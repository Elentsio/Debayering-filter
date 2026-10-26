library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FIFO_RAM is
    generic (
        FIFO_DEPTH : integer := 8
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
end FIFO_RAM;

architecture Behavioral of FIFO_RAM is

    type ram_type is array (0 to FIFO_DEPTH - 1) of std_logic_vector(7 downto 0);
    signal ram : ram_type := (others => (others => '0'));

    signal ptr : integer range 0 to FIFO_DEPTH - 1 := 0;

begin



    data_out <= ram(ptr);

    full  <= '0';
    empty <= '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then

                ptr <= 0;
                ram <= (others => (others => '0'));

            else

                if wr_en = '1' and rd_en = '1' then

                    ram(ptr) <= data_in;

                    if ptr = FIFO_DEPTH - 1 then
                        ptr <= 0;
                    else
                        ptr <= ptr + 1;
                    end if;

                elsif wr_en = '1' then

                    ram(ptr) <= data_in;

                    if ptr = FIFO_DEPTH - 1 then
                        ptr <= 0;
                    else
                        ptr <= ptr + 1;
                    end if;

                elsif rd_en = '1' then

                    if ptr = FIFO_DEPTH - 1 then
                        ptr <= 0;
                    else
                        ptr <= ptr + 1;
                    end if;

                end if;

            end if;
        end if;
    end process;

end Behavioral;