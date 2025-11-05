library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.env.all;

use work.montgomery_pkg.all;
use work.instruction_pkg.all;


entity montgomery_monpro_cios_systolic_array_tb is
end entity montgomery_monpro_cios_systolic_array_tb;

architecture tb of montgomery_monpro_cios_systolic_array_tb is
    
    constant C_CLOCK_FREQUENCY : integer := 100e6;
    constant C_CLOCK_PERIOD : time := 1 sec / C_CLOCK_FREQUENCY;
    
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';

    signal in_valid : std_logic := '0';
    signal in_ready : std_logic;

    signal out_valid : std_logic;
    signal out_ready : std_logic := '0';

    signal a, b, n : std_logic_vector(C_DATA_WIDTH - 1 downto 0);
    signal n_prime : std_logic_vector(C_LIMB_WIDTH - 1 downto 0);

    signal u : std_logic_vector(C_DATA_WIDTH - 1 downto 0);

begin
    
    DUT: entity work.montgomery_monpro_cios_systolic_array
        port map(
            clk => clk,
            rst_n => rst_n,
            in_valid => in_valid,
            in_ready => in_ready,
            out_valid => out_valid,
            out_ready => out_ready,
            a => a,
            b => b,
            n => n,
            n_prime => n_prime,
            u => u
        );

    clk <= not clk after C_CLOCK_PERIOD / 2;


    p_stimuli: process
    begin

        wait for C_CLOCK_PERIOD / 2;
        rst_n <= '1' after 3 * C_CLOCK_PERIOD;

        wait for 3 * C_CLOCK_PERIOD;

        n <= x"99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d" after 3 * C_CLOCK_PERIOD;
        n_prime <= x"8833c3bb" after 3 * C_CLOCK_PERIOD;

        a <= x"0000000011111111222222223333333344444444555555556666666677777777" after 3 * C_CLOCK_PERIOD;
        b <= x"56ddf8b43061ad3dbcd1757244d1a19e2e8c849dde4817e55bb29d1c20c06364" after 3 * C_CLOCK_PERIOD;

        in_valid <= '1' after 4 * C_CLOCK_PERIOD;
        out_ready <= '1' after 4 * C_CLOCK_PERIOD;

        wait for 4 * C_CLOCK_PERIOD;
        

        wait for 33 * C_CLOCK_PERIOD;

        assert u = x"8abe76b2cf6e603497a8ba867eddc580b943f5690777e388fae627e05449851a" report
        "Incorrect result" severity error;

        report "Testbench finished";
        finish;


    end process p_stimuli;
    
end architecture tb;
