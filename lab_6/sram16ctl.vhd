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
	constant cyclesReadWrite : integer := 4;
		
	-- System clock period in nanoseconds
	constant sysClkPeriod : integer := 20;

	-- RAM initialization period in nanoseconds
	constant initPeriod : integer := 150000;

	-- clk_i has a period of 20ns, MT45W8MW16BGX requires 150us power-up time.
	-- "During the initialization period,CE# should remain HIGH"
	constant cyclesInit : integer := (initPeriod / sysClkPeriod);

	-- Signal counts down. When 0 the the system can proceed with next operation.
	-- Longest wait period will be for power-up initialization
	signal waitCycles : integer range 0 to cyclesInit;

	-- Storage for data to be written to/read from memory
	signal dataFromMem : std_logic_vector (31 downto 0);
	signal dataToMem : std_logic_vector (15 downto 0);
	
	-- Keeps track of which 16-bit phase we are currently in
	type PHASE is (LOWER16BITS, UPPER16BITS);
	signal currentPhase : PHASE;

	-- Local RAM control signals
	signal CE_n, WE_n, OE_n, LB_n, UB_n : std_logic;

	-- System state machine declaration	
	type MODULESTATES is (INIT, IDLE, READ, WRITE, ACK);
	signal currentState : MODULESTATES;

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
	
	-- If we are not writing to the memory bus then put it in a High-Z state
	MemDB <= dataToMem when WE_n = '0' else (others => 'Z');
	
	MemAdr(23 downto 2) <= adr_i (22 downto 1);
	
	dat_o <= dataFromMem;

	process(clk_i, rst_i)
	begin
		if (rst_i = '1') then
			LB_n <= '0'; -- Enable the lower 8 bits
			UB_n <= '0'; -- Enable the upper 8 bits			
			CE_n <= '1'; -- Deselect chip
			WE_n <= '1'; -- Read mode
			OE_n <= '1'; -- Disable output
			ack_o <= '0'; -- Deassert ACK
			currentPhase <= LOWER16BITS; 
			MemAdr(1) <= '0'; -- Select LOWER 16 bits
			waitCycles <= cyclesInit; -- Set initialization wait period
			currentState <= INIT; 

		elsif (rising_edge(clk_i)) then
			case currentState is
			
				when INIT =>
					-- Complete initialization period
					if (waitCycles - 1 > 0) then
						waitCycles <= waitCycles - 1;
					-- Transisiton to IDLE to wait for READ or WRITE
					else
						currentState <= IDLE;
					end if;

				when IDLE =>
					if (stb_i = '1') then
						CE_n <= '0'; -- Select RAM chip 
						WE_n <= not we_i; -- (De)assert WRITE_ENABLE based on MASTER's request
						OE_n <= we_i; -- (De)assert OUTPUT_ENABLE depending on if MASTER is in READ or WRITE mode
						waitCycles <= cyclesReadWrite; -- Setup wait counter
						
						--Determine if the lower or upper 16 bits of the 32-bit word is being addressed
						if (currentPhase = LOWER16BITS) then
							MemAdr(1) <= '0';
						else
							MemAdr(1) <= '1';
						end if;
						
						if (we_i = '1') then -- Master is trying to WRITE to RAM
							if (currentPhase = LOWER16BITS) then
								dataToMem <= dat_i (15 downto 0);
							else
								dataToMem <= dat_i (31 downto 16);
							end if;

							currentState <= WRITE;
							
						else -- Master is trying to READ from RAM
							currentState <= READ;						
						end if;
						
					end if;

				when READ =>
					if (waitCycles - 1 > 0) then
						waitCycles <= waitCycles - 1;
					else
						--CE_n <= '1';
						--OE_n <= '1';
						
						--- Switch from 
						if (currentPhase = LOWER16BITS) then
							dataFromMem (15 downto 0) <= MemDB;
						else
							dataFromMem (31 downto 16) <= MemDB;
							ack_o <= '1'; -- Finished dealing with last 16-bits. Send ACK to master
						end if;
						
						currentState <= ACK;
						
					end if;

				when WRITE =>
					-- Wait for predefined period for write to be valid
					if (waitCycles - 1 > 0) then
						waitCycles <= waitCycles - 1;
					else -- Data to be written to RAM is latched in on the rising edge of WE# or CE# 
						--CE_n <= '1';
						--WE_n <= '1';
						-- Only send ACK if we have dealt with the last 16 bits of data
						if (currentPhase = UPPER16BITS) then
							ack_o <= '1';
						end if;

						currentState <= ACK;
					end if;

				when ACK =>
					if (currentPhase = LOWER16BITS) then
						currentPhase <= UPPER16BITS;
					else
						--CE_n <= '1';
						OE_n <= '1';
						CE_n <= '1';
						WE_n <= '1';
						ack_o <= '0';
						currentPhase <= LOWER16BITS;
					end if;
					currentState <= IDLE;
		
			end case;
			
		end if;
	end process;

end behavioral;
