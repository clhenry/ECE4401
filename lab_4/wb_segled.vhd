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
	signal segment_0, segment_1 : std_logic_vector (6 downto 0);
	signal hex_data : std_logic_vector (7 downto 0);
	signal onemsec_clk : std_logic;

begin

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
	
	-- 7-Segment digit multiplexer
	led_control : entity work.char_led_control
	port map (
		clk => onemsec_clk,
		reset => rst_i,
		segment0 => segment_0,
		segment1 => segment_1,
		segment2 => (others => '1'),
		segment3 => (others => '1'),
		segment => seg_o,
		an => an_o
	);

	-- State machine
	process(clk_i)
	begin
		if (rising_edge(clk_i)) then
			if (stb_i = '1' and we_i = '1') then
				ack_o <= '1';
				hex_data <= dat_i (7 downto 0);
			else
					ack_o <= '0';
			end if;
			
		end if;
	end process;

end Behavioral;
