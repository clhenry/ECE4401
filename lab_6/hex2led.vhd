----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:53:27 08/28/2014 
-- Design Name: 
-- Module Name:    hex2led - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hex2led is
	port(
		hex : in std_logic_vector(3 downto 0);
		segment : out std_logic_vector(6 downto 0)
	);
end hex2led;

architecture Behavioral of hex2led is

signal decimal_value : natural range 0 to 15;

begin

decimal_value <= to_integer(unsigned(hex));

process(decimal_value)
begin
	case decimal_value is			--gfedcba
		when 0 => segment <= "1000000"; 
		when 1 => segment <= "1111001";
		when 2 => segment <= "0100100";
		when 3 => segment <= "0110000";
		when 4 => segment <= "0011001";
		when 5 => segment <= "0010010";
		when 6 => segment <= "0000010";
		when 7 => segment <= "1111000";
		when 8 => segment <= "0000000";
		when 9 => segment <= "0011000";
		when 10 => segment <= "0001000"; -- A
		when 11 => segment <= "0000000"; -- B
		when 12 => segment <= "1000110"; -- C
		when 13 => segment <= "1000000"; -- D
		when 14 => segment <= "0000110"; -- E
		when 15 => segment <=  "0001110"; -- F
	end case;
end process;

end Behavioral;

