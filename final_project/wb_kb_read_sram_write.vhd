library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY wb_kb_read_sram_write IS
  PORT(
    clk_i : IN STD_LOGIC;
    rst_i : IN STD_LOGIC;
    adr_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dat_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dat_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    ack_i : IN STD_LOGIC;
    cyc_o : OUT STD_LOGIC;
    stb_o : OUT STD_LOGIC;
    we_o  : OUT STD_LOGIC;
    irq_i : IN STD_LOGIC;
    irqv_i: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    spi_clock : OUT STD_LOGIC;
    spi_mosi : OUT STD_LOGIC;
    spi_miso : IN STD_LOGIC;
    spi_csn : OUT STD_LOGIC;
    spi_ce : OUT STD_LOGIC;
    spi_interrupt : IN STD_LOGIC;
    leds_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END wb_kb_read_sram_write;

ARCHITECTURE Behavioral OF wb_kb_read_sram_write IS

  CONSTANT break_code : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"F0";
  CONSTANT make_code_bksp : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"66";
  CONSTANT make_code_enter : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"5A";
  CONSTANT make_code_shift : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"12";
  CONSTANT make_code_ctrl : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"14";
  CONSTANT make_code_alt : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"11";

  CONSTANT buffer_end_marker : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"FF";

	-- Definitions for 2-bit slave addresses on the wishbone bus
	CONSTANT ram_slave_adr : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
	CONSTANT keyboard_slave_adr : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";

	-- Contains the address OF the slave we are currently interested IN communicating with
	SIGNAL slave_adr : STD_LOGIC_VECTOR(1 DOWNTO 0);

	-- Points TO location IN RAM that we are interested IN reading TO/writing from
  SIGNAL scratchpad_char_sram_adr : INTEGER RANGE 0 TO (2**24)-1;
  SIGNAL scratchpad_char_line_sram_adr : INTEGER RANGE 0 TO (2**24)-1;

  SIGNAL message_char_sram_adr : INTEGER RANGE 0 TO (2**24)-1;
  SIGNAL message_char_line_sram_adr : INTEGER RANGE 0 TO (2**24)-1;

	CONSTANT chars_per_line : INTEGER := 80;
	CONSTANT lines_per_page : INTEGER := 40;
	CONSTANT chars_per_page : INTEGER := chars_per_line * lines_per_page;
	CONSTANT char_width : INTEGER := 8;
	CONSTANT char_height : INTEGER := 12;
	CONSTANT pixels_per_word : INTEGER := 8;
	CONSTANT bits_per_pixel : INTEGER := 4;
  CONSTANT display_row_offset : INTEGER := chars_per_line * 4;
  CONSTANT character_row_offset : INTEGER := char_height * display_row_offset;

  -- Region for active editing
  CONSTANT scratchpad_region_start : INTEGER := char_height * chars_per_line * (lines_per_page-1) * 4;
  CONSTANT scratchpad_region_end : INTEGER := scratchpad_region_start + ((chars_per_line-1) * 4);

  SIGNAL message_char_row  : INTEGER RANGE 0 TO lines_per_page;

  SIGNAL tx_buf_index : INTEGER RANGE 0 TO 255;
  SIGNAL rx_buf_index : INTEGER RANGE 0 TO 255;

	SIGNAL txtcolor, bgcolor : STD_LOGIC_VECTOR(bits_per_pixel-1 DOWNTO 0);
	SIGNAL pixels : STD_LOGIC_VECTOR(char_width-1 DOWNTO 0);
	SIGNAL color_pixels : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL scan_line : INTEGER RANGE 0 TO 12;

	-- Store the last two received incoming scancodes
  SIGNAL scancode_buffer : STD_LOGIC_VECTOR(15 DOWNTO 0);

  TYPE module_states IS (reset_idle,
                        initialize_scratchpad_area,
                        initialize_scratchpad_sram_setup,
                        initialize_scratchpad_sram_write,
                        wait_for_irq, 
                        read_kbd, 
                        process_scancode,
                        tx_buf_write_setup,
                        tx_buf_write,
                        scratchpad_sram_write_setup,
                        scratchpad_sram_write,
                        pixel_lut_setup,
                        reset_scratchpad_area,
                        clear_scratchpad_sram_setup,
                        clear_scratchpad_sram_write,
                        tx_buf_to_message_area_init,
                        check_tx_buf_for_end_of_msg,
                        tx_message_pixel_data_setup,
                        tx_message_sram_write_setup,
                        tx_message_sram_write,
                        rx_buf_to_message_area_init,
                        check_rx_buf_for_end_of_msg,
                        rx_message_pixel_data_setup,
                        rx_message_sram_write_setup,
                        rx_message_sram_write
                        );

	SIGNAL current_state : module_states;
	
	SIGNAL ascii : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL pixel_lut_in : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL pixel_lut_src_sel : STD_LOGIC;
  SIGNAL code : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL shift, ctrl, alt : STD_LOGIC;

  SIGNAL tx_bufi : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL tx_buf_adr : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL rx_buf_adr : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL tx_buf_we : STD_LOGIC;
  SIGNAL tx_bufo_lut_dati : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL rx_bufo_lut_dati : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL rx_bufo_pb_dati : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL pb_tx_adr : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL tx_bufo_pb_dati : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL pb_rx_adr : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL rx_bufi : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL pb_rx_we : STD_LOGIC;

  SIGNAL sram_addr : STD_LOGIC_VECTOR(29 DOWNTO 0);
  SIGNAL sram_data : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL interrupt_pb : STD_LOGIC;

  SIGNAL tx_buffer_ready : STD_LOGIC;
  SIGNAL rx_buffer_ready : STD_LOGIC;
  SIGNAL reset_tx_buffer_ready : STD_LOGIC;
  SIGNAL reset_rx_buffer_ready : STD_LOGIC;

  SIGNAL led2 : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

  --adr_o <= slave_adr & "000000" & STD_LOGIC_VECTOR(TO_UNSIGNED(scratchpad_char_line_sram_adr, 24));
  adr_o <= slave_adr & sram_addr;
  dat_o <= sram_data;
  --dat_o <= color_pixels;

  -- SIGNAL data_to_sram; put a mux between color_pixels and this

  --bgcolor <= "0000";
  --txtcolor <= "1011";

  tx_buf_adr <= STD_LOGIC_VECTOR(TO_UNSIGNED(tx_buf_index, 8));
  rx_buf_adr <= STD_LOGIC_VECTOR(TO_UNSIGNED(rx_buf_index, 8));

  color_pixels(3 DOWNTO 0) <= bgcolor WHEN pixels(0) = '0' ELSE txtcolor;
  color_pixels(7 DOWNTO 4) <= bgcolor WHEN pixels(1) = '0' ELSE txtcolor;
  color_pixels(11 DOWNTO 8) <= bgcolor WHEN pixels(2) = '0' ELSE txtcolor;
  color_pixels(15 DOWNTO 12) <= bgcolor WHEN pixels(3) = '0' ELSE txtcolor;
  color_pixels(19 DOWNTO 16) <= bgcolor WHEN pixels(4) = '0' ELSE txtcolor;
  color_pixels(23 DOWNTO 20) <= bgcolor WHEN pixels(5) = '0' ELSE txtcolor;
  color_pixels(27 DOWNTO 24) <= bgcolor WHEN pixels(6) = '0' ELSE txtcolor;
  color_pixels(31 DOWNTO 28) <= bgcolor WHEN pixels(7) = '0' ELSE txtcolor;

  ascii_pixel_lut : ENTITY work.char8x12_lookup_table
  PORT MAP(
    clk => clk_i,
    reset => rst_i,
    ascii => pixel_lut_in,
    line => scan_line,
    pixels => pixels
  );

  pixel_lut_in <= tx_bufo_lut_dati WHEN pixel_lut_src_sel = '0' ELSE rx_bufo_lut_dati;

  scancode_ascii_lut : ENTITY work.scancode2ascii
  PORT MAP(
    scancode => code,
--    ascii => tx_bufi,
    ascii => ascii,
    shift => shift,
    ctrl => ctrl,
    alt => alt
  );

  transmit_buffer : ENTITY work.dual_port_buffer
  PORT MAP(
    data_in_primary => tx_bufi, -- data from the scratchpad region
    data_out_primary => tx_bufo_lut_dati, -- data to be written to the pixel LUT
    data_out_secondary => tx_bufo_pb_dati, -- data to be read by the picoblaze for transmission
    addr_in_primary => tx_buf_adr,-- address controlled by the scratchpad process
    addr_in_secondary => pb_tx_adr, -- address controlled by the picoblaze buffer reading process 
    we_primary => tx_buf_we, -- write enable controlled by the scratchpad process
    clk => clk_i
  );

  receive_buffer : ENTITY work.dual_port_buffer
  PORT MAP(
    data_in_primary => rx_bufi, -- data from the picoblaze receive process
    data_out_primary => rx_bufo_pb_dati,
    data_out_secondary => rx_bufo_lut_dati, -- received data going to the pixel LUT
    addr_in_primary => pb_rx_adr,
    addr_in_secondary => rx_buf_adr, -- the scratchpad process controls what received data does to the pixel LUT 
    we_primary => pb_rx_we,
    clk => clk_i
  );

  picoblaze_spi_master : ENTITY work.picoblaze_spi
  PORT MAP(
    clk => clk_i,
    reset => rst_i,
    spi_clock => spi_clock,
    spi_mosi => spi_mosi,
    spi_miso => spi_miso,
    spi_csn => spi_csn,
    spi_ce => spi_ce,
    spi_interrupt => spi_interrupt,
    rx_buf_addr => pb_rx_adr,
    tx_buf_addr => pb_tx_adr,
    rx_buf_data => rx_bufi,
    rx_buf_data_loopback => rx_bufo_pb_dati,
    tx_buf_data => tx_bufo_pb_dati,
    rx_buf_we => pb_rx_we,
    tx_buffer_ready => tx_buffer_ready, -- wishbone master signals to the picoblaze to transmit the tx_buffer
    reset_tx_buffer_ready => reset_tx_buffer_ready,-- picoblaze clears tx_buffer_ready signal
    rx_buffer_ready => rx_buffer_ready, -- picoblaze signals the the wishbone master that it can start reading data from receive buffer
    reset_rx_buffer_ready => reset_rx_buffer_ready, -- wishbone master resets interrupt
    led => led2
    --led => leds_o
  );

  leds_o <= "0000000" & rx_buffer_ready;

  -- Interrupt to picoblaze signaling the availability of data to be transmitted
  -- Reset by the picoblaze
  -------------------------------------------------------------------------------------------
  PROCESS(clk_i, rst_i, reset_tx_buffer_ready)
  BEGIN
    IF(rst_i = '1'OR reset_tx_buffer_ready = '1') THEN
        tx_buffer_ready <= '0';
    ELSIF(RISING_EDGE(clk_i)) THEN
      IF(interrupt_pb = '1') THEN
        tx_buffer_ready <= '1';
      END IF;
    END IF;
  END PROCESS;

  -- Handle (re)setting OF CTRL, shift AND ALT keys
  PROCESS(clk_i, rst_i)
  BEGIN
    IF(rst_i = '1') THEN
      shift <= '0';
      ctrl <= '0';
      alt <= '0';
		ELSIF(rising_edge(clk_i)) THEN	
			-- ALT key released
			IF(scancode_buffer = break_code & make_code_alt) THEN
				alt <= '0';
			-- shift key released
			ELSIF(scancode_buffer = break_code &  make_code_shift) THEN
				shift <= '0';
			-- CTRL key released
			ELSIF(scancode_buffer = break_code & make_code_ctrl) THEN
				ctrl <= '0';
			-- ALT key pressed
			ELSIF(scancode_buffer(7 DOWNTO 0) = make_code_alt) THEN
				alt <= '1';
			-- shift key pressed
			ELSIF(scancode_buffer(7 DOWNTO 0) = make_code_shift) THEN
				shift <= '1';
			-- CTRL key pressed
			ELSIF(scancode_buffer(7 DOWNTO 0) = make_code_ctrl) THEN
				ctrl <= '1';
			END IF;
		END IF;
	END PROCESS;

  -- Main state machine
  PROCESS(clk_i, rst_i)
  BEGIN
    IF(rst_i = '1') THEN
      cyc_o <= '0';
      stb_o <= '0';
      we_o <= '0';
      scan_line <= 0;
      message_char_sram_adr <= 0;
      message_char_row  <= 0;
      scancode_buffer <= X"0000";
      tx_buf_index <= 0;
      rx_buf_index <= 0;
      pixel_lut_src_sel <= '0';
      interrupt_pb <= '0';
      reset_rx_buffer_ready <= '0';
      current_state <= reset_idle;
      scratchpad_char_sram_adr <= scratchpad_region_start;
		ELSIF(rising_edge(clk_i)) THEN

      CASE current_state IS
        -- Fill the scratchpad area with it's background color
        --------------------------------------------------------------------
        WHEN reset_idle =>
          scratchpad_char_line_sram_adr <= scratchpad_char_sram_adr;
          current_state <= initialize_scratchpad_area;

        WHEN initialize_scratchpad_area =>
          cyc_o <= '1';
          current_state <= initialize_scratchpad_sram_setup;

        WHEN initialize_scratchpad_sram_setup =>
          sram_data <= "00010001000100010001000100010001";
          slave_adr <= ram_slave_adr;
          we_o <= '1';
          stb_o <= '1';
          sram_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(scratchpad_char_line_sram_adr, 30));
          current_state <= initialize_scratchpad_sram_write;

        WHEN initialize_scratchpad_sram_write =>
          IF(ack_i = '1') THEN
            stb_o <= '0';
            IF(scratchpad_char_line_sram_adr < scratchpad_region_end + character_row_offset) THEN
              scratchpad_char_line_sram_adr <= scratchpad_char_line_sram_adr + 4;
              current_state <= initialize_scratchpad_sram_setup;
            ELSE
              cyc_o <= '0';
              current_state <= wait_for_irq;
            END IF;
          END IF;

        -- Wait for an IRQ from the keyboard or from the Picoblaze
        -----------------------------------------------------------------------------
          WHEN wait_for_irq =>
					-- If the keyboard has generated an IRQ
					IF(irq_i = '1' AND irqv_i = keyboard_slave_adr) THEN
						stb_o <= '1';
						we_o <= '0';
						cyc_o <= '1';
						slave_adr <= keyboard_slave_adr;
						current_state <= read_kbd;
            bgcolor <= "0001";
            txtcolor <= "0000";
          ELSIF(rx_buffer_ready = '1') THEN
            rx_buf_index <= 0;
            current_state <= rx_buf_to_message_area_init;
					END IF;

				WHEN read_kbd =>
					IF(ack_i = '1') THEN
						stb_o <= '0';
						scancode_buffer(15 DOWNTO 8) <= scancode_buffer(7 DOWNTO 0);
						scancode_buffer(7 DOWNTO 0) <= dat_i(7 DOWNTO 0);
						current_state <= process_scancode;
					END IF;
				
				WHEN process_scancode =>
					IF(scancode_buffer(7 DOWNTO 0) = break_code OR -- Incoming break code
						scancode_buffer(7 DOWNTO 0) = make_code_alt OR -- ALT key pressed
						scancode_buffer(7 DOWNTO 0) = make_code_shift OR -- shift key pressed
						scancode_buffer(7 DOWNTO 0) = make_code_shift OR -- CTRL key pressed
						scancode_buffer(15 DOWNTO 8) = break_code ) THEN -- Received complete break code
						-- Go back to waiting for legitimate key press
						cyc_o <= '0';
						current_state <= wait_for_irq;
          ELSIF(scancode_buffer(7 DOWNTO 0) = make_code_bksp AND tx_buf_index > 0) THEN
            -- Move all references to point to the previous character on backspace
            tx_buf_index <= tx_buf_index - 1;
            scratchpad_char_sram_adr <= scratchpad_char_sram_adr - 4;
            scratchpad_char_line_sram_adr <= scratchpad_char_sram_adr - 4;
            current_state <= tx_buf_write_setup;
          ELSE
            scratchpad_char_line_sram_adr <= scratchpad_char_sram_adr;
            current_state <= tx_buf_write_setup;
          END IF;
          code <= scancode_buffer(7 DOWNTO 0);


        -- If 'enter' was pressed, append the end of text marker to the buffer notify picoblaze that it can transmit
        ---------------------------------------------------------------------------------------------------------------
        WHEN tx_buf_write_setup =>
          IF(scancode_buffer(7 DOWNTO 0) = make_code_enter) THEN
            tx_bufi <= buffer_end_marker;
          ELSE
            tx_bufi <= ascii;
          END IF;
          tx_buf_we <= '1';
          current_state <= tx_buf_write;

        WHEN tx_buf_write =>
          tx_buf_we <= '0';
          current_state <= scratchpad_sram_write_setup;

        WHEN pixel_lut_setup =>
          IF(tx_bufo_lut_dati = buffer_end_marker) THEN
            interrupt_pb <= '1'; -- Alert the picoblaze it can begin reading the tx_buffer
            current_state <= reset_scratchpad_area;
          ELSE
            current_state <= scratchpad_sram_write_setup;
          END IF;

        WHEN scratchpad_sram_write_setup =>
          sram_data <= color_pixels;
          slave_adr <= ram_slave_adr;
          we_o <= '1';
          stb_o <= '1';
          sram_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(scratchpad_char_line_sram_adr, 30));
          current_state <= scratchpad_sram_write;

        -- Write a character TO RAM, one line at a time
        WHEN scratchpad_sram_write =>
          IF(ack_i = '1') THEN
            stb_o <= '0';
            IF(scan_line < char_height) THEN -- Scanline less than 12
							-- Go to next line
							scratchpad_char_line_sram_adr <= scratchpad_char_line_sram_adr + display_row_offset;
							scan_line <= scan_line + 1;
							current_state <= pixel_lut_setup;
            ELSE
              scan_line <= 0;
              cyc_o <= '0'; -- Release bus AND go back TO waiting for keyboard input
              current_state <= wait_for_irq;
              IF(scancode_buffer(7 DOWNTO 0) /= make_code_bksp) THEN
                scratchpad_char_sram_adr <= scratchpad_char_sram_adr + 4;
                tx_buf_index <= tx_buf_index + 1;
              END IF;
            END IF;
          END IF;

        WHEN reset_scratchpad_area =>
          interrupt_pb <= '0'; -- Interrupt has already been clocked in, deassert pulse
          tx_buf_index <= 0;
          scratchpad_char_sram_adr <= scratchpad_region_start;
          scratchpad_char_line_sram_adr <= scratchpad_region_start;
          current_state <= clear_scratchpad_sram_setup;
          
        WHEN clear_scratchpad_sram_setup =>
          sram_data <= "00010001000100010001000100010001";
          slave_adr <= ram_slave_adr;
          we_o <= '1';
          stb_o <= '1';
          sram_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(scratchpad_char_line_sram_adr, 30));
          current_state <= clear_scratchpad_sram_write;

        WHEN clear_scratchpad_sram_write =>
          IF(ack_i = '1') THEN
            stb_o <= '0';
            IF(scratchpad_char_line_sram_adr < scratchpad_region_end + character_row_offset) THEN
              scratchpad_char_line_sram_adr <= scratchpad_char_line_sram_adr + 4;
              current_state <= clear_scratchpad_sram_setup;
            ELSE
              scratchpad_char_line_sram_adr <= scratchpad_char_sram_adr;
              current_state <= tx_buf_to_message_area_init;
              cyc_o <= '0';
            END IF;
          END IF;

        -----------------------------------------------------------------------------------
        -- Responsible for writing the transmit message buffer contents to SRAM
        -----------------------------------------------------------------------------------

        WHEN tx_buf_to_message_area_init =>
          bgcolor <= "0000";
          txtcolor <= "0001";
          --cyc_o <= '1';
          message_char_line_sram_adr <= message_char_sram_adr;
          IF(message_char_row  < lines_per_page - 2) THEN
            message_char_row  <= message_char_row  + 1;
          ELSE
            message_char_row  <= 0;
          END IF;
          current_state <= check_tx_buf_for_end_of_msg;

        -- Verify that there is still valid data to transmit
        -------------------------------------------------------------
        WHEN check_tx_buf_for_end_of_msg =>
          IF(tx_bufo_lut_dati = buffer_end_marker) THEN
            message_char_sram_adr <= character_row_offset * message_char_row ;
            cyc_o <= '0';
            tx_buf_index <= 0;
            current_state <= wait_for_irq;
          ELSE
            cyc_o <= '1';
            message_char_line_sram_adr <= message_char_sram_adr;
            current_state <= tx_message_pixel_data_setup;
          END IF;

        -- Extra cycle for pixel LUT data to become valid
        -----------------------------------------------------------
        WHEN tx_message_pixel_data_setup =>
          current_state <= tx_message_sram_write_setup;

        WHEN tx_message_sram_write_setup =>
          we_o <= '1';
          stb_o <= '1';
          slave_adr <= ram_slave_adr;
          sram_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(message_char_line_sram_adr, 30));
          sram_data <= color_pixels;
          current_state <= tx_message_sram_write;

        WHEN tx_message_sram_write =>
          IF(ack_i = '1') THEN
            stb_o <= '0';
            IF(scan_line < char_height) THEN
              message_char_line_sram_adr <= message_char_line_sram_adr + display_row_offset;
              scan_line <= scan_line + 1;
              current_state <= tx_message_pixel_data_setup;
            ELSE
              scan_line <= 0;
              tx_buf_index <= tx_buf_index + 1;
              message_char_sram_adr <= message_char_sram_adr + 4;
              current_state <= check_tx_buf_for_end_of_msg;
            END IF;
          END IF;

        -----------------------------------------------------------------------------------
        -- Responsible for writing the receive message buffer to the display
        -----------------------------------------------------------------------------------

        WHEN rx_buf_to_message_area_init =>
          bgcolor <= "0000";
          txtcolor <= "0010";
          cyc_o <= '1';
          pixel_lut_src_sel <= '1';
          reset_rx_buffer_ready <= '1';
          message_char_line_sram_adr <= message_char_sram_adr;
          IF(message_char_row  < lines_per_page - 2) THEN
            message_char_row  <= message_char_row  + 1;
          ELSE
            message_char_row  <= 0;
          END IF;
          current_state <= check_rx_buf_for_end_of_msg;

        -- Verify that there is still valid data to transmit
        -------------------------------------------------------------
        WHEN check_rx_buf_for_end_of_msg =>
          IF(rx_bufo_lut_dati = buffer_end_marker) THEN
            message_char_sram_adr <= character_row_offset * message_char_row ;
            cyc_o <= '0';
            pixel_lut_src_sel <= '0';
            current_state <= wait_for_irq;
          ELSE
            message_char_line_sram_adr <= message_char_sram_adr;
            current_state <= rx_message_pixel_data_setup;
          END IF;
          reset_rx_buffer_ready <= '0';

        -- Extra cycle for pixel LUT data to become valid
        -----------------------------------------------------------
        WHEN rx_message_pixel_data_setup =>
          current_state <= rx_message_sram_write_setup;

        WHEN rx_message_sram_write_setup =>
          we_o <= '1';
          stb_o <= '1';
          slave_adr <= ram_slave_adr;
          sram_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(message_char_line_sram_adr, 30));
          sram_data <= color_pixels;
          current_state <= rx_message_sram_write;

        WHEN rx_message_sram_write =>
          IF(ack_i = '1') THEN
            stb_o <= '0';
            IF(scan_line < char_height) THEN
              message_char_line_sram_adr <= message_char_line_sram_adr + display_row_offset;
              scan_line <= scan_line + 1;
              current_state <= rx_message_pixel_data_setup;
            ELSE
              scan_line <= 0;
              rx_buf_index <= rx_buf_index + 1;
              message_char_sram_adr <= message_char_sram_adr + 4;
              current_state <= check_rx_buf_for_end_of_msg;
            END IF;
          END IF;

			END CASE;
		END IF;
	END PROCESS;

END Behavioral;
