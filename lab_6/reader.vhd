--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: Farrukh Hijaz
--
-- Create Date:    09/30/2015
-- Design Name:    
-- Module Name:    reader - Behavioral
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

entity reader is
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		adr_o : out std_logic_vector(31 downto 0);
		dat_i : in std_logic_vector(31 downto 0);
		dat_o : out std_logic_vector(31 downto 0);
		ack_i : in std_logic;
		cyc_o : out std_logic;
		stb_o : out std_logic;
		leds_o : out std_logic_vector(7 downto 0);
		we_o  : out std_logic
	);
end reader;

architecture Behavioral of reader is

type SYSTEM_STATE is (INIT, READ_RAM, WRITE_LED, RELEASE_BUS);
signal CURRENT_STATE : SYSTEM_STATE;

signal r_adr : std_logic_vector (22 downto 0);
signal slave_adr : std_logic_vector (1 downto 0);
signal dataword : std_logic_vector (31 downto 0);
signal WE : std_logic;
	
begin

	adr_o <= slave_adr & "000000" & r_adr (22 downto 0) & "0";
	
	we_o <= WE;
	
	
	process( clk_i, rst_i )
	begin
		if (rst_i = '1') then
			cyc_o <= '0';
			stb_o <= '0';
			WE <= '0';
			dataword <= (others => '0');
			r_adr <= (others => '0');
			slave_adr <= "00";
			CURRENT_STATE <= INIT;
			
		elsif (rising_edge(clk_i)) then
			case CURRENT_STATE is
				when INIT =>
					cyc_o <= '1';
					stb_o <= '1';
					WE <= '0';
					CURRENT_STATE <= READ_RAM;
					
				when READ_RAM =>
					if (ack_i = '1') then
						dataword <= dat_i;
						cyc_o <= '0';
						stb_o <= '0';
						CURRENT_STATE <= RELEASE_BUS;
					end if;
				
				when WRITE_LED =>
					if (ack_i = '1') then
						dat_o <= dataword; -- Write RAM data to wishbone buse
						r_adr <= r_adr + 1; -- Move to next address
						stb_o <= '0';
						cyc_o <= '0';
						CURRENT_STATE <= RELEASE_BUS;
					end if;
				
				when RELEASE_BUS =>
					if (WE = '1') then
						WE <= '0';
						slave_adr <= "00";
						CURRENT_STATE <= READ_RAM;
					else
						WE <= '1';
						slave_adr <= "01";
						CURRENT_STATE <= WRITE_LED;
					end if;
					
					cyc_o <= '1';
					stb_o <= '1';
					
			end case;
		end if;
	end process;


end Behavioral;
