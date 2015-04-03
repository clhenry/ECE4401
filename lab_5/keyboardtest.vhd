--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:31:47 09/30/2014
-- Design Name:   
-- Module Name:   /home/thor/Documents/Programming/Xilinx/KeyboardInterpreter/keyboardtest.vhd
-- Project Name:  KeyboardInterpreter
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
 
ENTITY keyboardtest IS
END keyboardtest;
 
ARCHITECTURE behavior OF keyboardtest IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT lab6
    PORT(
         seg : OUT  std_logic_vector(6 downto 0);
         an : OUT  std_logic_vector(3 downto 0);
         dp : OUT  std_logic;
         btn : IN  std_logic_vector(3 downto 3);
         ps2c : IN  std_logic;
         ps2d : IN  std_logic;
         clk : IN  std_logic
     );
    END COMPONENT;
    

   --Inputs
   signal btn : std_logic_vector(3 downto 3) := (others => '0');
   signal clk : std_logic := '0';

	--BiDirs
   signal ps2c : std_logic := '1';
   signal ps2d : std_logic := '1';

 	--Outputs
   signal seg : std_logic_vector(6 downto 0);
   signal an : std_logic_vector(3 downto 0);
   signal dp : std_logic;

   -- Clock period definitions
   constant clk_period : time := 20 ns;
	constant kbdclk_period : time := 40 us;
	signal kpresscode : std_logic_vector (7 downto 0) := X"1C"; -- A
	
	type kbd_states is (IDLE, START, DATA0, DATA1, DATA2, DATA3, DATA4, DATA5, DATA6, DATA7, PARITY, STOP);
	signal KBDSTATE : kbd_states := IDLE;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: lab6 PORT MAP (
          seg => seg,
          an => an,
          dp => dp,
          btn => btn,
          ps2c => ps2c,
          ps2d => ps2d,
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
	
	kbd_clk : process
	begin
		ps2c <= '1';
		wait for kbdclk_period/2;
		ps2c <= '0';
		wait for kbdclk_period/2 ;
	end process;
	
	keyboard_process : process (ps2c)
	begin
		if (falling_edge(ps2c)) then
			case KBDSTATE is
				when IDLE =>
					ps2d <= '1';
					KBDSTATE <= START;
				
				when START =>
					ps2d <= '0';
					KBDSTATE <= DATA0;

				when DATA0 =>
					ps2d <= kpresscode (0);
					KBDSTATE <= DATA1;

				when DATA1 =>
					ps2d <= kpresscode (1);
					KBDSTATE <= DATA2;

				when DATA2 =>
					ps2d <= kpresscode (2);
					KBDSTATE <= DATA3;

				when DATA3 =>
					ps2d <= kpresscode (3);
					KBDSTATE <= DATA4;

				when DATA4 =>
					ps2d <= kpresscode (4);
					KBDSTATE <= DATA5;

				when DATA5 =>
					ps2d <= kpresscode (5);
					KBDSTATE <= DATA6;

				when DATA6 =>
					ps2d <= kpresscode (6);
					KBDSTATE <= DATA7;

				when DATA7 =>
					ps2d <= kpresscode (7);
					KBDSTATE <= PARITY;

				when PARITY =>
					ps2d <= '0';
					KBDSTATE <= STOP;
	
				when STOP =>
					ps2d <= '1';
					KBDSTATE <= IDLE;

				when others => KBDSTATE <= START;
				
			end case;
		end if;
	end process;
 

   -- Stimulus process
   stim_proc: process
   begin
      -- hold reset state for 100 ns.
      wait for 100 ns;
		btn(3) <= '1';

      wait for clk_period*10;
		btn(3) <= '0';

      -- insert stimulus here 

      wait;
   end process;

END;
