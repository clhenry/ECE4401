library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity debounce is
	generic (
		counter_size  :  integer := 19	--counter size (19 bits gives 10.5ms with 50MHz clock)
	); 
	port (
		clk : in std_logic;													-- input clock
		input  : in std_logic;											-- input signal to be debounced
		output : out std_logic											-- debounced signal
	); 
end debounce;

architecture logic of debounce is

	signal button_input : std_logic;
	signal input_flipflop : std_logic_vector (1 downto 0);																-- input flip flops
	signal counter_reset : std_logic;																										--sync reset to zero
	signal counter_out : std_logic_vector (counter_size downto 0) := (others => '0');	--counter output

begin

	button_input <= input;
	counter_reset <= input_flipflop(0) xor input_flipflop(1);																			--determine when to start/reset counter
  
	process(clk)
	begin
		if (rising_edge(clk)) then
			
			input_flipflop(0) <= button_input;
			input_flipflop(1) <= input_flipflop(0);
			
			if (counter_reset = '1') then																										--reset counter because input is changing
				counter_out <= (others => '0');
			elsif (counter_out(counter_size) = '0') then																			--stable input time is not yet met
				counter_out <= counter_out + 1;
			else                                        																									--stable input time is met
				output <= input_flipflop(1);
			end if;
			
		end if;
		
	end process;
	
end logic;