library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;

entity beta_tb is
end entity beta_tb;

architecture tb of beta_tb is
    
    constant C_CLOCK_FREQUENCY : integer := 100e6;
    constant C_CLOCK_PERIOD : time := 1 sec / C_CLOCK_FREQUENCY;

    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';

    signal sum_in : std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal n_0 : std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal n_0_prime : std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal m : std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal beta_carry : std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
    
begin
    
    DUT: entity work.beta
        port map(
            clk => clk,
            rst_n => rst_n,
            sum_in => sum_in,
            n_0 => n_0,
            n_0_prime => n_0_prime,
            m => m,
            beta_carry => beta_carry
        );


        clk <= not clk after C_CLOCK_PERIOD / 2;

        p_stimuli: process
        begin

            wait for C_CLOCK_PERIOD / 2;

            rst_n <= '1';

            -- First iteration
            sum_in <= x"77777777" after 1 * C_CLOCK_PERIOD;
            n_0 <= x"F8FF768D" after 1 * C_CLOCK_PERIOD;
            n_0_prime <= x"8833C3BB" after 1 * C_CLOCK_PERIOD;
            wait for C_CLOCK_PERIOD;

            assert m /= x"48f8e8ed" report "Incorrect sum" severity WARNING;
            assert beta_carry /= x"46f9f361" report "Incorrect carry" severity WARNING;

            -- Second iteration
            sum_in <= x"88888888" after C_CLOCK_PERIOD;
            wait for C_CLOCK_PERIOD;

            assert m /= x"2ed35358" report "Incorrect sum" severity WARNING;
            assert beta_carry /= x"2d8b72ed" report "Incorrect carry" severity WARNING;

            -- Third iteration
            sum_in <= x"55555555" after C_CLOCK_PERIOD;
            wait for C_CLOCK_PERIOD;

            assert m /= x"7d441417" report "Incorrect sum" severity WARNING;
            assert beta_carry /= x"79d6f449" report "Incorrect carry" severity WARNING;

            report "Testbench finished";
            wait;
            
        end process p_stimuli;
    
end architecture tb;
