library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;
use work.instruction_pkg.all;


entity montgomery_monpro_cios_systolic_array_tb is
end entity montgomery_monpro_cios_systolic_array_tb;

architecture tb of montgomery_monpro_cios_systolic_array_tb is
    
    constant C_CLOCK_FREQUENCY : integer := 100e6;
    constant C_CLOCK_PERIOD : time := 1 sec / C_CLOCK_FREQUENCY;
    
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';

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
            u => u,
        );

        clk <= not clk after C_CLOCK_PERIOD / 2;
    
end architecture tb;
