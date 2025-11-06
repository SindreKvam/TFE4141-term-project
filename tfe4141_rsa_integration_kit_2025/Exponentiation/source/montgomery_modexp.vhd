library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

use work.montgomery_pkg.all;

entity montgomery_modexp is
    generic (
		C_block_size : integer := 16
	);
	port (
		--input controll
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC;

		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 ); -- e or d (encrypt or decrypt)

		--ouput controll
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;

		--output data
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		-- modulus
		r_stuff 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0); --r^2 % n precalculated 
        n   : in STD_LOGIC_VECTOR(C_block_size-1 downto 0);
        n_prime : in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC
	);
end montgomery_modexp ; 

architecture rtl of montgomery_modexp is
    -- make finite state machine
    type FSM is (ST_IDLE, ST_HANDSHAKE, ST_WAIT_FOR_ONE_INDEX, ST_LOAD, ST_CALC, ST_HOLD);
    signal state : FSM;

    --make internal signals
    signal a : std_logic_vector(C_block_size - 1 downto 0);
    signal b : std_logic_vector(C_block_size - 1 downto 0);
    signal key_sig : std_logic_vector(C_block_size-1 downto 0);
    signal M_bar : std_logic_vector(C_block_size - 1 downto 0);
    signal C_bar : std_logic_vector(C_block_size - 1 downto 0);

    signal loop_counter : unsigned(8 downto 0);-- keep track of index of e
    signal calc_type : unsigned(2 downto 0);-- there are 5 different monpro variations
    signal done_with_calc : unsigned(0 downto 0);
    -- 0 --> M_bar <= monpro(1,(r*r)%n)
    -- 1 --> C_bar <= monpro(1,(r*r)%n)
    -- 2 --> C_bar <= monpro(C_bar, C_bar)
    -- 3 --> C_bar <= monpro(M_bar, C_bar)

    --monpro logic--
    signal monpro_in_valid : std_logic;
    signal monpro_in_ready : std_logic;
    signal monpro_out_valid : std_logic;
    signal monpro_out_ready : std_logic;
    signal monpro_data : std_logic_vector(C_block_size - 1 downto 0);

    --find first one index logic--
    signal first_one_valid_in : std_logic;
    signal first_one_valid_out : std_logic;
    signal first_one_ready_in : std_logic;
    signal first_one_ready_out : std_logic;
    signal index_first_one : std_logic_vector(8 downto 0);
    signal one_found : std_logic;
    signal first_cycle : std_logic; -- for doing some stuff while waiting for index of first 1

    
    
