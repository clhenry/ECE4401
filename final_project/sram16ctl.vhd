library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sram16ctl is
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		adr_i : in std_logic_vector(31 downto 0);
		dat_i : in std_logic_vector(31 downto 0);
		dat_o : out std_logic_vector(31 downto 0);
		ack_o : out std_logic;
		stb_i : in std_logic;
		we_i : in std_logic;
		MemAdr : out std_logic_vector(23 downto 1); --
		MemOE : out std_logic; -- OE# - Output Enable
		MemWR : out std_logic; -- WE#, '1' for READ, '0' for WRITE
		MemDB : inout std_logic_vector(15 downto 0); -- DQ, 16-bit bidirectional data
		RamCS : out std_logic; -- CS# - Chip Select
		RamUB : out std_logic; -- UB# - Upper byte enable
		RamLB : out std_logic; -- LB# - Lower byte enable
		RamAdv : out std_logic; --- ADV# - Address valid. Tied low for asynch operation
		RamClk : out std_logic; -- CLK - Sync MEM with system. Tied low for async operation
		RamCRE : out std_logic -- CRE - Control Register Enable. Active HIGH	
	);
end sram16ctl;

architecture behavioral of sram16ctl is
	-- Cycles before valid data is present during a READ
	-- OR before data driven on memory bus can be latched in
	constant cycles_readwrite : integer := 4;
	-- System clock period in nanoseconds
	constant system_clk_period : integer := 20;
	-- RAM initialization period in nanoseconds
	constant init_period : integer := 150000;
	-- clk_i has a period of 20ns, MT45W8MW16BGX requires 150us power-up time.
	-- "During the initialization period,CE# should remain HIGH"
	constant cycles_init : integer := (init_period / system_clk_period);
	-- Longest wait period will be for power-up initialization
	signal wait_cycle : integer range 0 to cycles_init;
	-- Storage for data to be written to/read from memory
	signal data_from_mem : std_logic_vector(31 downto 0);
	signal data_to_mem : std_logic_vector(15 downto 0);
	-- Keeps track of which transaction phase we are currently in
	type transaction_phase is (LOWER16BITS, UPPER16BITS);
	signal current_phase : transaction_phase;

	-- Local RAM control signals
	signal CE_n, WE_n, OE_n, LB_n, UB_n : std_logic;

	-- System state machine declaration	
	type module_states is (INIT, WAIT_FOR_READ_OR_WRITE, READ, WRITE, ACK);
	signal current_state : module_states;

begin
	
	-- Tied LOW for asynch operation
	RamClk <= '0';
	RamCRE <= '0';
	RamAdv <= '0';

	RamLB <= LB_n;
	RamUB <= UB_n;
	RamCS <= CE_n;
	MemWR <= WE_n;
	MemOE <= OE_n;

	MemAdr(23 downto 2) <= adr_i (23 downto 2);
	
	-- If we are not writing to the memory bus then put it in a High-Z state
	MemDB <= data_to_mem when WE_n = '0' else (others => 'Z');

	dat_o <= data_from_mem;

	process(clk_i, rst_i)
	begin
		if (rst_i = '1') then
			LB_n <= '0'; -- Enable the lower 8 bits
			UB_n <= '0'; -- Enable the upper 8 bits			
			CE_n <= '1'; -- Deselect chip
			WE_n <= '1'; -- Read mode
			OE_n <= '1'; -- Disable output
			ack_o <= '0'; -- Deassert ACK
			current_phase <= LOWER16BITS; 
			MemAdr(1) <= '0'; -- Select LOWER 16 bits
			wait_cycle <= 0; -- Set initialization wait period
			current_state <= INIT; 
		elsif (rising_edge(clk_i)) then
			case current_state is
				when INIT =>
					-- Complete initialization period
					if (wait_cycle < cycles_init - 1) then
						wait_cycle <= wait_cycle + 1;
					-- Transisiton to IDLE to wait for READ or WRITE
					else
						current_state <= WAIT_FOR_READ_OR_WRITE;
					end if;

				when WAIT_FOR_READ_OR_WRITE =>
					if (stb_i = '1') then
						CE_n <= '0'; -- Select RAM chip 
						WE_n <= not we_i; -- (De)assert WRITE_ENABLE based on MASTER's request
						OE_n <= we_i; -- (De)assert OUTPUT_ENABLE depending on if MASTER is in READ or WRITE mode
						wait_cycle <= 0; -- reset wait counter
						--Determine if the lower or upper 16 bits of the 32-bit word is being addressed
						if (current_phase = LOWER16BITS) then
							MemAdr(1) <= '0';
						else
							MemAdr(1) <= '1';
						end if;
						-- Master is trying to WRITE to RAM
						if(we_i = '1') then
							if (current_phase = LOWER16BITS) then
								-- Put data to be written to memory bus
								data_to_mem <= dat_i(15 downto 0);
							else
								data_to_mem <= dat_i(31 downto 16);
							end if;
							current_state <= WRITE;
						-- Master is trying to READ from RAM
						else
							current_state <= READ;
						end if;
					end if;

				when READ =>
					if (wait_cycle < cycles_readwrite - 1) then
						wait_cycle <= wait_cycle + 1;
					else -- wait time has elapsed, data on the output of memory bus is valid
						if (current_phase = LOWER16BITS) then
							current_phase <= UPPER16BITS;
							data_from_mem(15 downto 0) <= MemDB;
							current_state <= WAIT_FOR_READ_OR_WRITE;
						else
							data_from_mem(31 downto 16) <= MemDB;
							ack_o <= '1'; -- Finished dealing with last 16-bits. Send ACK to master
							current_state <= ACK;
						end if;
					end if;

				when WRITE =>
					-- Wait for predefined period for write to be valid
					if (wait_cycle < cycles_readwrite - 1) then
						wait_cycle <= wait_cycle + 1;
					else 
						if(current_phase = LOWER16BITS) then
							current_phase <= UPPER16BITS;
							current_state <= WAIT_FOR_READ_OR_WRITE;
						-- Only send ACK if we have dealt with the last 16 bits of data
						else -- current_phase = UPPER16BITS
							ack_o <= '1';
							current_state <= ACK;
						end if;
						-- Data to be written to RAM is latched in on the rising edge of WE# or CE# 
						WE_n <= '1';
					end if;

				when ACK =>
					OE_n <= '1';
					CE_n <= '1';
					WE_n <= '1';
					ack_o <= '0';
					current_phase <= LOWER16BITS;
					current_state <= WAIT_FOR_READ_OR_WRITE;
			end case;
		end if;
	end process;

end behavioral;
