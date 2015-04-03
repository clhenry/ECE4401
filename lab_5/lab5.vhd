--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: Farrukh Hijaz
--
-- Create Date:    09/15/2015
-- Design Name:    
-- Module Name:    lab5 - Behavioral
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

entity lab6 is
	Port (
			 seg : out std_logic_vector(6 downto 0);
			 an : out std_logic_vector(3 downto 0);
			 dp : out std_logic;
			 btn : in std_logic_vector(3 downto 3);
			 ps2c : in std_logic;
			 ps2d : in std_logic;
			 -- ps2c : inout std_logic;
			 -- ps2d : inout std_logic;
			 clk : in std_logic
			 );
end lab6;

architecture Behavioral of lab6 is
	-- Wishbone signals
     		  signal ACK_I_M:    std_logic_vector(3 downto 0);
    		  signal ACK_O_S:     std_logic_vector(3 downto 0);
    		  signal ADR_O_M0:    std_logic_vector( 31 downto 0 );
    		  signal ADR_O_M1:    std_logic_vector( 31 downto 0 );
    		  signal ADR_O_M2:    std_logic_vector( 31 downto 0 );
    		  signal ADR_O_M3:    std_logic_vector( 31 downto 0 );
    		  signal ADR_I_S:	    std_logic_vector( 31 downto 0 );
			  signal CYC_O_M:     std_logic_vector(3 downto 0);
    		  signal DAT_O_M0:    std_logic_vector( 31 downto 0 );
    		  signal DAT_O_M1:    std_logic_vector( 31 downto 0 );
    		  signal DAT_O_M2:    std_logic_vector( 31 downto 0 );
    		  signal DAT_O_M3:    std_logic_vector( 31 downto 0 );
    		  signal DWR:  		 std_logic_vector( 31 downto 0 );
    		  signal DAT_O_S0:    std_logic_vector( 31 downto 0 );
    		  signal DAT_O_S1:    std_logic_vector( 31 downto 0 );
    		  signal DAT_O_S2:    std_logic_vector( 31 downto 0 );
    		  signal DAT_O_S3:    std_logic_vector( 31 downto 0 );
    		  signal DRD:  		 std_logic_vector( 31 downto 0 );
			  signal IRQ_O_S:	 std_logic_vector(3 downto 0);
			  signal IRQ_I_M:	 std_logic;
			  signal IRQV_I_M:	 std_logic_vector(1 downto 0);
			  signal STB_I_S:		 std_logic_vector(3 downto 0);
			  signal STB_O_M:		 std_logic_vector(3 downto 0);
			  signal WE_O_M:		 std_logic_vector(3 downto 0);
			  signal WE:		 	std_logic;

	signal rst : std_logic;
	signal leds2 : std_logic_vector(7 downto 0);
begin

	clocked_reset : process(clk)
	begin
		if (rising_edge(clk)) then
			if (btn(3) = '1') then
				rst <= '1';
			else
				rst <= '0';
			end if;
		end if;
	end process;
  	--rst <= btn(3); -- <- Transform into clocked reset process!

	wb_intercon : entity work.wb_intercon
		port map ( clk => clk, rst => rst,
     		   	  ack_i_m => ACK_I_M, ack_o_s => ack_o_s,
					  adr_o_m0 => adr_o_m0,	adr_o_m1 => adr_o_m1, adr_o_m2 => adr_o_m2, adr_o_m3 => adr_o_m3,
					  dat_o_m0 => dat_o_m0,	dat_o_m1 => dat_o_m1, dat_o_m2 => dat_o_m2, dat_o_m3 => dat_o_m3,
					  dat_o_s0 => dat_o_s0, dat_o_s1 => dat_o_s1, dat_o_s2 => dat_o_s2, dat_o_s3 => dat_o_s3,
					  adr_i_s => adr_i_s, drd => drd, dwr => dwr, 
					  irq_o_s => irq_o_s, irq_i_m => irq_i_m, irqv_i_m => irqv_i_m,
					  cyc_o_m => cyc_o_m, stb_o_m => stb_o_m, stb_i_s => stb_i_s, we_o_m => we_o_m, we => we );

	-- wb_ps2_kb module is at address 0 and reads scancodes from the PS/2 port and interrupts when a scancode is available
	wb_ps2_kb : entity work.wb_ps2_kb
		port map ( clk_i => clk, rst_i => rst, 
					  ps2_clk => ps2c, ps2_data => ps2d, 
					  adr_i => adr_i_s, dat_i => dwr, dat_o => dat_o_s0,
					  ack_o => ack_o_s(0), stb_i => stb_i_s(0), we_i => we, irq_o => irq_o_s(0));

	-- wb_eightcharled module is at address 1 is a write-only module that 
	-- displays the last eight characters written to it to the 4x7 segment
	-- LED display
	wb_eightcharled : entity work.wb_eightcharled
		port map ( clk_i => clk, rst_i => rst, 
					  adr_i => adr_i_s, dat_i => dwr, dat_o => dat_o_s1,
					  ack_o => ack_o_s(1), stb_i => stb_i_s(1), we_i => we,
					  segment => seg, an => an, dp => dp );

	-- wb_kb_reader module is a master module that waits for interrupts 
	-- from the ps2_kb module and then reads the scancode from the ps2_kb module
	-- and then converts the scancode to ascii which is then written to both
	-- the wb_eightcharled and wb_leds modules.
	wb_kb_reader : entity work.wb_kb_reader
		port map ( clk_i => clk, rst_i => rst, 
					  adr_o => adr_o_m0, dat_i => drd, dat_o => dat_o_m0,
					  ack_i => ack_i_m(0), cyc_o => cyc_o_m(0), stb_o => stb_o_m(0), 
					  we_o => we_o_m(0), irq_i => irq_i_m, irqv_i => irqv_i_m );
					  
	stb_o_m(3) <= '0';
	stb_o_m(2) <= '0';
	stb_o_m(1) <= '0';
	
	we_o_m(3) <= '0';
	we_o_m(2) <= '0';
	we_o_m(1) <= '0';

	cyc_o_m(3) <= '0';
	cyc_o_m(2) <= '0';
	cyc_o_m(1) <= '0';

end Behavioral;
