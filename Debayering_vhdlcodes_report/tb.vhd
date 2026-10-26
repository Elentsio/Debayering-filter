library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.ALL;

use STD.textio.all;                  
use IEEE.std_logic_textio.all;      

entity tb_debayer_top is
end tb_debayer_top;

architecture Behavioral of tb_debayer_top is

    component debayer_top
        generic (
            IMAGE_WIDTH  : integer:= 32        
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
    end component;

    signal clk            : std_logic := '0';
    signal rst_n          : std_logic := '0';
    signal valid_in       : std_logic := '0';
    signal s_axis_tready  : std_logic;
    signal new_image      : std_logic := '0';
    signal pixel_in       : std_logic_vector(7 downto 0) := (others => '0');
    signal m_tready       : std_logic := '1'; -- Testbench is always ready to receive data
    signal valid_out      : std_logic;
    signal image_finished : std_logic;
    signal R, G, B        : std_logic_vector(7 downto 0);
    signal col_out        : integer;
    signal row_out        : integer;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- Device Under Test (DUT) Instantiation
    UUT: debayer_top
        generic map (
            IMAGE_WIDTH  => 32
        )
        port map (
            col_out        => col_out,
            row_out        => row_out,
            clk            => clk,
            rst_n          => rst_n,
            valid_in       => valid_in,
            s_axis_tready  => s_axis_tready,
            new_image      => new_image,
            pixel_in       => pixel_in,
            m_tready       => m_tready,
            valid_out      => valid_out,
            image_finished => image_finished,
            R              => R,
            G              => G,
            B              => B
        );

    -- Clock Generation
    clk <= not clk after CLK_PERIOD / 2;

    -- Stimulus Process (Reading from input.txt)
    process
        file file_in      : text open read_mode is "input.txt";
        variable v_iline  : line;
        variable v_pixel  : integer;
        variable is_first : boolean := true;
    begin
        -- Initial Reset State
        rst_n <= '0';
        valid_in <= '0';
        new_image <= '0';
        wait for 25 ns;
        
        -- Come out of reset
        rst_n <= '1';
        wait for CLK_PERIOD * 2;

        -- Read file line by line
        while not endfile(file_in) loop
            readline(file_in, v_iline);
            read(v_iline, v_pixel);

            -- Apply the new pixel
            valid_in <= '1';
            pixel_in <= std_logic_vector(to_unsigned(v_pixel, 8));
            
            -- Manage the new_image flag
            if is_first then
                new_image <= '1';
                is_first := false;
            else
                new_image <= '0';
            end if;
            
            -- THE FIX: AXI Stream Master Handshake
            -- Wait here holding valid_in=1 and pixel_in steady until the DUT 
            -- asserts s_axis_tready, meaning it has successfully consumed the data.
            loop
                wait until rising_edge(clk);
                exit when s_axis_tready = '1';
            end loop;
            
        end loop;
        
        -- Finish simulation stimulus
        new_image <= '1';
        wait for CLK_PERIOD;
        valid_in <= '0';
        new_image <= '0';
        pixel_in <= (others => '0');
        
        wait for CLK_PERIOD * 40; 
        wait;
    end process;

    -- Output Logging Process (Writing to vivado_rgb.txt)
    process(clk)
        file file_out     : text open write_mode is "vivado_rgb.txt";
        variable v_oline  : line;
    begin
        if rising_edge(clk) then
            if valid_out = '1' then
                write(v_oline, to_integer(unsigned(R)));
                write(v_oline, string'(" "));
                write(v_oline, to_integer(unsigned(G)));
                write(v_oline, string'(" "));
                write(v_oline, to_integer(unsigned(B)));
                
                writeline(file_out, v_oline);
            end if;
        end if;
    end process;

end Behavioral;