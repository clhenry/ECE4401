--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: Farrukh Hijaz
--
-- Create Date:    09/15/2015
-- Design Name:    
-- Module Name:    wb_segled
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wb_segled is
	Port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		adr_i : in std_logic_vector(31 downto 0);
		dat_i : in std_logic_vector(31 downto 0);
		dat_o : out std_logic_vector(31 downto 0);
		ack_o : out std_logic;
		stb_i : in std_logic;
		we_i  : in std_logic;
		seg_o : out std_logic_vector(6 downto 0);
		an_o : out std_logic_vector(3 downto 0)
	);
end wb_segled;

architecture Behavioral of wb_segled is
-- declare the required signals
	type SYSTEM_STATES is (IDLE, HALFWORD1, HALFWORD2);
	signal CURRENT_STATE : SYSTEM_STATES;
	signal segment_0, segment_1,  segment_2, segment_3: std_logic_vector (6 downto 0);
	signal dataword : std_logic_vector (31 downto 0);
	signal hex_data : std_logic_vector (15 downto 0);
	signal onemsec_clk, onesec_clk, onesec_clk_prev : std_logic;

begin

	onesec_clock : entity work.clock_divider
	generic map (
		divisor => 1000
	)
	port map (
		clk_in => onemsec_clk,
		reset => rst_i,
		clk_out => onesec_clk
	);

	-- generate 1ms clock source
	msec_clock : entity work.clock_divider
	generic map (
		divisor => 50000
	)
	port map (
		clk_in => clk_i, 
		reset => rst_i,
		clk_out => onemsec_clk
	);

	-- binary to 7-segment lookup/mapper
	hex_7seg0 : entity work.hex2led
	port map (
		hex => hex_data (3 downto 0),
		segment => segment_0
	);
	
	hex_7seg1 : entity work.hex2led
	port map (
		hex => hex_data (7 downto 4),
		segment => segment_1
	);
	
	hex_7seg2 : entity work.hex2led
	port map (
		hex => hex_data (11 downto 8),
		segment => segment_2
	);
	
	hex_7seg3 : entity work.hex2led
	port map (
		hex => hex_data (15 downto 12),
		segment => segment_3
	);
	
	-- 7-Segment digit multiplexer
	led_control : entity work.char_led_control
	port map (
		clk => onemsec_clk,
		reset => rst_i,
		segment0 => segment_0,
		segment1 => segment_1,
		segment2 => segment_2,
		segment3 => segment_3,
		segment => seg_o,
		an => an_o
	);

	-- State machine
	process(clk_i, rst_i)
	begin
		if (rst_i = '1') then
			hex_data <= X"0000";
			ack_o <= '0';
			CURRENT_STATE <= IDLE;
		elsif (rising_edge(clk_i)) then
			case CURRENT_STATE is
				when IDLE =>
					ack_o <= '0';
					CURRENT_STATE <= HALFWORD1;
				
				when HALFWORD1 =>
					if (stb_i = '1' and we_i = '1') then
						dataword <= dat_i;
						hex_data <= dataword (15 downto 0);
						if (onesec_clk = '1' and onesec_clk_prev = '0') then
							CURRENT_STATE <= HALFWORD2;
						end if;
					end if;
				
				when HALFWORD2 =>
					hex_data <= dataword (31 downto 16);
					if (onesec_clk = '1' and onesec_clk_prev = '0') then
						CURRENT_STATE <= IDLE;
						ack_o <= '1';
					end if;
				end case;
					
			onesec_clk_prev <= onesec_clk;
		end if;
	end process;

end Behavioral;
