library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;

entity beta is
    generic(
        GC_LIMB_WIDTH : integer := C_LIMB_WIDTH
    );
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        --------------------------------------------------
        sum_in : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        n_0 : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        n_0_prime : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        --------------------------------------------------
        m : out std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        beta_carry : out std_logic_vector(GC_LIMB_WIDTH - 1 downto 0)
    );
end entity beta;


architecture rtl of beta is
    
begin
    
    p_beta: process(clk, rst_n)

        variable v_tmp_result_sum : T_CARRY_SUM_ARRAY;
        variable v_tmp_result_carry : T_CARRY_SUM_ARRAY;

    begin

        --------------------------------------------
        if rising_edge(clk) then
        --------------------------------------------

            --------------------------------------------
            if rst_n = '0' then
            --------------------------------------------

                m <= (others => '0');
                beta_carry <= (others => '0');

            --------------------------------------------
            else
            --------------------------------------------

                v_tmp_result_sum := carry_sum((others => '0'), sum_in, n_0_prime, (others => '0'));
                v_tmp_result_carry := carry_sum(sum_in, n_0, v_tmp_result_sum(1), (others => '0'));

                m <= v_tmp_result_sum(1);
                beta_carry <= v_tmp_result_carry(0);

            --------------------------------------------
            end if;
        end if;
    end process p_beta;
    
end architecture rtl;
