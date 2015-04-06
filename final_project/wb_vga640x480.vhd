library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY wb_vga640x480 IS
  PORT(
    sys_clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    adr_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dat_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dat_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    ack_i : IN STD_LOGIC;
    cyc_o : OUT STD_LOGIC;
    stb_o : OUT STD_LOGIC;
    we_o : OUT STD_LOGIC;
    red : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    green : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    blue : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    hsync : OUT STD_LOGIC;
    vsync : OUT STD_LOGIC
  );
END wb_vga640x480;

ARCHITECTURE Behavioral OF wb_vga640x480 IS

  -------------------------------------------------
  -- Vertical Timing Definitions
  -------------------------------------------------
  CONSTANT visible_lines_per_frame : INTEGER := 480;
  CONSTANT lines_per_frame : INTEGER := 524;
  CONSTANT vsync_front_porch_width : INTEGER := 11; -- Was 10
  CONSTANT vsync_width : INTEGER := 2;
  CONSTANT vsync_back_porch_width : INTEGER := 31; -- Was 29
  CONSTANT first_visible_line : INTEGER := vsync_front_porch_width + vsync_width + vsync_back_porch_width;
  CONSTANT last_visible_line : INTEGER := first_visible_line + visible_lines_per_frame - 1;

  -------------------------------------------------
  -- Horizontal Timming Definitions
  -------------------------------------------------
  CONSTANT visible_pixels_per_line : INTEGER := 640;
  CONSTANT pixels_per_line : INTEGER := 800;
  CONSTANT hsync_front_porch_width : INTEGER := 16;
  CONSTANT hsync_width : INTEGER := 96;
  CONSTANT hsync_back_porch_width : INTEGER := 48;
  CONSTANT leftmost_visible_pixel : INTEGER := hsync_front_porch_width + hsync_width + hsync_back_porch_width;
  CONSTANT rightmost_visible_pixel : INTEGER := leftmost_visible_pixel + visible_pixels_per_line - 1;

  CONSTANT character_columns : INTEGER := 80;
  CONSTANT character_rows : INTEGER := 40;
  CONSTANT chars_per_frame : INTEGER := character_columns * character_rows;
  CONSTANT lines_per_char : INTEGER := 12;
  CONSTANT pixels_per_word : INTEGER := 8;
  CONSTANT bits_per_pixel : INTEGER := 4;

  SIGNAL pixel_clk : STD_LOGIC;
  SIGNAL line_count : INTEGER RANGE 0 TO lines_per_frame;
  SIGNAL pixel_count : INTEGER RANGE 0 TO pixels_per_line;
  SIGNAL display_valid : STD_LOGIC;
  SIGNAL hdisplay_valid : STD_LOGIC;
  SIGNAL vdisplay_valid : STD_LOGIC;

  SIGNAL pixel : STD_LOGIC_VECTOR(bits_per_pixel-1 DOWNTO 0);
  SIGNAL pixnum : INTEGER RANGE 0 TO pixels_per_word-1;
  SIGNAL pixel_offset : INTEGER RANGE 0 TO visible_pixels_per_line;
  SIGNAL line_offset : INTEGER RANGE 0 TO visible_lines_per_frame;

  SIGNAL bgcolor : STD_LOGIC_VECTOR(bits_per_pixel-1 DOWNTO 0);

  CONSTANT max_memory_address : INTEGER := character_columns * visible_lines_per_frame * 4;

  -- Definitions for 2-bit slave addresses on the wishbone bus
  CONSTANT wb_slave_ram : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";

  SIGNAL character_line : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL sram_addr : UNSIGNED(29 DOWNTO 0);

  TYPE producer_states IS (horizontal_blanking, vertical_blanking, write_row_buffer, filling_row_buffer, read_sram, row_buffer_full, prefill_display_area, write_sram);
  SIGNAL producer_state : producer_states;
  SIGNAL producer_addr : INTEGER RANGE 0 TO character_columns;
  SIGNAL addr_a : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL producer_we : STD_LOGIC;

  SIGNAL consumer_addr : INTEGER RANGE 0 TO character_columns;
  SIGNAL addr_b : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL consumer_we : STD_LOGIC;

