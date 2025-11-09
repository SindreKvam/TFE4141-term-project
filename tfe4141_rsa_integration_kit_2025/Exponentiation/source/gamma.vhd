library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;

entity gamma is
    generic(
        GC_LIMB_WIDTH : integer := C_LIMB_WIDTH
    );
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        --------------------------------------------------
        n_i : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        m : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        carry_in : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        sum_in : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        --------------------------------------------------
        gamma_carry : out std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        gamma_sum : out std_logic_vector(GC_LIMB_WIDTH - 1 downto 0)
    );
end entity gamma;


architecture rtl of gamma is
    
begin
    
    p_gamma: process(clk, rst_n)

        variable v_tmp_result : T_CARRY_SUM_ARRAY;

    begin

        if rising_edge(clk) then

            --------------------------------------------
            if rst_n = '0' then
            --------------------------------------------

                gamma_carry <= (others => '0');
                gamma_sum <= (others => '0');

            --------------------------------------------
            else
            --------------------------------------------

                v_tmp_result := carry_sum(sum_in, n_i, m, carry_in);

                gamma_carry <= v_tmp_result(0);
                gamma_sum <= v_tmp_result(1);

            --------------------------------------------
            end if;
        end if;

    end process p_gamma;
    
end architecture rtl;
