library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;

use work.montgomery_pkg.all;

entity montgomery_modexp2 is
    generic (
		C_block_size : integer := 256;
		GC_LIMB_WIDTH : integer := 32
	);
	port (
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC;
    --------------------------------------------------
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC := '0';
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC := '0';
    --------------------------------------------------
        msgin_last  : in STD_LOGIC;
        msgout_last : out STD_LOGIC;
    --------------------------------------------------
		message 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR( C_block_size-1 downto 0 ); -- e or d (encrypt or decrypt)
    --------------------------------------------------
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0) := (others => '0');
    --------------------------------------------------
		r_stuff 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0); --r^2 % n precalculated 
        n   : in STD_LOGIC_VECTOR(C_block_size-1 downto 0);
        n_prime : in STD_LOGIC_VECTOR(C_block_size-1 downto 0)
	);
end montgomery_modexp2;

architecture rtl of montgomery_modexp2 is

    -- Make finite state machine
    type FSM_T is (
        ST_IDLE,
        ST_WAIT_FOR_MONPRO,
        ST_M_TO_MONTGOMERY,
        ST_C_SQUARED,
        ST_M_TIMES_C,
        ST_C_TO_MONTGOMERY,
        ST_RETURN,
        ST_HOLD
    );
    signal state : FSM_T := ST_IDLE;
    signal next_state : FSM_T := ST_IDLE;

    type RESULT_MUX_T is (MUX_M_BAR, MUX_C_BAR, MUX_RESULT);
    signal result_mux : RESULT_MUX_T;

    -- Make internal signals
    signal a : std_logic_vector(C_block_size - 1 downto 0) := (others => '0');
    signal b : std_logic_vector(C_block_size - 1 downto 0) := (others => '0');
    signal M_bar : std_logic_vector(C_block_size - 1 downto 0) := (others => '0');
    signal C_bar : std_logic_vector(C_block_size - 1 downto 0) := (others => '0');

    -- Make local signals for inputs
    signal s_message : std_logic_vector(C_block_size - 1 downto 0);
    signal s_key : std_logic_vector(C_block_size - 1 downto 0);
    signal s_r_squared : std_logic_vector(C_block_size - 1 downto 0);
    signal s_n : std_logic_vector(C_block_size - 1 downto 0);
    signal s_n_prime : std_logic_vector(C_block_size - 1 downto 0);
    signal s_msgin_last : std_logic;

    -- Monpro signals
    signal monpro_in_valid : std_logic;
    signal monpro_in_ready : std_logic;
    signal monpro_out_valid : std_logic;
    signal monpro_out_ready : std_logic;
    signal monpro_data : std_logic_vector(C_block_size - 1 downto 0);


    function leftmost_one_index(value : std_logic_vector) return integer is
    begin

        for i in value'range loop
            if value(i) = '1' then
                return i;
            end if;
        end loop;

        return 0;

    end function;
        
    signal key_index : integer range -1 to C_block_size - 1;
    