BEGIN

  bgcolor <= "0000";

  addr_a <= STD_LOGIC_VECTOR(TO_UNSIGNED(producer_addr, addr_a'LENGTH));
  addr_b <= STD_LOGIC_VECTOR(TO_UNSIGNED(consumer_addr, addr_b'LENGTH));

  ----------------------------------------------
  -- Display Line Buffer
  ----------------------------------------------
  line_buffer : ENTITY work.dual_port_ram
  GENERIC MAP(
    address_bit_width => 7
  )
  PORT MAP(
    data_in_a => dat_i,
    data_in_b => X"00000000",
    data_out_a => OPEN,
    data_out_b => character_line,
    addr_a => addr_a,
    addr_b => addr_b,
    we_a => producer_we,
    we_b => consumer_we,
    clk_a => sys_clk,
    clk_b => sys_clk
  );

  ----------------------------------------
  -- Pixel Clock
  ----------------------------------------
  PROCESS(sys_clk, reset)
  BEGIN
    IF(reset = '1') THEN
      pixel_clk <= '0';
    ELSIF(RISING_EDGE(sys_clk)) THEN
      pixel_clk <= NOT pixel_clk;
    END IF;
  END PROCESS;

	-- Points to the current line number of the visible region
	line_offset <= line_count - first_visible_line;
	-- Points to the current pixel number of the visible region
	pixel_offset <= pixel_count - leftmost_visible_pixel;
	-- Points to a pixel within the current character
	pixnum <= pixel_offset MOD pixels_per_word;
	
	adr_o <= wb_slave_ram & STD_LOGIC_VECTOR(sram_addr);

  ----------------------------------------------------------
  -- Producer Fills Buffer With Row Of Characters From SRAM
  ----------------------------------------------------------
  PROCESS(sys_clk, reset)
  BEGIN
    IF(reset = '1') THEN
      we_o <= '0';
      stb_o <= '0';
      cyc_o <= '0';
      producer_we <= '0';
      sram_addr <= (OTHERS => '0');
      producer_state <= prefill_display_area;
    ELSIF(RISING_EDGE(sys_clk)) THEN

      CASE producer_state IS

        WHEN prefill_display_area =>
          IF(sram_addr < max_memory_address) THEN
            cyc_o <= '1';
            we_o <= '1';
            stb_o <= '1';
            dat_o <= bgcolor & bgcolor & bgcolor & bgcolor & bgcolor & bgcolor & bgcolor & bgcolor;
            producer_state <= write_sram;
          ELSE
            cyc_o <= '0';
            we_o <= '0';
            sram_addr <= (OTHERS => '0');
            producer_state <= vertical_blanking;
          END IF;

        WHEN vertical_blanking =>
          IF(vdisplay_valid = '0' AND hdisplay_valid = '0') THEN
            sram_addr <= (OTHERS => '0');
          ELSE
            producer_state <= horizontal_blanking;
          END IF;

        WHEN horizontal_blanking =>
          IF(hdisplay_valid = '0') THEN
            producer_addr <= 0;
            producer_state <= filling_row_buffer;
          END IF;

        WHEN filling_row_buffer =>
          IF(producer_addr < character_columns) THEN
            stb_o <= '1';
            cyc_o <= '1';
            producer_state <= read_sram;
          ELSE
            cyc_o <= '0';
            producer_state <= row_buffer_full;
          END IF;

        WHEN read_sram =>
          IF(ack_i = '1') THEN
            stb_o <= '0';
            producer_we <= '1';
            sram_addr <= sram_addr + 4;
            producer_state <= write_row_buffer;
          END IF;

        WHEN write_row_buffer =>
            producer_we <= '0';
            producer_addr <= producer_addr + 1;
            producer_state <= filling_row_buffer;

        WHEN write_sram =>
          IF(ack_i = '1') THEN
            stb_o <= '0';
            sram_addr <= sram_addr + 4;
            producer_state <= prefill_display_area;
          END IF;

        WHEN row_buffer_full =>
          IF(vdisplay_valid = '1' AND hdisplay_valid = '0') THEN
            producer_state <= horizontal_blanking;
          ELSIF(vdisplay_valid = '0' AND hdisplay_valid = '0') THEN
            producer_state <= vertical_blanking;
          END IF;

      END CASE;
    END IF;
  END PROCESS;

  --------------------------------------------------
  -- Consumer Reads Character Line From Buffer 
  --------------------------------------------------
  PROCESS(pixel_clk, reset)
  BEGIN
    IF(reset = '1') THEN
      consumer_addr <= 0;
      consumer_we <= '0';
--      consumer_state <= blnking_period;
    ELSIF(RISING_EDGE(pixel_clk)) THEN
      IF(hdisplay_valid = '0') THEN
        consumer_addr <= 0;
      ELSIF(display_valid = '1' AND pixnum = 7 AND pixel_offset > 0) THEN
        consumer_addr <= consumer_addr + 1;
      END IF;
    END IF;
  END PROCESS;

  pixel <= character_line(3 DOWNTO 0) WHEN pixnum = 0 ELSE
          character_line(7 DOWNTO 4) WHEN pixnum = 1 ELSE
          character_line(11 DOWNTO 8) WHEN pixnum = 2 ELSE
          character_line(15 DOWNTO 12) WHEN pixnum = 3 ELSE
          character_line(19 DOWNTO 16) WHEN pixnum = 4 ELSE
          character_line(23 DOWNTO 20) WHEN pixnum = 5 ELSE
          character_line(27 DOWNTO 24) WHEN pixnum = 6 ELSE
          character_line(31 DOWNTO 28);

  ------------------------------------------------------------------
  -- Each Pixel Consists Of Red, Green And Blue Components
  ------------------------------------------------------------------
  red <= pixel(3 DOWNTO 2) & "0" WHEN display_valid = '1' ELSE "000";
  green <= pixel(1) & "00" WHEN display_valid = '1' ELSE "000";
  blue <= pixel(0) & "0" WHEN display_valid = '1' ELSE "00";

  vdisplay_valid <= '1' WHEN (line_count >= first_visible_line AND line_count <= last_visible_line) ELSE '0';
  hdisplay_valid <= '1' WHEN (pixel_count >= leftmost_visible_pixel AND pixel_count <= rightmost_visible_pixel) ELSE '0';
  display_valid <= hdisplay_valid AND vdisplay_valid;

  hsync <= '0' WHEN pixel_count >= hsync_front_porch_width AND pixel_count < hsync_front_porch_width+hsync_width ELSE '1';
  vsync <= '0' WHEN (line_count >= vsync_front_porch_width AND line_count < vsync_front_porch_width+vsync_width) ELSE '1';

  -----------------------------------------------------
  -- Current Pixel Of the Current Line
  -----------------------------------------------------
  pixel_count_process: PROCESS(pixel_clk, reset)
  BEGIN
    IF(reset = '1') THEN
      pixel_count <= 0;
    ELSIF(RISING_EDGE(pixel_clk)) THEN
      IF(pixel_count = pixels_per_line - 1) THEN
        pixel_count <= 0;
      ELSE
        pixel_count <= pixel_count + 1;
      END IF;
    END IF;
  END PROCESS;

  -----------------------------------------------------
  -- Current Line Of The Current Frame
  -----------------------------------------------------
	line_count_process: PROCESS(pixel_clk, reset)
	BEGIN
		IF(reset = '1') THEN
			line_count <= 0;
		ELSIF(RISING_EDGE(pixel_clk) AND pixel_count = 0) THEN
			IF(line_count = lines_per_frame - 1) THEN
				line_count <= 0;
			ELSE
				line_count <= line_count + 1;
			END IF;
		END IF;
	END PROCESS;

END Behavioral;
