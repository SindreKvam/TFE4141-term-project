library ieee;
use ieee.std_logic_1164.all;

entity exponentiation is
	generic (
		C_BLOCK_SIZE : integer := 256;
        C_NUM_CORES : integer := 7
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

        msgin_last  : in std_logic;
        msgout_last : out std_logic;

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

    type T_INPUT_VECTOR_ARRAY is array(0 to C_NUM_CORES - 1) of std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    type T_INPUT_BIT_ARRAY is array(0 to C_NUM_CORES - 1) of std_logic;

    signal valid_in_array : T_INPUT_BIT_ARRAY := (others => '0');
    signal ready_in_array : T_INPUT_BIT_ARRAY := (others => '0');

    signal valid_out_array : T_INPUT_BIT_ARRAY := (others => '0');
    signal ready_out_array : T_INPUT_BIT_ARRAY := (others => '0');

    signal msgout_last_array : T_INPUT_BIT_ARRAY := (others => '0');

    signal result_array : T_INPUT_VECTOR_ARRAY := (others => (others => '0'));

    -- Function to check if any cores are ready to calc
    -- Calc is short for calculate btw. (Incase you are new to the stream)
    function any_ready(ready_arr : T_INPUT_BIT_ARRAY) return std_logic is
    begin

        for i in ready_arr'range loop
            if ready_arr(i) = '1' then
                return '1';
            end if;
        end loop;

        return '0';
    end;

    signal next_core : integer range 0 to C_NUM_CORES - 1 := 0;

begin

    -- Arbiter: Round-robin
    p_control: process(clk, reset_n)
    begin

        --------------------------------------------------
        if rising_edge(clk) then
        --------------------------------------------------

            --------------------------------------------------
            if reset_n = '0' then
            --------------------------------------------------

                next_core <= 0;

            --------------------------------------------------
            else
            --------------------------------------------------

                

            --------------------------------------------------
            end if;

        end if;

    end process p_control;

    -- Values that are cached on the input does not need multiple copies.
    g_modexp: for i in 0 to C_NUM_CORES - 1 generate

        --------------------------------------------------
        -- Generate as many cores as we can fit
        --------------------------------------------------
        i_modexp: entity work.montgomery_modexp2
            generic map(
                C_block_size => C_BLOCK_SIZE,
                GC_LIMB_WIDTH => 32
            )
            port map(
                valid_in => valid_in_array(i),
                ready_in => ready_in_array(i),

                --input data
                message => message,
                key => key,

                --ouput controll
                ready_out => ready_out_array(i),
                valid_out => valid_out_array(i),

                msgin_last => msgin_last,
                msgout_last => msgout_last_array(i),

                --output data
                result => result_array(i),

                -- modulus
                r_stuff => r_squared,
                n => modulus,
                n_prime => n_prime,

                --utility
                clk => clk,
                reset_n => reset_n
            );

    end generate g_modexp;

end expBehave;
