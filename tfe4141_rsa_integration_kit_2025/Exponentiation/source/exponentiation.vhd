library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity exponentiation is
	generic (
		C_BLOCK_SIZE : integer := 256;
        GC_NUM_CORES : integer := 7;
        GC_TAG_LENGTH : integer := 8
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

    type T_INPUT_VECTOR_ARRAY is array(0 to GC_NUM_CORES - 1) of std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    type T_INPUT_BIT_ARRAY is array(0 to GC_NUM_CORES - 1) of std_logic;

    -- Handshake signals for each core
    signal valid_in_array : T_INPUT_BIT_ARRAY := (others => '0');
    signal ready_in_array : T_INPUT_BIT_ARRAY := (others => '0');
    signal valid_out_array : T_INPUT_BIT_ARRAY := (others => '0');
    signal ready_out_array : T_INPUT_BIT_ARRAY := (others => '0');
    signal msgout_last_array : T_INPUT_BIT_ARRAY := (others => '0');

    -- Store a copy of all inputs, because we need one extra clock cycle to send the valid flags to
    -- the internal modexp that will perform the arithmatic
    signal s_message : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    signal s_key : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    signal s_modulus : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    signal s_n_prime : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    signal s_r_squared : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    signal s_msgin_last : std_logic;


    signal result_array : T_INPUT_VECTOR_ARRAY := (others => (others => '0'));
    
    -- Tag arrays for tracking message ordering
    type T_TAG_ARRAY is array(0 to GC_NUM_CORES - 1) of std_logic_vector(GC_TAG_LENGTH - 1 downto 0);
    signal msg_tag_in_array : T_TAG_ARRAY := (others => (others => '0'));
    signal msg_tag_out_array : T_TAG_ARRAY := (others => (others => '0'));
    
    signal valid_out_int : std_logic := '0';
    signal result_int : std_logic_vector(C_BLOCK_SIZE - 1 downto 0) := (others => '0');
    signal msgout_last_int : std_logic := '0';

    -- Finite state machine for core status
    type T_CORE_STATE is (ST_CORE_READY, ST_CORE_WORKING, ST_CORE_DONE);

    -- Record for each core
    -- https://nandland.com/record/
    type R_CORE_STATUS is record
        state : T_CORE_STATE;
        msg_tag : std_logic_vector(GC_TAG_LENGTH - 1 downto 0);
        -- Store outputs from core incase we want the core to do new work before handing out results
        result : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
        msgout_last : std_logic;
    end record;

    -- Table to keep track of all core statuses
    type T_CORE_TABLE is array(0 to GC_NUM_CORES - 1) of R_CORE_STATUS;
    signal core_status_table : T_CORE_TABLE;

    -- Tag counter for assigning unique tags to each message
    signal msg_tag_counter : std_logic_vector(GC_TAG_LENGTH - 1 downto 0) := (others => '0');
    signal expected_output_tag : std_logic_vector(GC_TAG_LENGTH - 1 downto 0) := (others => '0');

    signal in_round_robin_pointer : integer range 0 to GC_NUM_CORES - 1 := 0;

begin

    --------------------------------------------------
    -- Check if we can handle input signal
    --------------------------------------------------
    p_ready: process(all)
        variable v_has_free_core : boolean := false;
    begin

        v_has_free_core := false;

        -- Check if any core is ready to accept new work
        -- v_has_free_core := any_ready(ready_in_array);
        for k in 0 to GC_NUM_CORES - 1 loop
            -- Check if this core is ready to accept new work
            if core_status_table(k).state = ST_CORE_READY 
               and ready_in_array(k) = '1' then
                v_has_free_core := true;
                exit;
            end if;
        end loop;

        -- We can accept input if we have a free core.
        -- Since this is combinatorial, and since the input 
        -- process does the same check, this should be set 
        -- one clock cycle before the core is actually ready 
        if v_has_free_core then
            ready_in <= '1';
        else
            ready_in <= '0';
        end if;

    end process p_ready;

    --------------------------------------------------
    -- Input process : round robin
    --------------------------------------------------
    p_input_control: process(clk, reset_n)

        variable v_found_core : boolean;
        variable v_chosen_core : integer range 0 to GC_NUM_CORES - 1;

        variable v_valid_in_array : T_INPUT_BIT_ARRAY;

    begin

        --------------------------------------------------
        if rising_edge(clk) then
        --------------------------------------------------

            --------------------------------------------------
            if reset_n = '0' then
            --------------------------------------------------

                in_round_robin_pointer <= 0;

                -- Reset all valid_in signals
                for k in 0 to GC_NUM_CORES - 1 loop
                    v_valid_in_array(k) := '0';
                    core_status_table(k).state <= ST_CORE_READY;
                    core_status_table(k).result <= (others => '0');
                    core_status_table(k).msgout_last <= '0';
                    core_status_table(k).msg_tag <= (others => '0');
                end loop;
                
                -- Reset tag counters
                msg_tag_counter <= (others => '0');
                expected_output_tag <= (others => '0');

            --------------------------------------------------
            else
            --------------------------------------------------
            
                -- Reset variables
                for k in 0 to GC_NUM_CORES - 1 loop
                    v_valid_in_array(k) := '0';
                end loop;

                v_found_core := false;

                --------------------------------------------------
                -- Input: Find a free core and assign work
                --------------------------------------------------
                if (valid_in = '1') and (ready_in = '1') then

                    s_message <= message;
                    s_key <= key;

                    s_modulus <= modulus;
                    s_n_prime <= n_prime;
                    s_r_squared <= r_squared;
                    s_msgin_last <= msgin_last;


                    -- Find a free core using round-robin
                    for offset in 0 to GC_NUM_CORES - 1 loop
                        v_chosen_core := (in_round_robin_pointer + offset) mod GC_NUM_CORES;
                        
                        -- Check if this core is ready to accept new work
                        if core_status_table(v_chosen_core).state = ST_CORE_READY 
                           and ready_in_array(v_chosen_core) = '1' then
                            v_found_core := true;
                            exit;
                        end if;
                    end loop;

                    if v_found_core then

                        -- Assign work to the chosen core
                        -- Data (message, key, msgin_last) is sampled by the core when valid_in is asserted
                        v_valid_in_array(v_chosen_core) := '1';
                        
                        -- Assign a unique tag to this message
                        msg_tag_in_array(v_chosen_core) <= msg_tag_counter;
                        
                        -- Update core status and track which tag this core is handling
                        core_status_table(v_chosen_core).state <= ST_CORE_WORKING;
                        core_status_table(v_chosen_core).msg_tag <= msg_tag_counter;
                        
                        -- Update round-robin pointer for next assignment
                        in_round_robin_pointer <= (v_chosen_core + 1) mod GC_NUM_CORES;
                        
                        msg_tag_counter <= std_logic_vector((unsigned(msg_tag_counter) + 1) mod GC_TAG_LENGTH);
                    end if;
                end if;

                --------------------------------------------------
                -- Modexp is done calculating: Put results into core table
                --------------------------------------------------
                for i in 0 to GC_NUM_CORES - 1 loop
                    if core_status_table(i).state = ST_CORE_WORKING then
                        -- Check if this core has finished (valid_out is asserted)
                        -- The result is stable on result_array(i) while valid_out is '1'
                        if valid_out_array(i) = '1' then
                            -- Store the result and tag - this happens on the clock edge after valid_out is asserted
                            -- The result is guaranteed to be stable at this point
                            core_status_table(i).result <= result_array(i);
                            core_status_table(i).msgout_last <= msgout_last_array(i);
                            -- Tag comes from the core's output
                            core_status_table(i).msg_tag <= msg_tag_out_array(i);
                            core_status_table(i).state <= ST_CORE_DONE;
                        end if;
                    end if;
                end loop;

                --------------------------------------------------
                -- Output routing: Advance tag when result is accepted
                --------------------------------------------------
                -- Find the core with the expected tag, check if it's done,
                -- and if downstream accepted the result (ready_out = '1' AND valid_out_int was '1')
                -- We check valid_out_int to ensure we were actually outputting before advancing
                for i in 0 to GC_NUM_CORES - 1 loop
                    -- Check if this is the core we're currently outputting from (matches expected tag)
                    if core_status_table(i).msg_tag = expected_output_tag 
                       and core_status_table(i).state = ST_CORE_DONE 
                       and ready_out = '1'
                       and valid_out_int = '1' then

                        -- Mark core as ready for new work
                        core_status_table(i).state <= ST_CORE_READY;
                        core_status_table(i).result <= (others => '0');
                        core_status_table(i).msgout_last <= '0';
                        core_status_table(i).msg_tag <= (others => '0');
                        
                        expected_output_tag <= std_logic_vector((unsigned(expected_output_tag) + 1) mod GC_TAG_LENGTH);
                        exit;
                    end if;
                end loop;

                valid_in_array <= v_valid_in_array;

            --------------------------------------------------
            end if;

        end if;

    end process p_input_control;

    --------------------------------------------------
    -- Output routing: Route results to output port and ready_out signals
    --------------------------------------------------
    p_output: process(all)

        variable v_valid_out : std_logic;
        variable v_result : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
        variable v_msgout_last : std_logic;
        variable v_ready_out_array : T_INPUT_BIT_ARRAY;

        variable v_output_core_found : boolean;
        variable v_output_core : integer range 0 to GC_NUM_CORES - 1;
    begin

        v_valid_out := '0';
        v_result := (others => '0');
        v_msgout_last := '0';
        v_output_core := 0;

        for i in 0 to GC_NUM_CORES - 1 loop
            v_ready_out_array(i) := '0';
        end loop;

        -- Find the core with the expected output tag
        v_output_core_found := false;
        for i in 0 to GC_NUM_CORES - 1 loop
            -- Check if this core has the expected tag and has completed
            if core_status_table(i).msg_tag = expected_output_tag and core_status_table(i).state = ST_CORE_DONE then
                v_output_core_found := true;
                v_output_core := i;
                exit;
            end if;
        end loop;

        -- Route output from the core with the expected tag if it's done
        if v_output_core_found then

            valid_out_int <= '1';
            v_valid_out := '1';
            v_result := core_status_table(v_output_core).result;
            v_msgout_last := core_status_table(v_output_core).msgout_last;

            -- Assert ready_out to the core that's currently outputting
            -- This allows the core to transition from ST_HOLD back to ST_IDLE
            v_ready_out_array(v_output_core) := ready_out;
        else
            valid_out_int <= '0';
        end if;

        valid_out <= v_valid_out;
        result <= v_result;
        msgout_last <= v_msgout_last;
        ready_out_array <= v_ready_out_array;

    end process p_output;

    --------------------------------------------------
    -- Generate as many cores as we can fit
    --------------------------------------------------
    g_modexp: for i in 0 to GC_NUM_CORES - 1 generate

        --------------------------------------------------
        -- Inputs that are cached do not need to be stored in arrays
        --------------------------------------------------
        i_modexp: entity work.montgomery_modexp2
            generic map(
                C_block_size => C_BLOCK_SIZE,
                GC_LIMB_WIDTH => 32,
                GC_TAG_LENGTH => GC_TAG_LENGTH
            )
            port map(
                valid_in => valid_in_array(i),
                ready_in => ready_in_array(i),

                --input data
                message => s_message,
                key => s_key,

                --ouput controll
                ready_out => ready_out_array(i),
                valid_out => valid_out_array(i),

                msgin_last => s_msgin_last,
                msgout_last => msgout_last_array(i),

                --output data
                result => result_array(i),

                -- message tags for ordering
                msg_tag_in => msg_tag_in_array(i),
                msg_tag_out => msg_tag_out_array(i),

                -- modulus
                r_stuff => s_r_squared,
                n => s_modulus,
                n_prime => s_n_prime,

                --utility
                clk => clk,
                reset_n => reset_n
            );

    end generate g_modexp;

end expBehave;
