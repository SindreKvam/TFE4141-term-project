library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library std;
use std.textio.all;

use std.textio.all;
use std.env.finish;

entity montgomery_modexp_tb is
    generic(
        C_block_size : integer := 16;

        -- key values
        e : std_logic_vector := std_logic_vector(to_unsigned(5, C_block_size));
        d : std_logic_vector := std_logic_vector(to_unsigned(269, C_block_size));

        -- modulus values
        n : std_logic_vector := std_logic_vector(to_unsigned(377, C_block_size));
        n_prime: std_logic_vector := std_logic_vector(to_unsigned(91959, C_block_size));
        r_stuff: std_logic_vector := std_logic_vector(to_unsigned(74, C_block_size))
    );
end montgomery_modexp_tb;

architecture sim of montgomery_modexp_tb is

    constant clk_hz : integer := 10e6;
    constant clk_period : time := 1 sec / clk_hz;

    --input control
    signal valid_in : std_logic := '0';
    signal ready_in : std_logic := '0';

    --input data
    signal message : std_logic_vector(C_block_size - 1 downto 0) := (others => '0');
    signal key : std_logic_vector(C_block_size - 1 downto 0) := (others => '0');
    
    --output control
    signal ready_out : std_logic := '1';
    signal valid_out : std_logic := '0';

    --output data
    signal result : std_logic_vector(C_block_size - 1 downto 0) := (others => '0');
    
    --utility
    signal clk : std_logic := '0';
    signal reset_n : std_logic := '0';

    --signals for push/pull logic of tb
    signal ready_for_push : std_logic := '1';

    --utility function for writing std_logic_vectors to terminal

	function stdvec_to_string ( a: std_logic_vector) return string is
		variable b : string (a'length/4 downto 1) := (others => NUL);
		variable nibble : std_logic_vector(3 downto 0);
	begin
		for i in b'length downto 1 loop
			nibble := a(i*4-1 downto (i-1)*4);
			case nibble is
				when "0000" => b(i) := '0';
				when "0001" => b(i) := '1';
				when "0010" => b(i) := '2';
				when "0011" => b(i) := '3';
				when "0100" => b(i) := '4';
				when "0101" => b(i) := '5';
				when "0110" => b(i) := '6';
				when "0111" => b(i) := '7';
				when "1000" => b(i) := '8';
				when "1001" => b(i) := '9';
				when "1010" => b(i) := 'A';
				when "1011" => b(i) := 'B';
				when "1100" => b(i) := 'C';
				when "1101" => b(i) := 'D';
				when "1110" => b(i) := 'E';
				when "1111" => b(i) := 'F';
				when others => b(i) := 'X';
			end case;
		end loop;
		return b;
	end function;


    --generate random message to test
    type testMessagesarr is array(3 downto 0) of std_logic_vector(C_block_size - 1 downto 0);
    signal testMessages : testMessagesarr;

    --filling in test data
    procedure generate_test_messages(signal message_i : out testMessagesarr) is
        variable seed1 : positive;
        variable seed2 : positive;
        variable seed3 : positive;
        variable rand : real;
    begin
        --calcing test data
        for o in 3 downto 0 loop
            for i in C_block_size - 1 downto 0 loop 
                uniform(seed2, seed3, rand);
                if rand > 0.5 then
                    message_i(o)(i) <= '1';
                else
                    message_i(o)(i) <= '0';
                end if;
            end loop;
        end loop;
    end generate_test_messages;

begin
    --Clock generation
    clk <= not clk after clk_period / 2;

    reset_gen: process is
    begin
        generate_test_messages(message_i => testMessages);
        reset_n <= '0';
        wait for clk_period;
        reset_n <= '1';
        wait;
    end process;

    --Pushing data to data_in
    -- datapusher: process is
    -- begin
    --     wait for 60 ns;

    --     wait until rising_edge(clk);
    --     write_all : for i in 3 downto 0 loop
    --         --make sure puller is finished before we can push more messages
    --         if (ready_for_push = '0') then
    --             wait until rising_edge(ready_for_push);
    --         end if;
    --         message <= testMessages(i);
    --         key <= e;
    --         valid_in <= '1';
    --         --pusher sets ready_for_push to 0 after pushing
    --         --puller is responsible for setting it to 1 again
    --         ready_for_push <= '0';
    --         if (ready_in = '0') then
    --             wait until rising_edge(ready_in);
    --         end if;
    --         wait until falling_edge(clk);
    --         wait until rising_edge(clk);
    --         valid_in <=  '0';
    --         wait until falling_edge(clk);
    --         wait until rising_edge(clk);

    --     end loop write_all;
    --     wait;
    -- end process datapusher;

    --pulling result
    -- datapuller : process is
    --     variable readout : std_logic_vector(C_block_size - 1 downto 0);
    -- begin
    --     wait for 60 ns;
    --     wait until rising_edge(clk);
    --     readout_all : for i in 3 downto 0 loop
    --         ready_out <= '1';
    --         if not (valid_out = '1') then
    --             wait until rising_edge(valid_out);
    --         end if;
    --         wait until falling_edge(clk);
    --         wait until rising_edge(clk);
    --         ready_out <= '0';
            
    --         --put encrypted message back into circuit for decryption
    --         message <= result;
    --         key <= d;
    --         valid_in <= '1';
    --         if not (ready_in = '1') then
    --             wait until rising_edge(ready_in);
    --         end if;
    --         wait until falling_edge(clk);
    --         wait until rising_edge(clk);
    --         valid_in <= '0';
    --         wait until falling_edge(clk);
    --         wait until rising_edge(clk);

    --         ready_out <= '1';
    --         if not (valid_out = '1') then
    --             wait until rising_edge(valid_out);
    --         end if;
    --         wait until falling_edge(clk);
    --         wait until rising_edge(clk);

    --         ready_out <= '0';
    --         readout := result;
    --         wait until falling_edge(clk);
    --         wait until rising_edge(clk);

    --         --tell pusher it can send a new message
    --         ready_for_push <= '1';

    --         -- assert testMessages(i) = readout;
    --         --     report "Incorrect result: test " & integer'image(i) & " expected [" & stdvec_to_string(message(i)) & "] got [" & stdvec_to_string(readout) & "]"
    --         --         severity failure;

        -- end loop readout_all;

    -- end process datapuller;

    --process is full testing of one word
    --includes encryption and decryption
    data_handler: process is
    begin
        key <= e;
        wait for 60 ns;
        wait until rising_edge(clk);
        write_all: for i in 3 downto 0 loop
            --ready_for_push is initialized as 1
            message <= testMessages(i);
            valid_in <= '1';

            if (ready_in = '0') then
                wait until rising_edge(ready_in);
            end if;

            --wait one clock cycle
            wait until falling_edge(clk);
            wait until rising_edge(clk);
            ready_for_push <= '0';
            valid_in <= '0';
            wait until falling_edge(clk);
            wait until rising_edge(clk);
            ready_for_push <= '1';

            --modexp now has message to be encrypted
            --wait for an answer, then send it back
            wait until rising_edge(valid_out);
            message <= result;
            valid_in <= '1';

            if (ready_in = '0') then
                wait until rising_edge(ready_in);
            end if;

            --wait one clock cycle
            wait until falling_edge(clk);
            wait until rising_edge(clk);
            ready_for_push <= '0';
            valid_in <= '0';
            wait until falling_edge(clk);
            wait until rising_edge(clk);
            ready_for_push <= '1';

            wait until rising_edge(valid_out);

        end loop write_all;

    end process data_handler;

    DUT : entity work.montgomery_modexp(rtl)

    generic map(
        C_block_size => C_block_size
    )

    port map (
        clk => clk,
        reset_n => reset_n,
        valid_in => valid_in,
        ready_in => ready_in,
        message => message,
        key => key,
        ready_out => ready_out,
        valid_out => valid_out,
        result => result,
        n => n,
        n_prime => n_prime,
        r_stuff => r_stuff
    );

    -- SEQUENCER_PROC : process
    -- begin
    --     wait for clk_period * 2;

    --     reset_n <= '1';

    --     wait for clk_period * 10;
    --     assert false
    --         report "Replace this with your test cases"
    --         severity failure;

    --     finish;
    -- end process;

end architecture;