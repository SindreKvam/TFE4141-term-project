library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;
use work.instruction_pkg.all;

entity first_one_finder_tb is 
    generic(
        C_block_size : integer := 16;
        C_block_size_log2 : integer := 4;

        --keys
        e : STD_LOGIC_VECTOR := STD_LOGIC_VECTOR(to_unsigned(5, C_block_size));
        d : STD_LOGIC_VECTOR := STD_LOGIC_VECTOR(to_unsigned(269, C_block_size))
    );
end first_one_finder_tb;

architecture sim of first_one_finder_tb is

    constant clk_hz : integer := 10e6;
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic := '0';
    signal key : std_logic_vector(C_block_size - 1 downto 0) := (others => '0');
    signal reset_n : std_logic := '1';

    --output
    signal result : std_logic_vector(C_block_size_log2 - 1 downto 0) := (others => '0');

    --handshake signals
    signal in_ready : std_logic;
    signal in_valid : std_logic;

    signal out_ready : std_logic;
    signal out_valid : std_logic;

begin
    --generate clock
    clk <= not clk after clk_period / 2;

reset_gen: process is 
begin
    reset_n <= '0'; 
    wait until rising_edge(clk);
    reset_n <= '1'; 
    wait;
end process;

--tests two different keys for their first 1-bit
--one has late first 1-bit, one has early
data_handler: process is 
begin 
    wait for 4 * clk_period;
    wait until rising_edge(clk);

    key <= e;
    in_valid <= '1';

    wait until falling_edge(clk);
    wait until rising_edge(clk);

    if in_ready = '0' then
        wait until falling_edge(in_ready);
    end if;

    in_valid <= '0';
    out_ready <= '1'; 

    wait until falling_edge(clk);
    wait until rising_edge(clk);

    if out_valid = '0' then
        wait until falling_edge(out_valid);
    end if;

    out_ready <= '0';

    wait until falling_edge(clk);
    wait until rising_edge(clk);

    key <= d;
    in_valid <= '1';

    wait until falling_edge(clk);
    wait until rising_edge(clk);

    if in_ready = '0' then
        wait until rising_edge(in_ready);
    end if;

    in_valid <= '0'; 
    out_ready <= '1'; 

    wait until falling_edge(clk);
    wait until rising_edge(clk);

    if out_valid = '0' then
        wait until rising_edge(out_valid);
    end if;

    out_ready <= '0';
end process;

DUT : entity work.first_one_finder(rtl)

generic map(
    C_block_size => C_block_size,
    C_block_size_log2 => C_block_size_log2
)

port map (
    clk => clk,
    reset_n => reset_n,
    data => key,
    first_one_index => result,
    in_ready => in_ready,
    in_valid => in_valid,
    out_ready => out_ready,
    out_valid => out_valid
);
end architecture;

