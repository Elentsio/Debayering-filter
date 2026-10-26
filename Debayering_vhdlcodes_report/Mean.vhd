library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.ALL;

entity mean is
  Port (
  clk: in std_logic;
  mean_en: in std_logic;
  square: in std_logic_vector(71 downto 0);
  ccase: in std_logic_vector(1 downto 0);
  red: out std_logic_vector(7 downto 0);
  green: out std_logic_vector(7 downto 0);
  blue: out std_logic_vector(7 downto 0)
  );
end mean;

architecture Behavioral of mean is
begin
    process(mean_en, square, ccase)
        variable b: std_logic_vector(9 downto 0);
        variable r: std_logic_vector(9 downto 0);
        variable g: std_logic_vector(9 downto 0);
        begin
            red   <= (others => '0');
            green <= (others => '0');
            blue  <= (others => '0');
            b := (others => '0');
            r := (others => '0');
            g := (others => '0');
            if mean_en = '1' then
                if ccase = "11" then
                    b := ("00" & square(15 downto 8)) + ("00" & square(63 downto 56));
                    r := ("00" & square(31 downto 24)) + ("00" & square(47 downto 40));
                    blue <= b(8 downto 1);
                    red <= r(8 downto 1);
                    green <= square(39 downto 32);
                elsif ccase = "00" then
                    r := ("00" & square(15 downto 8)) + ("00" & square(63 downto 56));
                    b := ("00" & square(31 downto 24)) + ("00" & square(47 downto 40));
                    blue <= b(8 downto 1);
                    red <= r(8 downto 1);
                    green <= square(39 downto 32);                    
                elsif ccase = "10" then
                    b := ("00" & square(71 downto 64)) + ("00" & square(55 downto 48)) + ("00" & square(23 downto 16)) + ("00" & square(7 downto 0));
                    g := ("00" & square(63 downto 56)) + ("00" & square(47 downto 40)) + ("00" & square(31 downto 24)) + ("00" & square(15 downto 8));
                    blue <= b(9 downto 2);
                    green <= g(9 downto 2);
                    red <= square(39 downto 32);
                else
                    r := ("00" & square(71 downto 64)) + ("00" & square(55 downto 48)) + ("00" & square(23 downto 16)) + ("00" & square(7 downto 0));
                    g := ("00" & square(63 downto 56)) + ("00" & square(47 downto 40)) + ("00" & square(31 downto 24)) + ("00" & square(15 downto 8));
                    red <= r(9 downto 2);
                    green <= g(9 downto 2);
                    blue <= square(39 downto 32);
                end if;
            end if;
        end process;
end Behavioral;