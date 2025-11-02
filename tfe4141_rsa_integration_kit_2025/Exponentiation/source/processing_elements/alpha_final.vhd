library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;

entity alpha_final is
    generic(
        GC_LIMB_WIDTH : integer := C_LIMB_WIDTH
    );
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        --------------------------------------------------
        carry_in : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        sum_in : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        --------------------------------------------------
        alpha_carry : out std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        alpha_sum : out std_logic_vector(GC_LIMB_WIDTH - 1 downto 0)
    );
end entity alpha_final;


architecture rtl of alpha_final is
    
begin
    
    p_alpha_final: process(clk, rst_n)

        variable v_tmp_result : unsigned(GC_LIMB_WIDTH * 2 - 1 downto 0) := (others => '0');

    begin

        v_tmp_result := (others => '0');

        --------------------------------------------
        if rst_n = '0' then
        --------------------------------------------

            alpha_carry <= (others => '0');
            alpha_sum <= (others => '0');

        --------------------------------------------
        elsif rising_edge(clk) then
        --------------------------------------------

            v_tmp_result := resize(unsigned(carry_in) + unsigned(sum_in), v_tmp_result'length);
            
            alpha_carry <= std_logic_vector(v_tmp_result(GC_LIMB_WIDTH * 2 - 1 downto GC_LIMB_WIDTH));
            alpha_sum <= std_logic_vector(v_tmp_result(GC_LIMB_WIDTH - 1 downto 0));

        --------------------------------------------
        end if;
    end process p_alpha_final;
    
end architecture rtl;
