library ieee;
use ieee.std_logic_1164.all;

entity exponentiation is
	generic (
		C_BLOCK_SIZE : integer := 256
	);
	port (
		--input controll
		valid_in	: in std_logic;
		ready_in	: out std_logic;

		--input data
		message 	: in std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
		key 		: in std_logic_vector(C_BLOCK_SIZE - 1 downto 0);

		--ouput controll
		ready_out	: in std_logic;
		valid_out	: out std_logic;

		--output data
		result 		: out std_logic_vector(C_BLOCK_SIZE - 1 downto 0);

		--modulus
		modulus 	: in std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
        n_prime     : in std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
        r_squared   : in std_logic_vector(C_BLOCK_SIZE - 1 downto 0);

		--utility
		clk 		: in std_logic;
		reset_n 	: in std_logic
	);
end exponentiation;


architecture expBehave of exponentiation is
begin

    modexp: entity work.montgomery_modexp2
        generic map(
            C_block_size => C_BLOCK_SIZE,
            GC_LIMB_WIDTH => 32
        )
        port map(
            valid_in => valid_in,
            ready_in => ready_in,

            --input data
            message => message,
            key => key,

            --ouput controll
            ready_out => ready_out,
            valid_out => valid_out,

            --output data
            result => result,

            -- modulus
            r_stuff => r_squared,
            n => modulus,
            n_prime => n_prime,

            --utility
            clk => clk,
            reset_n => reset_n
        );

end expBehave;
