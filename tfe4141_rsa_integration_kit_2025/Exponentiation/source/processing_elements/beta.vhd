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

        variable v_tmp_result : unsigned(GC_LIMB_WIDTH * 2 - 1 downto 0) := (others => '0');
        variable v_m : unsigned(GC_LIMB_WIDTH * 2 - 1 downto 0) := (others => '0');

    begin

        v_tmp_result := (others => '0');
        v_m := (others => '0');

        --------------------------------------------
        if rst_n = '0' then
        --------------------------------------------

            m <= (others => '0');
            beta_carry <= (others => '0');

        --------------------------------------------
        elsif rising_edge(clk) then
        --------------------------------------------

            v_m := unsigned(sum_in) * unsigned(n_0_prime);
            v_tmp_result := unsigned(sum_in) + unsigned(n_0) * unsigned(v_m(GC_LIMB_WIDTH - 1 downto 0));
            
            m <= std_logic_vector(v_m(GC_LIMB_WIDTH - 1 downto 0));
            beta_carry <= std_logic_vector(v_tmp_result(GC_LIMB_WIDTH * 2 - 1 downto GC_LIMB_WIDTH));

        --------------------------------------------
        end if;
    end process p_beta;
    
end architecture rtl;
