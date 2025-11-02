library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;

entity alpha_tb is
end entity alpha_tb;

architecture tb of alpha_tb is
    
    constant C_CLOCK_FREQUENCY : integer := 100e6;
    constant C_CLOCK_PERIOD : time := 1 sec / C_CLOCK_FREQUENCY;

    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';

    signal a : std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal b : std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal carry_in : std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal sum_in : std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
    
    signal carry_out : std_logic_vector(C_LIMB_WIDTH - 1 downto 0);
    signal sum_out : std_logic_vector(C_LIMB_WIDTH - 1 downto 0);
    
begin
    
    DUT: entity work.alpha
        port map(
            clk => clk,
            rst_n => rst_n,
            a => a,
            b => b,
            carry_in => carry_in,
            sum_in => sum_in,
            alpha_carry => carry_out,
            alpha_sum => sum_out
        );


        clk <= not clk after C_CLOCK_PERIOD / 2;

        p_stimuli: process
        begin

            wait for C_CLOCK_PERIOD / 2;

            rst_n <= '1';

            -- First iteration
            a <= x"77777777" after 1 * C_CLOCK_PERIOD;
            b <= x"20c06364" after 1 * C_CLOCK_PERIOD;
            carry_in <= (others => '0') after 1 * C_CLOCK_PERIOD;
            sum_in <= (others => '0') after 1 * C_CLOCK_PERIOD;
            wait for C_CLOCK_PERIOD;

            assert sum_out /= x"571daf80" report "Incorrect sum" severity WARNING;
            assert carry_out /= x"0f48b6ea" report "Incorrect carry" severity WARNING;

            -- Second iteration
            a <= x"66666666" after C_CLOCK_PERIOD;
            carry_in <= x"0f48b6ea" after C_CLOCK_PERIOD;
            wait for C_CLOCK_PERIOD;

            assert sum_out /= x"35622900" report "Incorrect sum" severity WARNING;
            assert carry_out /= x"0d19c15b" report "Incorrect carry" severity WARNING;

            -- Third iteration
            a <= x"55555555" after C_CLOCK_PERIOD;
            carry_in <= x"0d19c15b" after C_CLOCK_PERIOD;
            wait for C_CLOCK_PERIOD;

            assert sum_out /= x"022ef580" report "Incorrect sum" severity WARNING;
            assert carry_out /= x"0aeacbcc" report "Incorrect carry" severity WARNING;

            report "Testbench finished";
            wait;
            
        end process p_stimuli;
    
end architecture tb;
