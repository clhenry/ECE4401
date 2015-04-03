--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: Farrukh Hijaz
--
-- Create Date:    09/15/2015
-- Design Name:    
-- Module Name:    wb_swts
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

entity wb_swts is
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		adr_i : in std_logic_vector(31 downto 0);
		dat_i : in std_logic_vector(31 downto 0);
		dat_o : out std_logic_vector(31 downto 0);
		ack_o : out std_logic;
		stb_i : in std_logic;
		we_i  : in std_logic;
		irq_o : out std_logic;
		swts_i : in std_logic_vector(7 downto 0)
	);
end wb_swts;

architecture Behavioral of wb_swts is
-- declare the required signals
	signal switch_previous : std_logic_vector (7 downto 0);

begin

-- Design a state machine thats does the following:
-- Detect change in switches value and assert the interrupt
-- Wait for the strobe to be applied and put the switches value on the lower 8 bits of data_o. Pad the higher bits with zeros.
	
	
-- SLAVE interfaces MUST be designed so that the [ACK_O], [ERR_O] and [RTY_O] signals are asserted
-- and negated in response to the assertion and negation of [STB_O]. Furthermore, this activity MUST occur
-- asynchronous to the [CLK_I] signal.
	
	process (clk_i)
	begin
			
		if (rising_edge(clk_i)) then
			
			if (stb_i = '1' and we_i = '0') then
				ack_o <= '1';
				dat_o <= X"000000" & swts_i;
			else
				ack_o <= '0';
			end if;
			
		end if;
		
	end process;
	
	process(clk_i)
	begin
		if (rising_edge(clk_i)) then
			
			if (switch_previous /= swts_i) then
				irq_o <= '1';
			end if;
			
			switch_previous <= swts_i;
			
		end if;
	end process;

end Behavioral;
