library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FSM is
    generic (
        IMAGE_WIDTH : integer := 32
    );
    Port (
        clk            : in  std_logic;
        rst_n          : in  std_logic;

        valid_in       : in  std_logic;
        new_image      : in  std_logic;

        m_tready       : in  std_logic;
        ready_out      : out std_logic;

        col_out        : out integer range 0 to IMAGE_WIDTH - 1;
        row_out        : out integer range 0 to IMAGE_WIDTH - 1;

        stp_col_out    : out integer range 0 to IMAGE_WIDTH + 1;
        stp_row_out    : out integer range 0 to IMAGE_WIDTH + 1;

        image_finished : out std_logic;
        valid_out      : out std_logic;

        mean_en        : out std_logic;
        rst_stp        : out std_logic;
        valid_in_stp   : out std_logic;
        ccase          : out std_logic_vector(1 downto 0);

        pixel_source   : out std_logic_vector(1 downto 0);
        capture_pending: out std_logic
    );
end FSM;

architecture Behavioral of FSM is

    constant PAD_WIDTH    : integer := IMAGE_WIDTH + 2;
    constant TOTAL_OUTPUT : integer := IMAGE_WIDTH * IMAGE_WIDTH;

    type state_t is (IDLE, RUN, DONE);
    signal state : state_t := IDLE;

    signal pad_row : integer range 0 to PAD_WIDTH - 1 := 0;
    signal pad_col : integer range 0 to PAD_WIDTH - 1 := 0;

    signal output_count : integer range 0 to TOTAL_OUTPUT - 1 := 0;

    signal have_pending : std_logic := '0';

    signal valid_out_reg : std_logic := '0';
    signal last_out_reg  : std_logic := '0';

    signal ccase_reg : std_logic_vector(1 downto 0) := "00";

    signal out_row_reg : integer range 0 to IMAGE_WIDTH - 1 := 0;
    signal out_col_reg : integer range 0 to IMAGE_WIDTH - 1 := 0;

    signal real_pos     : std_logic;
    signal can_advance  : std_logic;
    signal advance_feed : std_logic;
    signal will_output  : std_logic;

begin

    row_out <= out_row_reg;
    col_out <= out_col_reg;

    stp_row_out <= pad_row;
    stp_col_out <= pad_col;

    valid_out      <= valid_out_reg;
    mean_en        <= valid_out_reg;
    image_finished <= last_out_reg;

    ccase <= ccase_reg;

    rst_stp <= '1' when state = IDLE else '0';

  
    real_pos <= '1' when
        state = RUN and
        pad_row >= 1 and pad_row <= IMAGE_WIDTH and
        pad_col >= 1 and pad_col <= IMAGE_WIDTH
        else '0';

    can_advance <= '1' when
        valid_out_reg = '0' or m_tready = '1'
        else '0';

    ready_out <= '1' when
        state = IDLE
        else '1' when
            state = RUN and
            can_advance = '1' and
            real_pos = '1' and
            have_pending = '0'
        else '0';

    advance_feed <= '1' when
        state = RUN and
        can_advance = '1' and
        (
            real_pos = '0' or
            have_pending = '1' or
            valid_in = '1'
        )
        else '0';

    valid_in_stp <= advance_feed;


    will_output <= '1' when
        advance_feed = '1' and
        pad_row >= 2 and
        pad_col >= 2
        else '0';

    capture_pending <= '1' when
        state = IDLE and valid_in = '1'
        else '0';

    process(state, real_pos, have_pending, valid_in)
    begin
        pixel_source <= "00";

        if state = RUN then
            if real_pos = '1' then
                if have_pending = '1' then
                    pixel_source <= "01"; -- pending first real pixel
                elsif valid_in = '1' then
                    pixel_source <= "10"; -- current AXI pixel
                else
                    pixel_source <= "00";
                end if;
            else
                pixel_source <= "00"; -- padding zero
            end if;
        end if;
    end process;

    process(clk, rst_n)
        variable real_r : integer;
        variable real_c : integer;
    begin
        if rst_n = '0' then

            state <= IDLE;

            pad_row <= 0;
            pad_col <= 0;

            output_count <= 0;
            have_pending <= '0';

            valid_out_reg <= '0';
            last_out_reg  <= '0';

            ccase_reg <= "00";

            out_row_reg <= 0;
            out_col_reg <= 0;

        elsif rising_edge(clk) then

            case state is

                when IDLE =>

                    valid_out_reg <= '0';
                    last_out_reg  <= '0';

                    pad_row <= 0;
                    pad_col <= 0;

                    output_count <= 0;

                    out_row_reg <= 0;
                    out_col_reg <= 0;

                    ccase_reg <= "00";

                    if valid_in = '1' then
                        have_pending <= '1';
                        state <= RUN;
                    end if;

                when RUN =>

                    if can_advance = '1' then
                        valid_out_reg <= '0';
                        last_out_reg  <= '0';
                    end if;

                    if advance_feed = '1' then

                        if real_pos = '1' and have_pending = '1' then
                            have_pending <= '0';
                        end if;

                        if will_output = '1' then

                            real_r := pad_row - 2;
                            real_c := pad_col - 2;

                            out_row_reg <= real_r;
                            out_col_reg <= real_c;

                            if (real_r mod 2) = 0 then
                                ccase_reg(1) <= '0';
                            else
                                ccase_reg(1) <= '1';
                            end if;

                            if (real_c mod 2) = 0 then
                                ccase_reg(0) <= '0';
                            else
                                ccase_reg(0) <= '1';
                            end if;

                            valid_out_reg <= '1';

                            if output_count = TOTAL_OUTPUT - 1 then
                                last_out_reg <= '1';
                                state <= DONE;
                            else
                                last_out_reg <= '0';
                                output_count <= output_count + 1;
                            end if;

                        end if;

                        if pad_col = PAD_WIDTH - 1 then
                            pad_col <= 0;

                            if pad_row < PAD_WIDTH - 1 then
                                pad_row <= pad_row + 1;
                            end if;
                        else
                            pad_col <= pad_col + 1;
                        end if;

                    end if;

                when DONE =>

                    if valid_out_reg = '1' and m_tready = '1' then
                        valid_out_reg <= '0';
                        last_out_reg  <= '0';
                        have_pending  <= '0';
                        state <= IDLE;
                    end if;

            end case;

        end if;
    end process;

end Behavioral;