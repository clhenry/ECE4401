library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY dual_port_buffer IS
  PORT(
    data_in_primary : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    data_out_primary : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    data_out_secondary : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    addr_in_primary : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    addr_in_secondary: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    we_primary : IN STD_LOGIC;
    clk : IN STD_LOGIC
  );
END dual_port_buffer;

ARCHITECTURE Behavioral OF dual_port_buffer IS

  TYPE data_words IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR(7 DOWNTO 0); 
  SIGNAL data_word : data_words;

BEGIN

  ----------------------------------------------------
  -- PORTA
  ----------------------------------------------------
  PROCESS(clk)
  BEGIN
    IF(RISING_EDGE(clk)) THEN
      IF(we_primary = '1') THEN
        data_word(TO_INTEGER(UNSIGNED(addr_in_primary))) <= data_in_primary;
      END IF;
    data_out_primary <= data_word(TO_INTEGER(UNSIGNED(addr_in_primary)));
    END IF;
  END PROCESS;
  ----------------------------------------------------
  -- PORTB
  ----------------------------------------------------
  PROCESS(clk)
  BEGIN
    IF(RISING_EDGE(clk)) THEN
      data_out_secondary <= data_word(TO_INTEGER(UNSIGNED(addr_in_secondary)));
    END IF;
  END PROCESS;
  
END Behavioral;

