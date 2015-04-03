--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   21:05:33 10/08/2014
-- Design Name:   
-- Module Name:   /home/thor/Documents/Programming/Xilinx/WishBoneSRAM/wbtest.vhd
-- Project Name:  WishBoneSRAM
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: lab6
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
 
ENTITY wbtest IS
END wbtest;
 
ARCHITECTURE behavior OF wbtest IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT lab6
    PORT(
         seg : OUT  std_logic_vector(6 downto 0);
         an : OUT  std_logic_vector(3 downto 0);
        -- led : OUT  std_logic_vector(7 downto 0);
         btn : IN  std_logic_vector(3 downto 3);
         MemAdr : OUT  std_logic_vector(23 downto 1);
         MemDB : INOUT  std_logic_vector(15 downto 0);
         RamCS : OUT  std_logic;
         RamUB : OUT  std_logic;
         RamLB : OUT  std_logic;
         RamAdv : OUT  std_logic;
         RamClk : OUT  std_logic;
         RamCRE : OUT  std_logic;
         MemOE : OUT  std_logic;
         MemWR : OUT  std_logic;
         clk : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal btn : std_logic_vector(3 downto 3) := (others => '0');
   signal clk : std_logic := '0';

	--BiDirs
   signal MemDB : std_logic_vector(15 downto 0);

 	--Outputs
   signal seg : std_logic_vector(6 downto 0);
   signal an : std_logic_vector(3 downto 0);
   signal MemAdr : std_logic_vector(23 downto 1);
   signal RamCS : std_logic;
   signal RamUB : std_logic;
   signal RamLB : std_logic;
   signal RamAdv : std_logic;
   signal RamClk : std_logic;
   signal RamCRE : std_logic;
   signal MemOE : std_logic;
   signal MemWR : std_logic;

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: lab6 PORT MAP (
          seg => seg,
          an => an,
          btn => btn,
          MemAdr => MemAdr,
          MemDB => MemDB,
          RamCS => RamCS,
          RamUB => RamUB,
          RamLB => RamLB,
          RamAdv => RamAdv,
          RamClk => RamClk,
          RamCRE => RamCRE,
          MemOE => MemOE,
          MemWR => MemWR,
          clk => clk
        );
 
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
		btn <= "1";
      wait for 100 ns;
		btn <= "0";

      -- insert stimulus here 

      wait;
   end process;

END;
