LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;


ENTITY counter IS
    PORT(
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        enable : IN STD_LOGIC;
        top : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        done : OUT STD_LOGIC
    );
END counter;

ARCHITECTURE logical OF counter IS

    SIGNAL compare : UNSIGNED(23 DOWNTO 0);

BEGIN

    PROCESS(clk, reset, enable)
    BEGIN
        IF(reset = '1' OR enable = '1') THEN
            done <= '0';
            compare <= X"000000";
        ELSIF(RISING_EDGE(clk)) THEN
            IF(STD_LOGIC_VECTOR(compare) < top) THEN
                compare <= compare + 1;
            ELSE
                done <= '1';
            END IF;
        END IF;
    END PROCESS;

END logical;
