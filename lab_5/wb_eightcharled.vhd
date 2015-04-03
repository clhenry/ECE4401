--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: Farrukh Hijaz
--
-- Create Date:    09/15/2015
-- Design Name:    
-- Module Name:    wb_eightcharled
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description: Master wishbone module that waits for interrupts 
--              from the ps2_kb module and then reads the scancode from the ps2_kb module
--              and then converts the scancode to ascii which is then written to 
--              the wb_eightcharled module.
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

entity wb_eightcharled is
	Port ( clk_i : in std_logic;
          rst_i : in std_logic;
		    adr_i : in std_logic_vector(31 downto 0);
          dat_i : in std_logic_vector(31 downto 0);
          dat_o : out std_logic_vector(31 downto 0);
          ack_o : out std_logic;
          stb_i : in std_logic;
          we_i  : in std_logic;
			 segment : out std_logic_vector(6 downto 0);
          an : out std_logic_vector(3 downto 0);
          dp : out std_logic
		);
end wb_eightcharled;

architecture Behavioral of wb_eightcharled is
	
	type SYSTEM_STATES is (IDLE, READ);
	signal CURRENT_STATE : SYSTEM_STATES;
	signal char_counter : integer;
	type chararray is array (0 to 7) of std_logic_vector (7 downto 0);
	signal char : chararray;
	signal onemsec_clk : std_logic;
	
begin

 	onemsec_clk_divider : entity work.clock_divider
		generic map ( divisor => 50000 )
		port map ( clk_in => clk_i, reset => rst_i, clk_out => onemsec_clk );

	-- convert eight characters to the appropriate digit and segment signals
	string2leds : entity work.string2leds
	port map (
		char0 => char(0), char1 => char(1), char2 =>char(2), char3 => char(3),
		char4 => char(4), char5 => char(5), char6 =>char(6), char7 => char(7),
		onemsec_clk => onemsec_clk, 
		sys_rst => rst_i,
		segment => segment,
		an => an,
		dp => dp
	);
	
	process(clk_i, rst_i)
	begin
		if (rst_i = '1') then
			ack_o <= '0';
			char(0) <= X"20";
			char(1) <= X"20";
			char(2) <= X"20";
			char(3) <= X"20";
			CURRENT_STATE <= IDLE;
			
		elsif (rising_edge(clk_i)) then
			case CURRENT_STATE is
			
				when IDLE =>
					if (stb_i = '1' and we_i = '1') then
						if (dat_i (7 downto 0) = X"08") then
							char(0) <= char(1);
							char(1) <= char(2);
							char(2) <= char(3);
							char(3) <= char(4);
							char(4) <= char(5);
							char(5) <= char(6);
							char(6) <= char(7);
							char(7) <= X"20";
			
						else
							char(0) <= dat_i (7 downto 0);
							char(1) <= char(0);
							char(2) <= char(1);
							char(3) <= char(2);
							char(4) <= char(3);
							char(5) <= char(4);
							char(6) <= char(5);
							char(7) <= char(6);
						end if;
						
						ack_o <= '1';
						CURRENT_STATE <= READ;
					
					else
						ack_o <= '0';
					end if;
					
				when READ =>
					ack_o <= '0';
					CURRENT_STATE <= IDLE;
					
			end case;
		end if;
	end process;

end Behavioral;

