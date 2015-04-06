library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY dual_port_ram IS
  GENERIC(
    data_bit_width : INTEGER := 32;
    address_bit_width : INTEGER := 8
  );
  PORT(
    data_in_a : IN STD_LOGIC_VECTOR(data_bit_width-1 DOWNTO 0);
    data_in_b : IN STD_LOGIC_VECTOR(data_bit_width-1 DOWNTO 0);
    data_out_a : OUT STD_LOGIC_VECTOR(data_bit_width-1 DOWNTO 0);
    data_out_b : OUT STD_LOGIC_VECTOR(data_bit_width-1 DOWNTO 0);
    addr_a : IN STD_LOGIC_VECTOR(address_bit_width-1 DOWNTO 0);
    addr_b : IN STD_LOGIC_VECTOR(address_bit_width-1 DOWNTO 0);
    we_a : IN STD_LOGIC;
    we_b : IN STD_LOGIC;
    clk_a : IN STD_LOGIC;
    clk_b : IN STD_LOGIC
  );
END dual_port_ram;

ARCHITECTURE Behavioral OF dual_port_ram IS

  CONSTANT number_of_words : INTEGER := 2**address_bit_width; 

  TYPE data_words IS ARRAY (0 TO number_of_words-1) OF STD_LOGIC_VECTOR(data_bit_width-1 DOWNTO 0); 
  SHARED VARIABLE data_word : data_words;

BEGIN

  ----------------------------------------------------
  -- PORTA
  ----------------------------------------------------
  PROCESS(clk_a)
  BEGIN

    IF(RISING_EDGE(clk_a)) THEN
      IF(we_a = '1') THEN
        data_word(TO_INTEGER(UNSIGNED(addr_a))) := data_in_a;
      END IF;
        data_out_a <= data_word(TO_INTEGER(UNSIGNED(addr_a)));
    END IF;
  END PROCESS;

  ----------------------------------------------------
  -- PORTB
  ----------------------------------------------------
  PROCESS(clk_b)
  BEGIN

    IF(RISING_EDGE(clk_b)) THEN
      IF(we_b = '1') THEN
        data_word(TO_INTEGER(UNSIGNED(addr_b))) := data_in_b;
      END IF;
        data_out_b <= data_word(TO_INTEGER(UNSIGNED(addr_b)));
    END IF;
  END PROCESS;

END Behavioral;