begin
    --include montgomery monpro--
    monpro : entity work.montgomery_monpro
    generic map(
        GC_DATA_WIDTH => C_block_size
    )
    port map(
            clk => clk,
            rst_n => reset_n,
            --------------------------------------------------
            in_valid => monpro_in_valid, --left Monpro signals / right modexp signals
            out_ready => monpro_out_ready,  --output
            in_ready => monpro_in_ready,    --input
            out_valid => monpro_out_valid,  --input
            --------------------------------------------------
            a => a,
            b => b,
            --------------------------------------------------
            n => n,
            n_prime => n_prime,
            --------------------------------------------------
            u => monpro_data
    );

    ----------------------------
    --include first_one_finder--
    ----------------------------
    first_one_finder_proc : entity work.first_one_finder
    port map (
        clk => clk,--should be able to increase this a lot mabie another clock
        reset_n => reset_n,
        data => key_sig,

        --output
        first_one_index => index_first_one,

        --handshake signals
        in_ready => first_one_ready_in,
        in_valid => first_one_valid_in,

        out_ready => first_one_ready_out,
        out_valid => first_one_valid_out
    );


    --------------------    
    --starting process--
    --------------------
    modexp_proc : process(clk, reset_n)

        variable v_out_valid : std_logic; --temporary monpro in valid
        variable v_in_ready : std_logic; --variables are serial not concurrent--

        variable v_monpro_in_valid : std_logic; --valid data to send to monpro
        variable v_monpro_out_ready : std_logic; --ready to recieve from monpro

        variable v_first_one_valid_in : std_logic;
        variable v_first_one_ready_out : std_logic;


    begin
    	if reset_n = '0' then
        	result <= (others => '0');
            loop_counter <= (others => '0');
            calc_type <= (others => '0');
            state <= ST_IDLE;
            v_in_ready := '1'; -- ready to accept data

      	elsif rising_edge(clk) then
            v_out_valid := '0';
            v_in_ready := '0';

            v_monpro_in_valid := '0';
            v_monpro_out_ready := '0';

            v_first_one_valid_in := '0';
            v_first_one_ready_out := '0';
            ------------------------
            --finite state machine--
            ------------------------
        	case state is
          	---------------------------
          	when ST_IDLE =>
          	---------------------------
                calc_type <= (others => '0');-- allways start new modexp with 0 --> M_bar <= monpro(1,(r*r)%n)
                loop_counter <= (others => '0');
                first_cycle <= '1';-- because we can do some voodo stuff the first time

            	if valid_in = '1' then -- when modexp has valid_in change state
              		state <= ST_HANDSHAKE;
                    --monpro stuff--
                    a <= message;
                    b <= r_stuff;
                    v_monpro_in_valid := '1'; -- monpro can now recieve valid data
                    
                    --first one index--
                    key_sig <= key;
                    v_first_one_valid_in := '1';-- first_one_finder har valid key
                    
                else
                    v_monpro_in_valid := '0';
                    v_monpro_out_ready := '0';

                    v_in_ready := '1'; -- ready to accept data
                    v_out_valid := '0'; -- output is not ready
            	end if;
            
            ---------------------------
            when ST_HANDSHAKE =>
            ---------------------------
                v_monpro_in_valid := '1'; -- telling monpro the data is ready untill i get a response

                if monpro_in_ready = '1' then
                --hanshake is done
                    state <= ST_CALC;
                end if;
                
            ---------------------------
            when ST_WAIT_FOR_ONE_INDEX =>
            ---------------------------
                v_first_one_ready_out := '1';
                if first_one_valid_out = '1' then
                    one_found <= '1';
                    --index_first_one <= name of index signal
                    loop_counter <= C_block_size - UNSIGNED(index_first_one);--because we have already done the first '1'
                    v_first_one_valid_in := '0'; -- key is no longer valid for first 
                    v_first_one_ready_out := '0';
                elsif one_found = '1' then
                    --find next calctype--
                    if key_sig(C_block_size - 1 - to_integer(loop_counter)) = '1'then
                        calc_type <= TO_UNSIGNED(3,3);
                    else
                        calc_type <= TO_UNSIGNED(2,3);
                        loop_counter <= loop_counter + 1;
                    end if;
                    state <= ST_LOAD;
                end if; 


          	---------------------------
          	when ST_LOAD =>
          	---------------------------

                -- all controll are 0 nothing gets in and nothing gets out    
                state <= ST_HANDSHAKE; --allways maximum in this state one cycle 

                --calctype 0 is handeled by IDLE and HANDSHAKE
                if calc_type = 1 then
                    a <= std_logic_vector(to_unsigned(1, a'length)); -- puts value 1 into a
                    b <= std_logic_vector(r_stuff);
                elsif calc_type = 2 then
                    a <= C_bar;
                    b <= C_bar;
                elsif calc_type = 3 then
                    a <= M_bar;
                    b <= C_bar;
                elsif calc_type = 4 then
                    a <= C_bar;
                    b <= std_logic_vector(to_unsigned(1, C_block_size));
                elsif calc_type = 5 then
                    a <= M_bar;
                    b <= C_bar;
                else
                    state <= ST_IDLE; -- this state cant happen
                    v_in_ready := '1'; -- ready to accept data
                    
                end if;
                -- 0 --> M_bar <= monpro(M,(r*r)%n)
                -- 1 --> C_bar <= monpro(1,(r*r)%n)
                -- 2 --> C_bar <= monpro(C_bar, C_bar)
                -- 3 --> C_bar <= monpro(M_bar, C_bar)

            ---------------------------    
          	when ST_CALC =>
            ---------------------------

                v_monpro_out_ready := '1'; -- ready to recieve from monpro
                if monpro_out_valid = '1' then
                    --handshake done

                    --------
                    --LOAD--
                    --------
                    if calc_type = 0 then
                        M_bar <= monpro_data;

                    elsif calc_type = 1 then
                        C_bar <= monpro_data;

                    elsif calc_type = 2 then
                        C_bar <= monpro_data;

                    elsif calc_type = 3 then
                        C_bar <= monpro_data;
                    
                    elsif calc_type = 4 then
                        result <= monpro_data;

                    elsif calc_type = 5 then
                        C_bar <= monpro_data;
                        
                        
                    else
                        state <= ST_IDLE; -- can not happen
                        v_in_ready := '1'; -- ready to accept data
                    end if;
                    -- 0 --> M_bar <= monpro(1,(r*r)%n)
                    -- 1 --> C_bar <= monpro(1,(r*r)%n)
                    -- 2 --> C_bar <= monpro(C_bar, C_bar)
                    -- 3 --> C_bar <= monpro(M_bar, C_bar)
                    -- 4 --> result <= monpro(C_bar, 1)

                    -----------------------
                    -- check next calc type
                    -----------------------
                    if loop_counter < C_block_size then
                        
                        --first cycle stuff--    
                        if calc_type = 1 and first_cycle = '1' then
                            calc_type <= TO_UNSIGNED(5, 3); --go to calctype 5
                            --to ficure calctype after calctype 2 we need to see first one finder index
                        elsif calc_type = 5 then
                            calc_type <= TO_UNSIGNED(2,3); --ready for calctype 2
                        ---------------------

                        elsif calc_type < 2 then
                            calc_type <= calc_type + 1;

                        

                        elsif calc_type = 2 and key_sig(C_block_size - 1 - to_integer(loop_counter)) = '1' then
                            calc_type <= calc_type + 1;

                        elsif calc_type = 3 then
                            if loop_counter < C_block_size - 1 then
                                calc_type <= calc_type - 1;-- go back in the loop, but not if last bit

                            elsif loop_counter = C_block_size - 1 then
                                calc_type <= TO_UNSIGNED(4, 3); --if it was last bit, go to calctype 4
                                    
                            end if;
                            loop_counter <= loop_counter + 1;
                    
                        else
                            calc_type <= calc_type; -- no change in calc type
                            loop_counter <= loop_counter + 1; 
                        
                        end if;
                    end if;

                    -------------------
                    --Figure next state
                    -------------------
                    -- is the calculation done ?
                    if calc_type = 4 then -- meaning we are done with calc
                        state <= ST_HOLD;
                        v_out_valid := '1'; -- on next clk this module has valid output
                    
                    --first cycle stuff--
                    elsif calc_type = 1 and first_cycle = '1' then
                        state <= ST_LOAD;
                    elsif calc_type = 2 and first_cycle = '1' then
                        v_first_one_ready_out := '1';--we are ready to get data
                        state <= ST_WAIT_FOR_ONE_INDEX;
                        first_cycle <= '0';
                    elsif calc_type = 5 then
                            state <= ST_LOAD;
                    ---------------------

                    elsif loop_counter = C_block_size then
                        calc_type <= to_unsigned(4, 3); --calctype = 4
                        --we are done with calc on next cycle
                        state <= ST_LOAD;
                
                    elsif loop_counter < C_block_size then
                        state <= ST_LOAD;

                    else
                        state <= ST_IDLE;
                        v_in_ready := '1'; -- ready to accept data
                    end if;
                end if;

                


            when ST_HOLD =>
                v_out_valid := '1'; -- my output is available untill something on the outside
                                    -- is ready to input more
                one_found <= '0'; -- mabye new key ? 

                if ready_out = '1' then
                    state <= ST_IDLE; --is this change to fast?
                    v_in_ready := '1'; -- ready to accept data
                end if;
                
            ---------------------------
        	end case;
            valid_out <= v_out_valid;
            ready_in <= v_in_ready;

            monpro_out_ready <= v_monpro_out_ready;
            monpro_in_valid <= v_monpro_in_valid;

            first_one_valid_in <= v_first_one_valid_in;
            first_one_ready_out <= v_first_one_ready_out;

      	end if;
    end process;



end architecture ;