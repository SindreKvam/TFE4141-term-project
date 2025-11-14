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

        variable v_tmp_result_mult : unsigned(2 * GC_LIMB_WIDTH - 1 downto 0);
        variable v_m : unsigned(GC_LIMB_WIDTH - 1 downto 0);

        variable v_tmp_result_mult2 : unsigned(2 * GC_LIMB_WIDTH - 1 downto 0);
        variable v_tmp_result_carry : unsigned(2 * GC_LIMB_WIDTH - 1 downto 0);

    begin

        --------------------------------------------------
        if rising_edge(clk) then
        --------------------------------------------------

            --------------------------------------------------
            if rst_n = '0' then
            --------------------------------------------------

                m <= (others => '0');
                beta_carry <= (others => '0');

            --------------------------------------------------
            else
            --------------------------------------------------

                v_tmp_result_mult := unsigned(sum_in) * unsigned(n_0_prime);
                v_m := v_tmp_result_mult(GC_LIMB_WIDTH - 1 downto 0);

                v_tmp_result_mult2 := unsigned(n_0) * v_m;
                v_tmp_result_carry := resize(unsigned(sum_in), 2 * GC_LIMB_WIDTH) + v_tmp_result_mult2;

                beta_carry <= std_logic_vector(v_tmp_result_carry(2*GC_LIMB_WIDTH - 1 downto GC_LIMB_WIDTH));
                m <= std_logic_vector(v_m);

            --------------------------------------------
            end if;
        end if;
    end process p_beta;
    
end architecture rtl;
