library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stp is
    generic (
        IMAGE_WIDTH : integer := 32
    );
    port (
        row           : in  integer range 0 to IMAGE_WIDTH - 1;
        col           : in  integer range 0 to IMAGE_WIDTH - 1;
        new_image     : in  std_logic;
        clk           : in  std_logic;
        rst           : in  std_logic;
        valid_in      : in  std_logic;
        pixel_in      : in  std_logic_vector(7 downto 0);

        p11, p12, p13 : out std_logic_vector(7 downto 0);
        p21, p22, p23 : out std_logic_vector(7 downto 0);
        p31, p32, p33 : out std_logic_vector(7 downto 0);

        valid_out_3x3 : out std_logic
    );
end stp;

architecture RTL of stp is

    component FIFO_RAM
        generic (
            FIFO_DEPTH : integer := 32
        );
        port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            wr_en    : in  std_logic;
            data_in  : in  std_logic_vector(7 downto 0);
            rd_en    : in  std_logic;
            full     : out std_logic;
            data_out : out std_logic_vector(7 downto 0);
            empty    : out std_logic
        );
    end component;

    signal rst1 : std_logic;

    signal line1_out : std_logic_vector(7 downto 0) ;
    signal line2_out : std_logic_vector(7 downto 0) ;

    type dff_row is array (0 to 2) of std_logic_vector(7 downto 0);

    signal top_row    : dff_row := (others => (others => '0'));
    signal middle_row : dff_row := (others => (others => '0'));
    signal bottom_row : dff_row := (others => (others => '0'));

begin

    rst1 <= rst;


    line_delay_1 : FIFO_RAM
        generic map (
            FIFO_DEPTH => IMAGE_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst1,
            wr_en    => valid_in,
            data_in  => pixel_in,
            rd_en    => valid_in,
            data_out => line1_out,
            full     => open,
            empty    => open
        );

    line_delay_2 : FIFO_RAM
        generic map (
            FIFO_DEPTH => IMAGE_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst1,
            wr_en    => valid_in,
            data_in  => line1_out,
            rd_en    => valid_in,
            data_out => line2_out,
            full     => open,
            empty    => open
        );



    process(clk, rst1)
    begin
        if rst1 = '1' then

            top_row    <= (others => (others => '0'));
            middle_row <= (others => (others => '0'));
            bottom_row <= (others => (others => '0'));

            valid_out_3x3 <= '0';

        elsif rising_edge(clk) then

            if valid_in = '1' then

                top_row(0) <= line2_out;
                top_row(1) <= top_row(0);
                top_row(2) <= top_row(1);

                middle_row(0) <= line1_out;
                middle_row(1) <= middle_row(0);
                middle_row(2) <= middle_row(1);

                bottom_row(0) <= pixel_in;
                bottom_row(1) <= bottom_row(0);
                bottom_row(2) <= bottom_row(1);

                valid_out_3x3 <= '1';

            else

                valid_out_3x3 <= '0';

            end if;

        end if;
    end process;



    p11 <= top_row(2);
    p12 <= top_row(1);
    p13 <= top_row(0);

    p21 <= middle_row(2);
    p22 <= middle_row(1);
    p23 <= middle_row(0);

    p31 <= bottom_row(2);
    p32 <= bottom_row(1);
    p33 <= bottom_row(0);

end RTL;