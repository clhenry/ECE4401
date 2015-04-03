--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: Farrukh Hijaz
--
-- Create Date:    09/30/2015
-- Design Name:    
-- Module Name:    lab6 - Behavioral
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
	port ( 
		seg : out std_logic_vector(6 downto 0);
		an  : out std_logic_vector(3 downto 0);
		--led : out std_logic_vector(7 downto 0);
		btn : in std_logic_vector(3 downto 3);
	 	MemAdr : out std_logic_vector(23 downto 1);
		MemDB  : inout std_logic_vector(15 downto 0);
		RamCS  : out std_logic;
		RamUB  : out std_logic;
		RamLB  : out std_logic;
		RamAdv  : out std_logic;
		RamClk  : out std_logic;
		RamCRE  : out std_logic;
		MemOE  : out std_logic;
		MemWR  : out std_logic;
		clk : in std_logic
	);
end lab6;

architecture Behavioral of lab6 is
	-- Wishbone signals
	signal ACK_I_M:	std_logic_vector(3 downto 0);
	signal ACK_O_S:	std_logic_vector(3 downto 0);
	signal ADR_O_M0:	std_logic_vector( 31 downto 0 );
	signal ADR_O_M1:	std_logic_vector( 31 downto 0 );
	signal ADR_O_M2:	std_logic_vector( 31 downto 0 );
	signal ADR_O_M3:	std_logic_vector( 31 downto 0 );
	signal ADR_I_S:		std_logic_vector( 31 downto 0 );
	signal CYC_O_M:	std_logic_vector(3 downto 0);
	signal DAT_O_M0:	std_logic_vector( 31 downto 0 );
	signal DAT_O_M1:	std_logic_vector( 31 downto 0 );
	signal DAT_O_M2:	std_logic_vector( 31 downto 0 );
	signal DAT_O_M3:	std_logic_vector( 31 downto 0 );
	signal DWR:	std_logic_vector( 31 downto 0 );
	signal DAT_O_S0:	std_logic_vector( 31 downto 0 );
	signal DAT_O_S1:	std_logic_vector( 31 downto 0 );
	signal DAT_O_S2:	std_logic_vector( 31 downto 0 );
	signal DAT_O_S3:	std_logic_vector( 31 downto 0 );
	signal DRD:	std_logic_vector( 31 downto 0 );
	signal STB_I_S:	std_logic_vector(3 downto 0);
	signal STB_O_M:	std_logic_vector(3 downto 0);
	signal WE_O_M:	std_logic_vector(3 downto 0);
	signal WE:	std_logic;
	signal sys_clk, sys_rst : std_logic;
	--signal led_wb, led_reader : std_logic_vector(7 downto 0);
begin

	sys_clk <= clk;
	
	process(clk)
	begin
		if(rising_edge(clk)) then
			if (btn(3) = '1') then
				sys_rst <= '1';
			else
				sys_rst <= '0';
			end if;
		end if;
	end process;
	
--	led <= led_reader;

	wb_intercon : entity work.wb_intercon
		port map ( clk => sys_clk, rst => sys_rst,
     		   	  ack_i_m => ACK_I_M, ack_o_s => ack_o_s,
					  adr_o_m0 => adr_o_m0,	adr_o_m1 => adr_o_m1, adr_o_m2 => adr_o_m2, adr_o_m3 => adr_o_m3,
					  dat_o_m0 => dat_o_m0,	dat_o_m1 => dat_o_m1, dat_o_m2 => dat_o_m2, dat_o_m3 => dat_o_m3,
					  dat_o_s0 => dat_o_s0, dat_o_s1 => dat_o_s1, dat_o_s2 => dat_o_s2, dat_o_s3 => dat_o_s3,
					  adr_i_s => adr_i_s, drd => drd, dwr => dwr,
					  cyc_o_m => cyc_o_m, stb_o_m => stb_o_m, stb_i_s => stb_i_s, we_o_m => we_o_m, we => we
					  --leds_o => led_wb 
					  );
	
	-- Reads from RAM, writes to 7-segment LED module
	reader : entity work.reader
		port map ( clk_i => sys_clk, rst_i => sys_rst, 
					  adr_o => adr_o_m0, dat_i => drd, dat_o => dat_o_m0,
					  ack_i => ack_i_m(0), cyc_o => cyc_o_m(0), stb_o => stb_o_m(0), we_o => we_o_m(0)
					  --leds_o => led_reader
					  );
	
	-- Write up to address 0x7FFFFF in RAM
	writer : entity work.writer
		port map ( clk_i => sys_clk, rst_i => sys_rst, 
					  adr_o => adr_o_m1, dat_i => drd, dat_o => dat_o_m1,
					  ack_i => ack_i_m(1), cyc_o => cyc_o_m(1), stb_o => stb_o_m(1), we_o => we_o_m(1) );
	
	-- Interface to 8Mx16 SRAM
	sram16ctl : entity work.sram16ctl
		port map ( clk_i => sys_clk, rst_i => sys_rst, 
					  adr_i => adr_i_s, dat_i => dwr, dat_o => dat_o_s0,
					  ack_o => ack_o_s(0), stb_i => stb_i_s(0), we_i => we,
					  MemAdr => MemAdr, MemOE => MemOE, MemWR => MemWR,
					  MemDB => MemDB, RamCS => RamCS, RamUB => RamUB, RamLB => RamLB,
					  RamAdv => RamAdv, RamClk => RamClk, RamCRE => RamCRE);

	-- Written to by reader
	wb_segled : entity work.wb_segled
		port map ( clk_i => sys_clk, rst_i => sys_rst, 
					  adr_i => adr_i_s, dat_i => dwr, dat_o => dat_o_s1,
					  ack_o => ack_o_s(1), stb_i => stb_i_s(1), we_i => we, 
					  seg_o => seg, an_o => an );

	cyc_o_m(3) <= '0';
	cyc_o_m(2) <= '0';

	ack_o_s(3) <= '0';
	ack_o_s(2) <= '0';

	stb_o_m(3) <= '0';
	stb_o_m(2) <= '0';
	
	we_o_m(3) <= '0';
	we_o_m(2) <= '0';

end Behavioral;
