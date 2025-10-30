library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;

entity gamma_final is
    generic(
        GC_LIMB_WIDTH : integer := 16
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
    
    p_gamma_final: process(clk)

        variable v_tmp_result : unsigned(GC_LIMB_WIDTH - 1 downto 0) := (others => '0');

    begin

        v_tmp_result := (others => '0');

        --------------------------------------------
        if rst_n = '0' then
        --------------------------------------------

            gamma_sum_1 <= (others => '0');
            gamma_sum_2 <= (others => '0');

        --------------------------------------------
        elsif rising_edge(clk) then
        --------------------------------------------

            v_tmp_result := unsigned(sum_1_in) + unsigned(carry_in);
            
            gamma_sum_1 <= std_logic_vector(v_tmp_result(GC_LIMB_WIDTH - 1 downto 0));
            gamma_sum_2 <= std_logic_vector(v_tmp_result(GC_LIMB_WIDTH * 2 - 1 downto GC_LIMB_WIDTH) + unsigned(sum_2_in));

        --------------------------------------------
        end if;
    end process p_gamma_final;
    
end architecture rtl;
