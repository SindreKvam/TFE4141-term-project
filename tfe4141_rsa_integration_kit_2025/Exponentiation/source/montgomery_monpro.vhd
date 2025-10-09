
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity montgomery_monpro is
    generic(
        GC_DATA_WIDTH : positive := 32
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
        k : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0); -- number of bits to shift down (log2 of k)
        r : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    --------------------------------------------------
    -- Outputs
    --------------------------------------------------
        u : out std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := (others => '0')
   );
end entity montgomery_monpro;


architecture rtl of montgomery_monpro is
    
    signal t : unsigned(GC_DATA_WIDTH * 2 - 1 downto 0);
    signal m : unsigned(GC_DATA_WIDTH - 1 downto 0);
    signal u_pre : unsigned(GC_DATA_WIDTH * 2 - 1 downto 0);
    signal u_shift : unsigned(GC_DATA_WIDTH - 1 downto 0);

begin

    monpro_proc: process(clk)
    begin

        if rising_edge(clk) then
            if rst_n = '0' then
                u <= (others => '0');

            else

                t <= unsigned(a) * unsigned(b);
                m <= (t * unsigned(n_prime)) mod unsigned(r);
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
