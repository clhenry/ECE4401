--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: John A. Chandy
--
-- Create Date:    13:26:19 04/22/05
-- Design Name:    
-- Module Name:    string2leds - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description: Converts eight characters to the necessary signals to display
--              the characters on a 4x7-segment display
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

entity string2leds is
    Port ( char0, char1, char2, char3, char4, char5, char6, char7 : in std_logic_vector(7 downto 0);
		segment : out std_logic_vector(6 downto 0);
		an : out std_logic_vector(3 downto 0);
		dp : out std_logic;
		onemsec_clk : in std_logic;
		sys_rst : in std_logic );
end string2leds;

architecture Behavioral of string2leds is

	signal c0, c1, c2, c3 : std_logic_vector(7 downto 0);
	signal s0, s1, s2 : integer;
	signal segment0 : std_logic_vector(6 downto 0);
	signal segment1 : std_logic_vector(6 downto 0);
	signal segment2 : std_logic_vector(6 downto 0);
	signal segment3 : std_logic_vector(6 downto 0);
	signal dp0, dp1, dp2, dp3 : std_logic;
	
begin

	dp0 <= '0' when char0 = X"2E" else '1';
	c0 <= X"20" when char0=X"2E" and char1 = X"2E" else
			char1 when char0=X"2E" else char0;
	s0 <= 1 when char0=X"2E" and char1 /= X"2E" else 0;

	dp1 <= '0' when s0=0 and char1 = X"2E" else
						'0' when s0=1 and char2 = X"2E" else
						'1';
	c1 <= X"20" when s0=0 and char1=X"2E" and char2 = X"2E" else
			X"20" when s0=1 and char2=X"2E" and char3 = X"2E" else
			char2 when s0=0 and char1=X"2E" else
			char3 when s0=1 and char2=X"2E" else
			char2 when s0=1 else
			char1;
	s1 <= 1 when s0=0 and char1=X"2E" and char2 /= X"2E" else
			2 when s0=1 and char2=X"2E" and char3 /= X"2E" else
			s0;

	dp2 <= '0' when s1=0 and char2 = X"2E" else
						'0' when s1=1 and char3 = X"2E" else
						'0' when s1=2 and char4 = X"2E" else
						'1';
	c2 <= X"20" when s1=0 and char2=X"2E" and char3 = X"2E" else
			X"20" when s1=1 and char3=X"2E" and char4 = X"2E" else
			X"20" when s1=2 and char4=X"2E" and char5 = X"2E" else
			char3 when s1=0 and char2=X"2E" else
			char4 when s1=1 and char3=X"2E" else
			char5 when s1=2 and char4=X"2E" else
			char4 when s1=2 else
			char3 when s1=1 else
			char2;
	s2 <= 1 when s1=0 and char2=X"2E" and char3 /= X"2E" else
			2 when s1=1 and char3=X"2E" and char4 /= X"2E" else
			3 when s1=2 and char4=X"2E" and char5 /= X"2E" else
			s1;

	dp3 <= '0' when s2=0 and char3 = X"2E" else
						'0' when s2=1 and char4 = X"2E" else
						'0' when s2=2 and char5 = X"2E" else
						'0' when s2=3 and char6 = X"2E" else
						'1';
	c3 <= X"20" when s2=0 and char3=X"2E" and char4 = X"2E" else
			X"20" when s2=1 and char4=X"2E" and char5 = X"2E" else
			X"20" when s2=2 and char5=X"2E" and char6 = X"2E" else
			X"20" when s2=3 and char6=X"2E" and char7 = X"2E" else
			char4 when s2=0 and char3=X"2E" else
			char5 when s2=1 and char4=X"2E" else
			char6 when s2=2 and char5=X"2E" else
			char7 when s2=3 and char6=X"2E" else
			char6 when s2=3 else
			char5 when s2=2 else
			char4 when s2=1 else
			char3;
	
	char0led : entity work.char2led
		port map ( segment => segment0, ascii => c0 );

	char1led : entity work.char2led
		port map ( segment => segment1, ascii => c1 );

	char2led : entity work.char2led
		port map ( segment => segment2, ascii => c2 );

	char3led : entity work.char2led
		port map ( segment => segment3, ascii => c3 );

	led_control : entity work.char_led_control
		port map (
				clk => onemsec_clk,
				 reset => sys_rst,
				 segment0 => segment0,
				 dp0 => dp0,
			 	 segment1 => segment1,
				 dp1 => dp1,
			 	 segment2 => segment2,
				 dp2 => dp2,
			 	 segment3 => segment3,
				 dp3 => dp3,
			 	 segment => segment,
			 	 an => an,
				 dp => dp
		);

end Behavioral;
