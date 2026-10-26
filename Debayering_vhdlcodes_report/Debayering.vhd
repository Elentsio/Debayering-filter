library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debayer_top is
    generic (
        IMAGE_WIDTH  : integer := 32
    );
    Port (
        col_out        : out integer range 0 to IMAGE_WIDTH - 1;
        row_out        : out integer range 0 to IMAGE_WIDTH - 1;

        clk            : in  std_logic;
        rst_n          : in  std_logic;

        valid_in       : in  std_logic;
        s_axis_tready  : out std_logic;

        new_image      : in  std_logic;
        pixel_in       : in  std_logic_vector(7 downto 0);

        m_tready       : in  std_logic;

        valid_out      : out std_logic;
        image_finished : out std_logic;

        R              : out std_logic_vector(7 downto 0);
        G              : out std_logic_vector(7 downto 0);
        B              : out std_logic_vector(7 downto 0)
    );
end debayer_top;

architecture Structural of debayer_top is

    constant PAD_WIDTH : integer := IMAGE_WIDTH + 2;

    component FSM
        generic (
            IMAGE_WIDTH : integer
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
    end component;

    component stp
        generic (
            IMAGE_WIDTH : integer
        );
        port (
            row           : in integer range 0 to IMAGE_WIDTH - 1;
            col           : in integer range 0 to IMAGE_WIDTH - 1;
            new_image     : in std_logic;
            clk           : in  std_logic;
            rst           : in  std_logic;
            valid_in      : in  std_logic;
            pixel_in      : in  std_logic_vector(7 downto 0);

            p11, p12, p13 : out std_logic_vector(7 downto 0);
            p21, p22, p23 : out std_logic_vector(7 downto 0);
            p31, p32, p33 : out std_logic_vector(7 downto 0);

            valid_out_3x3 : out std_logic
        );
    end component;

    component mean
        Port (
            clk     : in  std_logic;
            mean_en : in  std_logic;
            square  : in  std_logic_vector(71 downto 0);
            ccase   : in  std_logic_vector(1 downto 0);
            red     : out std_logic_vector(7 downto 0);
            green   : out std_logic_vector(7 downto 0);
            blue    : out std_logic_vector(7 downto 0)
        );
    end component;

    signal mean_en_sig      : std_logic;
    signal valid_in_stp_sig : std_logic;
    signal ccase_sig        : std_logic_vector(1 downto 0);
    signal rst_stp_sig      : std_logic;
    signal stp_rst_sig      : std_logic;

    signal p11_sig, p12_sig, p13_sig : std_logic_vector(7 downto 0);
    signal p21_sig, p22_sig, p23_sig : std_logic_vector(7 downto 0);
    signal p31_sig, p32_sig, p33_sig : std_logic_vector(7 downto 0);

    signal square_bus : std_logic_vector(71 downto 0);

    signal col_wire : integer range 0 to IMAGE_WIDTH - 1;
    signal row_wire : integer range 0 to IMAGE_WIDTH - 1;

    signal stp_col_wire : integer range 0 to PAD_WIDTH - 1;
    signal stp_row_wire : integer range 0 to PAD_WIDTH - 1;

    signal s_axis_tready_int : std_logic;

    signal pixel_source_sig    : std_logic_vector(1 downto 0);
    signal capture_pending_sig : std_logic;

    signal pending_pixel : std_logic_vector(7 downto 0) := (others => '0');
    signal stp_pixel_in  : std_logic_vector(7 downto 0);

begin

    col_out <= col_wire;
    row_out <= row_wire;

    s_axis_tready <= s_axis_tready_int;

    stp_rst_sig <= (not rst_n) or rst_stp_sig;

    square_bus <= p31_sig & p32_sig & p33_sig &
                  p21_sig & p22_sig & p23_sig &
                  p11_sig & p12_sig & p13_sig;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            pending_pixel <= (others => '0');
        elsif rising_edge(clk) then
            if capture_pending_sig = '1' then
                pending_pixel <= pixel_in;
            end if;
        end if;
    end process;

    with pixel_source_sig select
        stp_pixel_in <= x"00"         when "00",
                        pending_pixel when "01",
                        pixel_in      when "10",
                        x"00"         when others;

    Control_Unit : FSM
        generic map (
            IMAGE_WIDTH => IMAGE_WIDTH
        )
        port map (
            clk             => clk,
            rst_n           => rst_n,

            valid_in        => valid_in,
            new_image       => new_image,

            m_tready        => m_tready,
            ready_out       => s_axis_tready_int,

            col_out         => col_wire,
            row_out         => row_wire,

            stp_col_out     => stp_col_wire,
            stp_row_out     => stp_row_wire,

            image_finished  => image_finished,
            valid_out       => valid_out,

            mean_en         => mean_en_sig,
            rst_stp         => rst_stp_sig,
            valid_in_stp    => valid_in_stp_sig,
            ccase           => ccase_sig,

            pixel_source    => pixel_source_sig,
            capture_pending => capture_pending_sig
        );

    Sliding_Window : stp
        generic map (
            IMAGE_WIDTH => PAD_WIDTH
        )
        port map (
            row           => stp_row_wire,
            col           => stp_col_wire,

            new_image     => new_image,
            clk           => clk,
            rst           => stp_rst_sig,
            valid_in      => valid_in_stp_sig,
            pixel_in      => stp_pixel_in,

            p11           => p11_sig,
            p12           => p12_sig,
            p13           => p13_sig,

            p21           => p21_sig,
            p22           => p22_sig,
            p23           => p23_sig,

            p31           => p31_sig,
            p32           => p32_sig,
            p33           => p33_sig,

            valid_out_3x3 => open
        );

    Math_Debayer : mean
        port map (
            clk     => clk,
            mean_en => mean_en_sig,
            square  => square_bus,
            ccase   => ccase_sig,
            red     => R,
            green   => G,
            blue    => B
        );

end Structural;