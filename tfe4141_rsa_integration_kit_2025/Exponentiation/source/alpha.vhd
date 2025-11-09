library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;

entity alpha is
    generic(
        GC_LIMB_WIDTH : integer := C_LIMB_WIDTH
    );
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        --------------------------------------------------
        a : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        b : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        carry_in : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        sum_in : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        --------------------------------------------------
        alpha_carry : out std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        alpha_sum : out std_logic_vector(GC_LIMB_WIDTH - 1 downto 0)
    );
end entity alpha;


architecture rtl of alpha is
    
begin
    
    p_alpha: process(clk, rst_n)

        variable v_tmp_result : T_CARRY_SUM_ARRAY;

    begin

        if rising_edge(clk) then

            --------------------------------------------
            if rst_n = '0' then
            --------------------------------------------

                alpha_carry <= (others => '0');
                alpha_sum <= (others => '0');

            --------------------------------------------
            else
            --------------------------------------------

                v_tmp_result := carry_sum(carry_in, a, b, sum_in);

                alpha_carry <= v_tmp_result(0);
                alpha_sum <= v_tmp_result(1);

            end if;
        end if;

    end process p_alpha;
    
end architecture rtl;
