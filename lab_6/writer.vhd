--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: Farrukh Hijaz
--
-- Create Date:    09/30/2015
-- Design Name:    
-- Module Name:    writer - Behavioral
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

entity writer is
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		adr_o : out std_logic_vector(31 downto 0);
		dat_i : in std_logic_vector(31 downto 0);
		dat_o : out std_logic_vector(31 downto 0);
		ack_i : in std_logic;
		cyc_o : out std_logic;
		stb_o : out std_logic;
		--leds_o : out std_logic_vector(4 downto 0);
		we_o  : out std_logic
	);
end writer;

architecture Behavioral of writer is

	signal w_adr : std_logic_vector (22 downto 0); -- use only 1 bit comparator on w(23) to determine end point
	type SYSTEM_STATES is (IDLE, RELEASE_BUS, WRITE_RAM);
	signal CURRENT_STATE : SYSTEM_STATES;
	
begin
-- Design a state machine that writes data to the bus, wait for an ack and then given up the bus before asserting cyc_o again.
-- The data written should be the current address (24-bits) padded with x"00" at the front.
-- After each write, increment the current address by 4.

	adr_o <= X"00" & w_adr (22 downto 0) & "0";
	dat_o <= X"00" & w_adr (22 downto 0) & "0";
	
	process(clk_i, rst_i)
	begin
		if (rst_i = '1') then
			CURRENT_STATE <= IDLE;
			w_adr <= (others => '0');
			stb_o <= '1';
			cyc_o <= '1';
			we_o <= '1';
			
		elsif (rising_edge(clk_i)) then
			case CURRENT_STATE is
				when IDLE =>
					CURRENT_STATE <= WRITE_RAM;
					
				when WRITE_RAM =>
					if (ack_i = '1') then
						stb_o <= '0';
						w_adr <= w_adr + 1;
						CURRENT_STATE <= RELEASE_BUS;
					end if;
				
				-- Don't give up the bus until every address has been written to
				when RELEASE_BUS =>
					if (w_adr(22) = '0') then
						stb_o <= '1';
						CURRENT_STATE <= IDLE;
					else
						stb_o <= '0';
						cyc_o <= '0'; -- Give up the bus for good
					end if;
				
			end case;
		end if;
		
	end process;


end Behavioral;
