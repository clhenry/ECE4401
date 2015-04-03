library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
--The clock input is supplied by a millisecond base.
--On each rising edge the 7-bit segment is provided with one of the provided input segments
--
--
entity char_led_control is
	port (
		clk : in std_logic;
		reset : in std_logic;
		segment0 : in std_logic_vector(6 downto 0);
		segment1 : in std_logic_vector(6 downto 0);
		segment2 : in std_logic_vector(6 downto 0);
		segment3 : in std_logic_vector(6 downto 0);
		dp0 : in std_logic;
		dp1 : in std_logic;
		dp2 : in std_logic;
		dp3 : in std_logic;
		an : out std_logic_vector(3 downto 0);
		segment : out std_logic_vector(6 downto 0);
		dp : out std_logic
	);
end char_led_control;

architecture behavioral of char_led_control is
	signal digit_selector : natural range 0 to 3;
begin

	--cycle through each digit once per millisecond
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '1' or digit_selector = 3) then
				digit_selector <= 0;
			else
				digit_selector <= digit_selector + 1;
			end if;
		end if;
	end process;
	
	--bias the correct transisitor dependent on the current digit
	process(digit_selector, segment0, segment1, segment2, segment3, dp0, dp1, dp2, dp3)
	begin
		case digit_selector is
			when 0 => an <= "0111";
									segment <= segment3;
									dp <= dp3;
			when 1 => an <= "1011";
									segment <= segment2;
									dp <= dp2;
			when 2 => an <= "1101";
									segment <= segment1;
									dp <= dp1;
			when 3 => an <= "1110";
									segment <= segment0;
									dp <= dp0;
		end case;
	end process;
	
end behavioral;
