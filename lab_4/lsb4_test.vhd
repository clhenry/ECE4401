--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   01:32:02 09/25/2014
-- Design Name:   
-- Module Name:   /home/thor/Documents/Programming/Xilinx/WishBoneFoundation/lsb4_test.vhd
-- Project Name:  WishBoneFoundation
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: lab4
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY lsb4_test IS
END lsb4_test;
 
ARCHITECTURE behavior OF lsb4_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT lab4
    PORT(
         seg : OUT  std_logic_vector(6 downto 0);
         an : OUT  std_logic_vector(3 downto 0);
         btn : IN  std_logic_vector(3 downto 3);
         sw : IN  std_logic_vector(7 downto 0);
         clk : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal btn : std_logic_vector(3 downto 3) := (others => '0');
   signal sw : std_logic_vector(7 downto 0) := (others => '0');
   signal clk : std_logic := '0';

 	--Outputs
   signal seg : std_logic_vector(6 downto 0);
   signal an : std_logic_vector(3 downto 0);

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: lab4 PORT MAP (
          seg => seg,
          an => an,
          btn => btn,
          sw => sw,
          clk => clk
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
		btn <= "1";
		wait for clk_period*2;
		btn <= "0";
		wait for clk_period;

      -- insert stimulus here 
		sw <= X"43";
		wait for clk_period*50;
		sw <= X"37";

      wait;
   end process;

END;
