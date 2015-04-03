--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: Farrukh Hijaz
--
-- Create Date:    09/15/2015
-- Design Name:    
-- Module Name:    reader
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

entity reader is
	port (
		clk_i : in std_logic; -- system clock
		rst_i : in std_logic; -- system reset
		adr_o : out std_logic_vector (31 downto 0);	-- Most significant 2 bits specify the address of the slave
		dat_i : in std_logic_vector (31 downto 0);	-- Data FROM slave
		dat_o : out std_logic_vector (31 downto 0); -- Data TO slave
		ack_i : in std_logic;		-- When asserted indicates the termination of a normal bus cycle. Does STB and CYC get reset?
		cyc_o : out std_logic;	-- Indicates valid bus cycle in progress when asserted. Asserted for the duration of all bus cycles
		stb_o : out std_logic;	-- The strobe output [STB_O] indicates a valid data transfer cycle. It is used to qualify various other signals
														-- on the interface such as [SEL_O(7..0)]. The SLAVE must assert either the [ACK_I], [ERR_I] or [RTY_I]
														-- signals in response to every assertion of the [STB_O] signal.
		we_o  : out std_logic		-- '1' for WRITE, '0' for READ 
	);
end reader;

architecture Behavioral of reader is
	
	signal rdata : std_logic_vector(31 downto 0); -- Stores data READ from switches and is the same data to be WRITTEN to the LEDs
	type SYSTEM_STATES is (ACK_WAIT, READ, WRITE);	-- READ from switches, WRITE to LEDs
	signal CURRENT_STATE, NEXT_STATE : SYSTEM_STATES;
	signal WE : std_logic;
	
begin

--------------------------
-- RULES
--------------------------
-- MASTER and SLAVE interfaces MUST initialize themselves after the assertion of [RST_I].
-- The interface MUST be capable of reacting to [RST_I] at any time.

-- Design a state machine that reads from the switches through the bus and then writes it to the leds through the bus.
	
	we_o <= WE;
	
	process (clk_i)
	begin
		
		if (rising_edge(clk_i)) then
			if (rst_i = '1') then
				
				WE <= '0';
				stb_o <= '0';
				cyc_o <= '0';
				CURRENT_STATE <= READ;
				NEXT_STATE <= READ;
				
			else
				case CURRENT_STATE is
				
					when ACK_WAIT =>
						
						if (ack_i = '1') then
							stb_o <= '0';
							cyc_o <= '0';
							
							if (WE = '1') then -- Was previously in WRITE state, go to READ
								dat_o <= rdata;
								NEXT_STATE <= READ;
							else
								rdata <= dat_i;
								NEXT_STATE <= WRITE;
							end if;
							
						end if;
						
					when READ =>
					
							WE <= '0';
							stb_o <= '1';
							cyc_o <= '1';
							adr_o <= X"00000000";
							NEXT_STATE <= ACK_WAIT;
						
					when WRITE =>
							
							WE <= '1';
							stb_o <= '1';
							cyc_o <= '1';
							adr_o <= X"40000000";
							NEXT_STATE <= ACK_WAIT;
					
				end case;
			end if;
		
			CURRENT_STATE <= NEXT_STATE;
		
		end if;
	end process;

end Behavioral;
