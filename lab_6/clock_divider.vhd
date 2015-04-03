library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_divider is
	generic (
		divisor : natural := 0
	);
	port (
		clk_in, reset : in std_logic;
		clk_out : out std_logic
	);
end clock_divider;

architecture Behavioral of clock_divider is

	signal tick_counter : natural range 1 to (divisor / 2);
	signal clock_out : std_logic;
	
begin

	process(clk_in, reset)
	begin
		if (reset = '1') then
			tick_counter <= 1;
			clock_out <= '0';
		elsif(rising_edge(clk_in)) then
			if(tick_counter < (divisor / 2)) then
				tick_counter <= tick_counter + 1;
			else
				tick_counter <= 1;
				clock_out <= not clock_out;
			end if;
		end if;
	end process;
	
	clk_out <= clock_out;
	
end Behavioral;

