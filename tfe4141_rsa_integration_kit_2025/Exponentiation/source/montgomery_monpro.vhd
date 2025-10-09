
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity montgomery_monpro is
    generic(
        GC_DATA_WIDTH : integer := 16
    );
    port (
        clk : in std_logic;
        rst_n : in std_logic;
    --------------------------------------------------
    -- Values to be multiplicated
    --------------------------------------------------
        a : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
        b : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    --------------------------------------------------
        n : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
        n_prime : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    --------------------------------------------------
    -- Outputs
    --------------------------------------------------
        u : out std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := (others => '0')
   );
end entity montgomery_monpro;


architecture rtl of montgomery_monpro is

    constant r_minus_1 : unsigned(GC_DATA_WIDTH - 1 downto 0) := (others => '1');
    
    signal t : unsigned(GC_DATA_WIDTH * 2 - 1 downto 0);
    signal m : unsigned(GC_DATA_WIDTH - 1 downto 0);
    signal u_pre : unsigned(GC_DATA_WIDTH * 2 - 1 downto 0);
    signal u_shift : unsigned(GC_DATA_WIDTH - 1 downto 0);

begin

    monpro_proc: process(clk)
        variable v_m : unsigned(GC_DATA_WIDTH * 3 - 1 downto 0) := (others => '0');
    begin

        if rising_edge(clk) then
            if rst_n = '0' then
                u <= (others => '0');

            else

                t <= unsigned(a) * unsigned(b);
                v_m := (t * unsigned(n_prime));
                m <= v_m(GC_DATA_WIDTH - 1 downto 0) and r_minus_1;
                u_pre <= (t + m * unsigned(n));
                u_shift <= u_pre(u_pre'left downto GC_DATA_WIDTH);

                if u_shift >= unsigned(n) then
                    u <= std_logic_vector(u_shift - unsigned(n));
                else
                    u <= std_logic_vector(u_shift);
                end if;

            end if;
        end if;

        
    end process monpro_proc;
    
end architecture rtl;
