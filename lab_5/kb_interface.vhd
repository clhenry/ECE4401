--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: Farrukh Hijaz
--
-- Create Date:    09/15/2015
-- Design Name:    
-- Module Name:    kb_interface
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity kb_interface is
	Port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		ps2_clk : in std_logic;
		ps2_data : in std_logic;
		-- ps2_clk : inout std_logic;
		-- ps2_data : inout std_logic;
		scancode_available : out std_logic;
		scancode : out std_logic_vector(7 downto 0)
	);
end kb_interface;

architecture Behavioral of kb_interface is
	type state_type is (START, DATA0, DATA1, DATA2, DATA3, DATA4, DATA5, DATA6, DATA7, PARITY, STOP);
	signal state : state_type;
	signal scantemp : std_logic_vector(7 downto 0);
	signal scancode_avail : std_logic;

begin

-- The keyboard generates its own clock signal
process( ps2_clk, rst_i )
		variable code : std_logic_vector(7 downto 0);
		variable p : std_logic;
	begin
		if ( rst_i = '1' ) then
			state <= START;
			scancode_avail <= '0';
		elsif ( ps2_clk'event and ps2_clk='0' ) then

			case state is
			when START =>
				scancode_avail <= '0';
				if ( ps2_data = '0' ) then
					state <= DATA0;
					p := '1';
				end if;

			when DATA0 =>
				code(0) := ps2_data;
				p := p xor ps2_data;
				state <= DATA1;

			when DATA1 =>
				code(1) := ps2_data;
				p := p xor ps2_data;
				state <= DATA2;

			when DATA2 =>
				code(2) := ps2_data;
				p := p xor ps2_data;
				state <= DATA3;

			when DATA3 =>
				code(3) := ps2_data;
				p := p xor ps2_data;
				state <= DATA4;

			when DATA4 =>
				code(4) := ps2_data;
				p := p xor ps2_data;
				state <= DATA5;

			when DATA5 =>
				code(5) := ps2_data;
				p := p xor ps2_data;
				state <= DATA6;

			when DATA6 =>
				code(6) := ps2_data;
				p := p xor ps2_data;
				state <= DATA7;

			when DATA7 =>
				code(7) := ps2_data;
				p := p xor ps2_data;
				state <= PARITY;
				
			-- Keyboard calculates parity bit before hand
			-- Verify that local calculation matches expected parity
			-- Transition to STOP state, else incorrect, go to START
			when PARITY =>
				if ( ps2_data = p ) then
					state <= STOP;
				else
					state <= START;
				end if;
				
			-- Scancode-available signal is asserted on each succesfully read byte
			-- Deasserted in next state
			when STOP =>
				if ( ps2_data = '1' ) then
					scancode_avail <= '1';
					scantemp <= code;
				end if;
				state <= START;

			when others => state <= START;
			end case;
		end if;
	end process;
	
	scancode_available <= scancode_avail;
	scancode <= scantemp;

end Behavioral;

