
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity montgomery_monpro_tb is
end entity montgomery_monpro_tb;


architecture tb of montgomery_monpro_tb is

    constant C_DATA_WIDTH : integer := 16;
    constant C_CLOCK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';

    signal in_valid : std_logic := '0';
    signal in_ready : std_logic := '0';
    signal out_valid : std_logic := '0';
    signal out_ready : std_logic := '0';

    signal a : std_logic_vector(C_DATA_WIDTH - 1 downto 0);
    signal b : std_logic_vector(C_DATA_WIDTH - 1 downto 0);

    signal n : std_logic_vector(C_DATA_WIDTH - 1 downto 0);
    signal n_prime : std_logic_vector(C_DATA_WIDTH - 1 downto 0);

    signal u : std_logic_vector(C_DATA_WIDTH - 1 downto 0);
    
begin
    
    DUT : entity work.montgomery_monpro
        port map(
            clk => clk,
            rst_n => rst_n,
            --------------------------------------------------
            in_valid => in_valid,
            in_ready => in_ready,
            out_valid => out_valid,
            out_ready => out_ready,
            --------------------------------------------------
            a => a,
            b => b,
            --------------------------------------------------
            n => n,
            n_prime => n_prime,
            --------------------------------------------------
            u => u
        );

    clk <= not clk after C_CLOCK_PERIOD / 2;

    SEQUENCER_PROC: process
    begin


        rst_n <= '1' after C_CLOCK_PERIOD;

        n <= std_logic_vector(to_unsigned(143, C_DATA_WIDTH)) after 3 * C_CLOCK_PERIOD;
        n_prime <= std_logic_vector(to_unsigned(57745, C_DATA_WIDTH)) after 3 * C_CLOCK_PERIOD;

        a <= std_logic_vector(to_unsigned(130, C_DATA_WIDTH)) after 3 * C_CLOCK_PERIOD;
        b <= std_logic_vector(to_unsigned(48, C_DATA_WIDTH)) after 3 * C_CLOCK_PERIOD;

        in_valid <= '1' after 4 * C_CLOCK_PERIOD;
        in_valid <= '0' after 5 * C_CLOCK_PERIOD;

        out_ready <= '1' after 10 * C_CLOCK_PERIOD;
        
        wait for 10 * C_CLOCK_PERIOD;
        assert u /= std_logic_vector(to_unsigned(26, C_DATA_WIDTH)) report "Incorrect result" severity note;

        a <= std_logic_vector(to_unsigned(136, C_DATA_WIDTH)) after 3 * C_CLOCK_PERIOD;
        b <= std_logic_vector(to_unsigned(69, C_DATA_WIDTH)) after 3 * C_CLOCK_PERIOD;

        in_valid <= '1' after 4 * C_CLOCK_PERIOD;
        in_valid <= '0' after 5 * C_CLOCK_PERIOD;

        out_ready <= '1' after 10 * C_CLOCK_PERIOD;

        report "Testbench finished";

    end process SEQUENCER_PROC;


end architecture tb;
