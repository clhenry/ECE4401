--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    16:27:32 08/15/05
-- Design Name:    
-- Module Name:    wb_ps2_kb - Behavioral
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

entity wb_ps2_kb is
	port(
		clk_i : in std_logic;
		rst_i : in std_logic;
		adr_i : in std_logic_vector(31 downto 0);
		dat_i : in std_logic_vector(31 downto 0);
		dat_o : out std_logic_vector(31 downto 0);
		ack_o : out std_logic;
		stb_i : in std_logic;
		we_i  : in std_logic;
		ps2_clk : inout std_logic;
		ps2_data : inout std_logic;
		irq_o : out std_logic
	);
end wb_ps2_kb;

architecture Behavioral of wb_ps2_kb is
   type module_states is (WAIT_FOR_READ, ACK);
	signal current_state : module_states;
	signal scancode : std_logic_vector(7 downto 0);
   signal scancode_available, scancode_available_previous : std_logic;
	
begin

		kb_interface : entity work.kb_interface
		port map (
			clk_i => clk_i,
			rst_i => rst_i,
			ps2_clk => ps2_clk,
			ps2_data => ps2_data,
			scancode_available => scancode_available,
			scancode => scancode
		);
		
		irq_trigger : process (clk_i, rst_i)
		begin
			if (rst_i = '1') then
				irq_o <= '0';
			elsif (rising_edge(clk_i)) then
				if (scancode_available = '1' and scancode_available_previous = '0') then -- rising edge of scancode_available
					irq_o <= '1';
				else
					irq_o <= '0';
				end if;
				scancode_available_previous <= scancode_available;
			end if;
		end process;
		
		-- Service READ request 
		process (clk_i, rst_i)
		begin
			if (rst_i = '1') then
				dat_o <= (others => '0');
				ack_o <= '0';
				current_state <= WAIT_FOR_READ;
			elsif (rising_edge(clk_i)) then
				case current_state is
					when WAIT_FOR_READ =>
						if (stb_i = '1' and we_i = '0') then
							ack_o <= '1';
							dat_o <= X"000000" & scancode;
							current_state <= ACK;
						end if;
							
					when ACK =>
						ack_o <= '0';
						current_state <= WAIT_FOR_READ;
				end case;	
			end if;
		end process;
	
end Behavioral;