begin

    --------------------------------------------------
    -- Instantiate montgomery monpro module
    --------------------------------------------------
    monpro : entity work.montgomery_monpro_cios_systolic_array
    generic map(
        GC_DATA_WIDTH => C_block_size
    )
    port map(
            clk => clk,
            rst_n => reset_n,
            --------------------------------------------------
            in_valid => monpro_in_valid,
            out_ready => monpro_out_ready,
            in_ready => monpro_in_ready,
            out_valid => monpro_out_valid,
            --------------------------------------------------
            a => a,
            b => b,
            --------------------------------------------------
            n => s_n,
            n_prime => s_n_prime(GC_LIMB_WIDTH - 1 downto 0),
            --------------------------------------------------
            u => monpro_data
    );


    --------------------------------------------------
    -- Main process
    --------------------------------------------------
    modexp_proc : process(clk, reset_n)

        variable v_out_valid : std_logic;
        variable v_in_ready : std_logic;

        variable v_monpro_in_valid : std_logic; -- Valid data to send to monpro
        variable v_monpro_out_ready : std_logic; -- Ready to recieve from monpro

    begin

        --------------------------------------------------
    	if reset_n = '0' then
        --------------------------------------------------

            -- Result is 0
        	result <= (others => '0');

            -- Reset counters
            key_index <= C_block_size - 1;

            -- Reset state
            state <= ST_IDLE;

        --------------------------------------------------
      	elsif rising_edge(clk) then
        --------------------------------------------------

            v_out_valid := '0';
            v_in_ready := '0';

            v_monpro_in_valid := '0';
            v_monpro_out_ready := '0';

            --------------------------------------------------
            -- Finite State Machine
            --------------------------------------------------
        	case state is

                --------------------------------------------------
                -- Wait for top level to give message and key
                --------------------------------------------------
                when ST_IDLE =>
                --------------------------------------------------

                    v_in_ready := '1';

                    -- Reset internal signals
                    C_bar <= (others => '0');
                    M_bar <= (others => '0');

                    result <= (others => '0');

                    -- when modexp has valid data, load values and go to next state
                    if valid_in = '1' then 

                        -- Calculate M_bar
                        state <= ST_M_TO_MONTGOMERY;
                        
                        -- Load input values
                        s_message <= message;
                        s_key <= key;
                        s_n <= n;
                        s_n_prime <= n_prime;
                        s_r_squared <= r_stuff;
                        s_msgin_last <= msgin_last;

                        key_index <= leftmost_one_index(key);

                        v_in_ready := '0';

                    end if;
            
                --------------------------------------------------
                -- Calculate monpro(M, r² mod n)
                --------------------------------------------------
                when ST_M_TO_MONTGOMERY =>
                --------------------------------------------------

                    a <= s_message;
                    b <= r_stuff;

                    v_monpro_in_valid := '1';
                    result_mux <= MUX_M_BAR;
                    
                    if monpro_in_ready = '1' then
                        state <= ST_WAIT_FOR_MONPRO;
                        next_state <= ST_C_TO_MONTGOMERY;
                    end if;

                --------------------------------------------------
                -- Calculate monpro(C, r² mod n)
                --------------------------------------------------
                when ST_C_TO_MONTGOMERY =>
                --------------------------------------------------

                    a <= std_logic_vector(to_unsigned(1, C_block_size));
                    b <= r_stuff;

                    v_monpro_in_valid := '1';
                    result_mux <= MUX_C_BAR;

                    if monpro_in_ready = '1' then
                        state <= ST_WAIT_FOR_MONPRO;
                        next_state <= ST_C_SQUARED;
                    end if;

                --------------------------------------------------
                -- Calculate monpro(C_bar, C_bar)
                --------------------------------------------------
                when ST_C_SQUARED =>
                --------------------------------------------------

                    a <= C_bar;
                    b <= C_bar;

                    v_monpro_in_valid := '1';
                    result_mux <= MUX_C_BAR;

                    if monpro_in_ready = '1' then
                        state <= ST_WAIT_FOR_MONPRO;

                        if s_key(key_index) = '1' then
                            next_state <= ST_M_TIMES_C;
                        else
                            next_state <= ST_C_SQUARED;
                        end if;

                        key_index <= key_index - 1;

                    end if;

                --------------------------------------------------
                -- Calculate monpro(M_bar, C_bar)
                --------------------------------------------------
                when ST_M_TIMES_C =>
                --------------------------------------------------

                    a <= M_bar;
                    b <= C_BAR;

                    v_monpro_in_valid := '1';
                    result_mux <= MUX_C_BAR;

                    if monpro_in_ready = '1' then
                        state <= ST_WAIT_FOR_MONPRO;

                        -- The keys have to be odd values so on the last iteration
                        -- M times C will always be ran, we can check this here.
                        if key_index = -1 then
                            next_state <= ST_RETURN;
                        else
                            next_state <= ST_C_SQUARED;
                        end if;

                    end if;

                --------------------------------------------------
                -- Calculate monpro(C_bar, 1)
                --------------------------------------------------
                when ST_RETURN =>
                --------------------------------------------------

                    a <= C_bar;
                    b <= std_logic_vector(to_unsigned(1, C_block_size));

                    v_monpro_in_valid := '1';
                    result_mux <= MUX_RESULT;

                    if monpro_in_ready = '1' then
                        state <= ST_WAIT_FOR_MONPRO;
                        next_state <= ST_HOLD;
                    end if;

                --------------------------------------------------
                when ST_WAIT_FOR_MONPRO =>
                --------------------------------------------------

                    v_monpro_out_ready := '1';

                    if monpro_out_valid = '1' then

                        -- Load output value
                        case result_mux is
                            when MUX_C_BAR => C_bar <= monpro_data;
                            when MUX_M_BAR => M_bar <= monpro_data;
                            when MUX_RESULT => 

                                result <= monpro_data;
                                v_out_valid := '1';

                            when others =>
                        end case;

                        state <= next_state;

                    end if;

                --------------------------------------------------
                when ST_HOLD =>
                --------------------------------------------------

                    v_out_valid := '1';

                    if ready_out = '1' then
                        state <= ST_IDLE;
                        v_in_ready := '1';
                        v_out_valid := '0';
                    end if;

                --------------------------------------------------
                when others => state <= ST_IDLE;
                --------------------------------------------------
                    
        	end case;

            valid_out <= v_out_valid;
            ready_in <= v_in_ready;
            msgout_last <= s_msgin_last and v_out_valid;

            monpro_out_ready <= v_monpro_out_ready;
            monpro_in_valid <= v_monpro_in_valid;

      	end if;
    end process;

end architecture;
