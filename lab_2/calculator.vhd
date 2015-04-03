library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calculator is
	port (
		sw : in std_logic_vector ( 7 downto 0);
		btn: in std_logic_vector (3 downto 0);
		clk : in std_logic;
		seg : out std_logic_vector (6 downto 0);
		an : out std_logic_vector ( 3 downto 0)
	);
end calculator;

architecture behavioural of push_button_switch is
	
	signal debounced_button : std_logic_vector (3 downto 0);
	
	signal reset_button : std_logic;
	signal add_button : std_logic;
	signal multiply_button : std_logic;
	signal equal_button : std_logic;
	
	signal reset_button_prev: std_logic;
	signal add_button_prev : std_logic;
	signal multiply_button_prev : std_logic;
	signal equal_button_prev : std_logic;
	
	signal onemsec_clk : std_logic;
	
	type ALU_OPERATIONS is (ADD, MULTIPLY);
	signal operation, alu_operation : ALU_OPERATIONS;
	
	type SYSTEM_STATES is (COMMIT_OPERAND1, COMMIT_OPERAND2, DISPLAY_RESULT);
	signal current_state, next_state : SYSTEM_STATES;
		
	signal alu_operand2, operand2, operand2_prev : signed (7 downto 0);
	signal alu_result, result, alu_operand1 : signed (15 downto 0);
	
	-- Hexadecimal data to be displayed
	type hex_data is array (0 to 3) of std_logic_vector (3 downto 0);
	signal data : hex_data;
	
	-- 7 Segment equivalent to hexadecimal data
	type segment_data is array (0 to 3) of std_logic_vector (6 downto 0);
	signal digit : segment_data;
	
begin

	-- Map names buttons to their equivalent debounced output
	equal_button <= debounced_button(0);
	add_button <= debounced_button(1);
	multiply_button <= debounced_button(2);
	reset_button <= debounced_button(3);
	
	hex_7seg: for i in 0 to 3 generate
	begin
		hex_to_7seg : entity work.hex2led
			port map (
				hex => data(i),
				segment => digit(i)
			);
	end generate;
	
	led_control : entity work.char_led_control
	port map (
		clk => onemsec_clk,
		reset => btn(3),
		segment0 => digit(0),
		segment1 => digit(1),
		segment2 => digit(2),
		segment3 => digit(3),
		segment => seg,
		an => an
	);
	
	-- Debounce external button presses
	debounce_mapper : for i in 0 to 3 generate
	begin
		button_debouncer : entity work.debounce
			generic map (
				counter_size => 5 -- With a 1ms input clock there should be a ~15ms period where the signal is allowed to settle
			)
			port map (
				input => btn(i),
				clk => onemsec_clk,
				output => debounced_button(i)
			);
	end generate;

	--Generate 1ms clock source
	msec_clk : entity work.clock_divider
	generic map (
		divisor => 50000
	)
	port map (
		reset => '0',
		clk_in => clk,
		clk_out => onemsec_clk
	);
	
	-- Toggle LEDs based on button-press states
	process(clk)
	begin
		if(rising_edge(clk)) then
			
			current_state <= next_state;
			
			--STATE MACHINE
			case current_state is
				when COMMIT_OPERAND1 =>
									
					if (add_button_prev = '0' and add_button = '1') then --rising_edge(add_button)
						operation <= ADD;
						next_state <= COMMIT_OPERAND2;
						result <= X"00" & operand2;
					elsif (multiply_button_prev = '0' and multiply_button = '1') then --rising_edge(multiply_button)
						operation <= MULTIPLY;
						next_state <= COMMIT_OPERAND2;
						result <= X"00" & operand2;
					end if;
					
					data(0) <= std_logic_vector(operand2(3 downto 0));
					data(1) <= std_logic_vector(operand2(7 downto 4));
					data(2) <= X"0";
					data(3) <= X"0";
					
				when COMMIT_OPERAND2 =>
				
					if (reset_button_prev = '0' and reset_button = '1') then
						next_state <= COMMIT_OPERAND1;
					elsif (add_button_prev = '0' and add_button = '1') then
						operation <= ADD;
					elsif (multiply_button_prev = '0' and multiply_button = '1') then
						operation <= MULTIPLY;
					elsif (equal_button_prev = '0' and equal_button = '1') then
						result <= alu_result;
						next_state <= DISPLAY_RESULT;
					end if;
					
					data(0) <= std_logic_vector(operand2(3 downto 0));
					data(1) <= std_logic_vector(operand2(7 downto 4));
					data(2) <= X"0";
					data(3) <= X"0";
					
				when DISPLAY_RESULT =>
					
					if (reset_button_prev = '0' and reset_button = '1') then
						next_state <= COMMIT_OPERAND1;
					elsif (operand2_prev /= operand2) then --there was a sw[7:0] change
						next_state <= COMMIT_OPERAND1;
					elsif (add_button_prev = '0' and add_button = '1') then --rising_edge(add_button)
						operation <= ADD;
						next_state <= COMMIT_OPERAND2;
					elsif (multiply_button_prev = '0' and multiply_button = '1') then --rising_edge(multiply_button)
						operation <= MULTIPLY;
						next_state <= COMMIT_OPERAND2;
					end if;
					
					data(0) <= std_logic_vector(result(3 downto 0));
					data(1) <= std_logic_vector(result(7 downto 4));
					data(2) <= std_logic_vector(result (11 downto 8));
					data(3) <= std_logic_vector(result (15 downto 12));
					
			end case;
			
			equal_button_prev <= equal_button;
			add_button_prev <= add_button;
			multiply_button_prev <= multiply_button;
			reset_button_prev <= reset_button;
			
			operand2 <= signed(sw);
			operand2_prev <= operand2;
			
		end if;
	end process;
	
	--ALU Process
	process(operand2, result, operation)
	begin
		
		alu_operation <= operation;
		alu_operand1 <= result;
		alu_operand2 <= operand2;
		
		if (alu_operation = ADD) then
			alu_result <= alu_operand1 + alu_operand2;
		else
			alu_result <= alu_operand1 * alu_operand2;
		end if;
	end process;
	
end behavioural;
