library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity wb_kb_reader is
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		adr_o : out std_logic_vector(31 downto 0);
		dat_i : in std_logic_vector(31 downto 0);
		dat_o : out std_logic_vector(31 downto 0);
		ack_i : in std_logic;
		cyc_o : out std_logic;
		stb_o : out std_logic;
		we_o  : out std_logic;
		irq_i : in std_logic;
		--leds_o : out std_logic_vector(7 downto 0);
		irqv_i: in std_logic_vector(1 downto 0)
	);
end wb_kb_reader;

architecture Behavioral of wb_kb_reader is
	-- Add other signals as required.	
	-- Two byte buffer stores incoming scancodes
	signal scancode_buffer : std_logic_vector(15 downto 0);

	-- Slaves on the wishbone bus
	constant keyboard_adr : std_logic_vector(1 downto 0) := "00";
	--constant ram_adr : std_logic_vector(1 downto 0) := "01";
	constant segled_adr : std_logic_vector (1 downto 0) := "01";
	
	type SYSTEM_STATES is (IRQ_WAIT, READ, PROCESS_DATA, WRITE);
	signal CURRENT_STATE : SYSTEM_STATES;
	
	signal ascii : std_logic_vector(7 downto 0);
	signal shift, ctrl, alt : std_logic;
	signal STB, CYC, WE : std_logic;
	
begin

	stb_o <= STB;
	we_o <= WE;
	cyc_o <= CYC;
	
	-- convert the scancode signal given the shift, ctrl, and alt flags into
	-- an eight bit ASCII signal.
	s2a : entity work.scancode2ascii
	port map (
		scancode => scancode_buffer(7 downto 0), -- input
		ascii => ascii, -- output
		shift => shift, -- input
		ctrl => ctrl, -- input
		alt => alt -- input
	);
	
	process(clk_i, rst_i)
	begin
		if(rst_i = '1') then
			shift <= '0';
			ctrl <= '0';
			alt <= '0';
		elsif (rising_edge(clk_i)) then	
			-- ALT key released
			if (scancode_buffer = X"F011") then
				alt <= '0';
			-- SHIFT key released
			elsif (scancode_buffer = X"F012") then
				shift <= '0';
			-- CTRL key released
			elsif (scancode_buffer = X"F014") then
				ctrl <= '0';
			-- ALT key pressed
			elsif (scancode_buffer(7 downto 0) = X"11") then
				alt <= '1';
			-- SHIFT key pressed
			elsif (scancode_buffer(7 downto 0) = X"12") then
				shift <= '1';
			-- CTRL key pressed
			elsif (scancode_buffer(7 downto 0) = X"14") then
				ctrl <= '1';
			end if;
		end if;
	end process;
	
	process(clk_i, rst_i)
	begin
		if (rst_i = '1') then
			CURRENT_STATE <= IRQ_WAIT;
			CYC <= '0';
			STB <= '0';
			WE <= '0';
			adr_o <= (others => '0');
			dat_o <= (others => '0');
			scancode_buffer <= X"0000";
		-- IRQ generated from Slave 0
		elsif (rising_edge(clk_i)) then
			case CURRENT_STATE is
				when IRQ_WAIT =>
					if (irq_i = '1') then  -- setup signals for read state
						adr_o <= keyboard_adr & "000000" & X"000000";
						CYC <= '1';
						WE <= '0';
						STB <= '1';
						CURRENT_STATE <= READ;
					end if;
				
				when READ =>
					if (ack_i = '1') then -- SETUP for WRITE
						CYC <= '0';
						STB <= '0';
						scancode_buffer(7 downto 0) <= dat_i (7 downto 0); -- Was previously in read state, store READ result
						scancode_buffer(15 downto 8) <= scancode_buffer(7 downto 0);
						CURRENT_STATE <= PROCESS_DATA;
					end if;
					
				when PROCESS_DATA =>
					if (scancode_buffer(7 downto 0) = X"F0" or -- Incoming break code
						scancode_buffer(7 downto 0) = X"11" or -- ALT key pressed
						scancode_buffer(7 downto 0) = X"12" or -- SHIFT key pressed
						scancode_buffer(7 downto 0) = X"14" or -- CTRL key pressed
						scancode_buffer(15 downto 8) = X"F0") then -- Received complete break code
						CURRENT_STATE <= IRQ_WAIT;
					else
						adr_o <= segled_adr & "000000" & X"000000";
						dat_o <= X"000000" & ascii;
						CYC <= '1';
						WE <= '1';
						STB <= '1';
						CURRENT_STATE <= WRITE;
					end if;
					
				when WRITE =>
					if (ack_i = '1') then
						CYC <= '0';
						STB <= '0';
						CURRENT_STATE <= IRQ_WAIT;
					end if;
			end case;
		end if;
	end process;

end Behavioral;
