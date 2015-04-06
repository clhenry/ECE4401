library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY picoblaze_spi IS
    PORT(
      clk : IN STD_LOGIC;
      reset : IN STD_LOGIC;
      spi_clock : OUT STD_LOGIC;
      spi_mosi : OUT STD_LOGIC;
      spi_miso : IN STD_LOGIC;
      spi_csn : OUT STD_LOGIC;
      spi_ce : OUT STD_LOGIC;
      spi_interrupt : IN STD_LOGIC;
      rx_buf_addr : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      rx_buf_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      rx_buf_data_loopback : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      rx_buf_we : OUT STD_LOGIC;
      tx_buf_addr : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      tx_buf_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      tx_buffer_ready : IN STD_LOGIC; -- wishbone master signals to the picoblaze to transmit the tx_buffer
      reset_tx_buffer_ready : OUT STD_LOGIC; -- picoblaze clears tx_buffer_ready signal
      rx_buffer_ready : OUT STD_LOGIC; -- picoblaze signals the the wishbone master that it can start reading data from receive buffer
      reset_rx_buffer_ready : IN STD_LOGIC; -- wishbone master resets interrupt
      led : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END picoblaze_spi;

ARCHITECTURE Behavioral OF picoblaze_spi IS

  --SIGNAL led2 : STD_LOGIC_VECTOR(7 DOWNTO 0);

  ---------------------------------------
  -- PicoBlaze State Machine Component
  ---------------------------------------
  COMPONENT kcpsm3
  PORT(
    address : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    instruction : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    port_id : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    write_strobe : OUT STD_LOGIC;
    out_port : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    read_strobe : OUT STD_LOGIC;
    in_port : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    interrupt : IN STD_LOGIC;
    interrupt_ack : OUT STD_LOGIC;
    reset : IN STD_LOGIC;
    clk : IN STD_LOGIC
  );
  END COMPONENT;

  -----------------------------------------------
  -- PicoBlaze ROM Component
  -----------------------------------------------
  COMPONENT rom
  PORT(
    address : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    instruction : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
    clk : IN STD_LOGIC
  );
  END COMPONENT;

  --------------------------------------------
  -- PicoBlaze Interconnects
  --------------------------------------------
  SIGNAL address : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL instruction : STD_LOGIC_VECTOR(17 DOWNTO 0);
  SIGNAL port_id : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL out_port : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL in_port : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL write_strobe : STD_LOGIC;
  SIGNAL read_strobe : STD_LOGIC;
  SIGNAL interrupt_ack : STD_LOGIC;
  SIGNAL system_reset : STD_LOGIC;
  SIGNAL interrupt : STD_LOGIC;

  ---------------------------------------------------------------------
  SIGNAL spi_tx_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL spi_tx_data_write : STD_LOGIC;
  SIGNAL spi_rx_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL spi_control_write : STD_LoGIC;
  SIGNAL spi_enable : STD_LOGIC;
  SIGNAL spi_busy : STD_LOGIC;
  SIGNAL spi_csn_write : STD_LOGIC;
  SIGNAL spi_ce_write : STD_LOGIC;

  SIGNAL led_write : STD_LOGIC;

  SIGNAL interrupt_wb : STD_LOGIC;
  SIGNAL interrupt_wb_write : STD_LOGIC;

  SIGNAL counter_enable : STD_LOGIC;
  SIGNAL counter_control_write : STD_LOGIC;
  SIGNAL counter_done : STD_LOGIC;
  SIGNAL counter_config : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL counter_config0_write : STD_LOGIC;
  SIGNAL counter_config1_write : STD_LOGIC;
  SIGNAL counter_config2_write : STD_LOGIC;

  SIGNAL rx_buf_addr_write : STD_LOGIC;
  SIGNAL rx_buf_data_write : STD_LOGIC;
  SIGNAL rx_buf_we_write : STD_LOGIC;

  SIGNAL tx_buf_addr_write : STD_LOGIC;

  SIGNAL reset_tx_buffer_ready_write : STD_LOGIC;

  ------------------------------------------------------------------
  ------------------------------------------------------------------
  -- Writeable PIDs
  ------------------------------------------------------------------
  ------------------------------------------------------------------

  -- SPI Writeable PIDs
  ------------------------------------------- 
  CONSTANT spi_tx_data_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"00";
  CONSTANT spi_control_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"01";
  CONSTANT spi_csn_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"02";
  CONSTANT spi_ce_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"03";

  -- LED Writeable PIDs
  -----------------------------------------------------------------------
  CONSTANT led_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"04";

  -- Counter Writeable PIDs
  -----------------------------------------------------------------------
  CONSTANT counter_config0_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"05";
  CONSTANT counter_config1_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"06";
  CONSTANT counter_config2_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"07";
  CONSTANT counter_control_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"08";


  -- Message Buffer Writeable PIDs
  --------------------------------------------------------------------------
  CONSTANT rx_buf_data_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"09";
  CONSTANT rx_buf_addr_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"0A";
  CONSTANT rx_buf_we_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"0B";

  CONSTANT tx_buf_addr_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"0C";

  CONSTANT reset_tx_buffer_ready_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"0D";

  CONSTANT interrupt_wb_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"0F";

  ------------------------------------------------------------------
  ------------------------------------------------------------------
  -- Readable PIDs
  ------------------------------------------------------------------
  ------------------------------------------------------------------

  -- SPI Readable PIDs
  --------------------------------------------------------------
  CONSTANT spi_rx_data_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"00";
  CONSTANT spi_status_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"01";
  CONSTANT spi_interrupt_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"02";

  -- Counter Readable PIDs
  ---------------------------------------------------------------
  CONSTANT counter_status_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"03";


  -- Message Buffer Readable PIDs
  -------------------------------------------------------------------
  CONSTANT tx_buf_data_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"04";

  CONSTANT tx_buffer_ready_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"05";

  CONSTANT rx_buf_data_loopback_pid : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"06";


BEGIN

--  interrupt <= wb_to_pb_irq OR NOT spi_interrupt;
  interrupt <= tx_buffer_ready OR NOT spi_interrupt;

  system_reset <= reset;

  -- Interrupt to wishbone master signaling the availability of received data
  -- Reset by wishbone master
  -------------------------------------------------------------------------------------------
  PROCESS(clk, system_reset, reset_rx_buffer_ready)
  BEGIN
    IF(system_reset = '1' OR reset_rx_buffer_ready = '1') THEN
        rx_buffer_ready <= '0';
    ELSIF(RISING_EDGE(clk)) THEN
      IF(interrupt_wb = '1') THEN
        rx_buffer_ready <= '1';
      END IF;
    END IF;
  END PROCESS;

  ------------------------------------
  -- PicoBlaze State Machine Instance
  ------------------------------------
  processor: kcpsm3
  PORT MAP(
    address => address,
    instruction => instruction,
    port_id => port_id,
    write_strobe => write_strobe,
    out_port => out_port,
    read_strobe => read_strobe,
    in_port => in_port,
    interrupt => interrupt,
    interrupt_ack => interrupt_ack,
    reset => system_reset,
    clk => clk
  );

  ------------------------------------
  -- PicoBlaze ROM Instance
  ------------------------------------
  program: rom
  PORT MAP(
    address => address,
    instruction => instruction,
    clk => clk
  );

  -------------------------------------
  -- SPI Master Module
  -------------------------------------
  spi_master : ENTITY work.spi_master
  PORT MAP(
    reset => system_reset,
    clk => clk,
    tx_data => spi_tx_data,
    rx_data => spi_rx_data,
    sck => spi_clock,
    mosi => spi_mosi,
    miso => spi_miso,
    busy => spi_busy,
    enable => spi_enable
  );

  -----------------------------------
  -- Clock Cycle Module
  -----------------------------------
  counter_timer : ENTITY work.counter
  PORT MAP(
    clk => clk,
    reset => system_reset,
    enable => counter_enable,
    top => counter_config,
    done => counter_done
  );

  ---------------------------------------------
  -- PicoBlaze INPUT Demultiplexer
  ---------------------------------------------
  input_ports: PROCESS(clk)
  BEGIN
    IF(RISING_EDGE(clk)) THEN
      CASE port_id IS

        WHEN spi_status_pid =>
          in_port <= "0000000" & spi_busy;

        WHEN spi_rx_data_pid =>
          in_port <= spi_rx_data;

        WHEN counter_status_pid =>
          in_port <= "0000000" & counter_done;

        WHEN tx_buffer_ready_pid =>
          in_port <= "0000000" & tx_buffer_ready;

        WHEN spi_interrupt_pid =>
          in_port <= "0000000" & NOT spi_interrupt;

        WHEN rx_buf_data_loopback_pid =>
          in_port <= rx_buf_data_loopback;

        WHEN tx_buf_data_pid =>
          in_port <= tx_buf_data;

        WHEN OTHERS =>
          in_port <= spi_rx_data;

      END CASE;
    END IF;
  END PROCESS input_ports;

  ---------------------------------------------
  -- PicoBlaze OUTPUT Multiplexer
  ---------------------------------------------
  output_ports: PROCESS(clk, system_reset)
  BEGIN
    IF(system_reset = '1') THEN
      led(6 DOWNTO 0) <= "0000000";
      --led2 <= X"00";
    ELSIF(RISING_EDGE(clk)) THEN
      CASE port_id IS

        WHEN spi_control_pid =>
          IF(spi_control_write = '1') THEN
            spi_enable <= out_port(0);
          END IF;

        WHEN spi_tx_data_pid =>
          IF(spi_tx_data_write = '1') THEN
            spi_tx_data <= out_port;
          END IF;

        WHEN counter_config0_pid =>
          IF(counter_config0_write = '1') THEN
            counter_config(7 DOWNTO 0) <= out_port;
          END IF;

        WHEN counter_config1_pid =>
          IF(counter_config1_write = '1') THEN
            counter_config(15 DOWNTO 8) <= out_port;
          END IF;

        WHEN counter_config2_pid =>
          IF(counter_config2_write = '1') THEN
            counter_config(23 DOWNTO 16) <= out_port;
          END IF;

        WHEN counter_control_pid =>
          IF(counter_control_write = '1') THEN
            counter_enable <= out_port(0);
          END IF;

        WHEN spi_ce_pid =>
          IF(spi_ce_write = '1') THEN
            spi_ce <= out_port(0);
          END IF;

        WHEN spi_csn_pid =>
          IF(spi_csn_write = '1') THEN
            spi_csn <= out_port(0);
          END IF;

        WHEN rx_buf_addr_pid =>
          IF(rx_buf_addr_write = '1') THEN
            rx_buf_addr <= out_port;
          END IF;

        WHEN rx_buf_data_pid =>
          IF(rx_buf_data_write = '1') THEN
            rx_buf_data <= out_port;
          END IF;

        WHEN rx_buf_we_pid =>
          IF(rx_buf_we_write = '1') THEN
            rx_buf_we <= out_port(0);
          END IF;

        WHEN tx_buf_addr_pid =>
          IF(tx_buf_addr_write = '1') THEN
            tx_buf_addr <= out_port;
          END IF;

        WHEN reset_tx_buffer_ready_pid =>
          IF(reset_tx_buffer_ready_write = '1') THEN
            reset_tx_buffer_ready <= out_port(0);
          END IF;

        WHEN interrupt_wb_pid =>
          IF(interrupt_wb_write = '1') THEN
            interrupt_wb <= out_port(0);
          END IF;

        WHEN led_pid =>
          IF(led_write = '1') THEN
            led <= out_port;
            --led2 <= out_port;
          END IF;

        WHEN OTHERS =>
          IF(led_write = '1') THEN
            led <= out_port;
            --led2 <= out_port;
          END IF;

      END CASE;
    END IF;
  END PROCESS output_ports;

  spi_tx_data_write <= '1' WHEN port_id = spi_tx_data_pid AND write_strobe = '1' ELSE '0';
  spi_control_write <= '1' WHEN port_id = spi_control_pid AND write_strobe = '1' ELSE '0';
  spi_ce_write <= '1' WHEN port_id = spi_ce_pid AND write_strobe = '1' ELSE '0';
  spi_csn_write <= '1' WHEN port_id = spi_csn_pid AND write_strobe = '1' ELSE '0';

  counter_config0_write <= '1' WHEN port_id = counter_config0_pid AND write_strobe = '1' ELSE '0';
  counter_config1_write <= '1' WHEN port_id = counter_config1_pid AND write_strobe = '1' ELSE '0';
  counter_config2_write <= '1' WHEN port_id = counter_config2_pid AND write_strobe = '1' ELSE '0';
  counter_control_write <= '1' WHEN port_id = counter_control_pid AND write_strobe = '1' ELSE '0';

  led_write <= '1' WHEN port_id = led_pid AND write_strobe = '1' ELSE '0';

  interrupt_wb_write <= '1' WHEN port_id = interrupt_wb_pid AND write_strobe = '1' ELSE '0';
  
  rx_buf_addr_write <= '1' WHEN port_id = rx_buf_addr_pid AND write_strobe = '1' ELSE '0';
  rx_buf_data_write <= '1' WHEN port_id = rx_buf_data_pid AND write_strobe = '1' ELSE '0';
  rx_buf_we_write <= '1' WHEN port_id = rx_buf_we_pid AND write_strobe = '1' ELSE '0';

  tx_buf_addr_write <= '1' WHEN port_id = tx_buf_addr_pid AND write_strobe = '1' ELSE '0';

  reset_tx_buffer_ready_write <= '1' WHEN port_id = reset_tx_buffer_ready_pid AND write_strobe = '1' ELSE '0';

  interrupt_wb_write <= '1' WHEN port_id = interrupt_wb_pid AND write_strobe = '1' ELSE '0';


  

END Behavioral;
