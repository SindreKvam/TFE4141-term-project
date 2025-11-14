library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;

entity gamma_final is
    generic(
        GC_LIMB_WIDTH : integer := C_LIMB_WIDTH
    );
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        --------------------------------------------------
        carry_in : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        sum_1_in : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        sum_2_in : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        --------------------------------------------------
        gamma_sum_1 : out std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        gamma_sum_2 : out std_logic_vector(GC_LIMB_WIDTH - 1 downto 0)
    );
end entity gamma_final;


architecture rtl of gamma_final is
    
begin
    
    p_gamma_final: process(clk, rst_n)

        variable v_tmp_result : T_CARRY_SUM_ARRAY;

    begin

        v_tmp_result := (others => (others => '0'));

        --------------------------------------------------
        if rising_edge(clk) then
        --------------------------------------------------

            --------------------------------------------------
            if rst_n = '0' then
            --------------------------------------------------

                gamma_sum_1 <= (others => '0');
                gamma_sum_2 <= (others => '0');

            --------------------------------------------------
            else
            --------------------------------------------------

                v_tmp_result := carry_sum(sum_1_in, (others => '0'), (others => '0'), carry_in);
                
                gamma_sum_1 <= v_tmp_result(1);
                gamma_sum_2 <= std_logic_vector(unsigned(v_tmp_result(0)) + unsigned(sum_2_in));

            --------------------------------------------
            end if;
        end if;
    end process p_gamma_final;
    
end architecture rtl;
