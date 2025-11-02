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

        variable v_tmp_result : unsigned(GC_LIMB_WIDTH * 2 - 1 downto 0) := (others => '0');

    begin

        v_tmp_result := (others => '0');

        --------------------------------------------
        if rst_n = '0' then
        --------------------------------------------

            gamma_carry <= (others => '0');
            gamma_sum <= (others => '0');

        --------------------------------------------
        elsif rising_edge(clk) then
        --------------------------------------------

            v_tmp_result := unsigned(sum_in) + unsigned(n_i) * unsigned(m) + unsigned(carry_in);
            
            gamma_carry <= std_logic_vector(v_tmp_result(GC_LIMB_WIDTH * 2 - 1 downto GC_LIMB_WIDTH));
            gamma_sum <= std_logic_vector(v_tmp_result(GC_LIMB_WIDTH - 1 downto 0));

        --------------------------------------------
        end if;
    end process p_gamma;
    
end architecture rtl;
