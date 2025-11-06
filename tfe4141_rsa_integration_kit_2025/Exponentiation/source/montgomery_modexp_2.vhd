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
		ready_in	: out STD_LOGIC;
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;
    --------------------------------------------------
		message 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR( C_block_size-1 downto 0 ); -- e or d (encrypt or decrypt)
    --------------------------------------------------
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);
    --------------------------------------------------
		r_stuff 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0); --r^2 % n precalculated 
        n   : in STD_LOGIC_VECTOR(C_block_size-1 downto 0);
        n_prime : in STD_LOGIC_VECTOR(C_block_size-1 downto 0)
	);
end montgomery_modexp2;

architecture rtl of montgomery_modexp2 is
    -- make finite state machine
    type FSM is (ST_IDLE, ST_M_TO_MONTGOMERY, ST_C_TO_MONTGOMERY, ST_LOAD, ST_CALC, ST_HOLD);
    signal state : FSM;

    --make internal signals
    signal a : std_logic_vector(C_block_size - 1 downto 0);
    signal b : std_logic_vector(C_block_size - 1 downto 0);
    signal M_bar : std_logic_vector(C_block_size - 1 downto 0);
    signal C_bar : std_logic_vector(C_block_size - 1 downto 0);

    signal done_with_calc : unsigned(0 downto 0);

    signal calc_type : integer range 0 to 4;
    -- 0 --> M_bar <= monpro(M, (r*r)%n)
    -- 1 --> C_bar <= monpro(1, (r*r)%n)
    -- 2 --> C_bar <= monpro(C_bar, C_bar)
    -- 3 --> C_bar <= monpro(M_bar, C_bar)
    -- 4 --> result <= monpro(C_bar, 1)

    -- keep track of index of e
    signal loop_counter : integer range 0 to C_block_size - 1;

    --monpro logic--
    signal monpro_in_valid : std_logic;
    signal monpro_in_ready : std_logic;
    signal monpro_out_valid : std_logic;
    signal monpro_out_ready : std_logic;
    signal monpro_data : std_logic_vector(C_block_size - 1 downto 0);
    
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
            in_valid => monpro_in_valid, --left Monpro signals / right modexp signals
            out_ready => monpro_out_ready,  --output
            in_ready => monpro_in_ready,    --input
            out_valid => monpro_out_valid,  --input
            --------------------------------------------------
            a => a,
            b => b,
            --------------------------------------------------
            n => n,
            n_prime => n_prime(GC_LIMB_WIDTH - 1 downto 0),
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

        v_out_valid := '0';
        v_in_ready := '0';

        v_monpro_in_valid := '0';
        v_monpro_out_ready := '0';

        --------------------------------------------------
    	if reset_n = '0' then
        --------------------------------------------------

            -- Result is 0
        	result <= (others => '0');

            -- Reset counters
            loop_counter <= 0;
            calc_type <= 0;

            -- Reset state
            state <= ST_IDLE;

        --------------------------------------------------
      	elsif rising_edge(clk) then
        --------------------------------------------------

            --------------------------------------------------
            -- Finite State Machine
            --------------------------------------------------
        	case state is

                --------------------------------------------------
                -- Wait for top level to give message and key
                --------------------------------------------------
                when ST_IDLE =>
                --------------------------------------------------

                    calc_type <= 0;
                    loop_counter <= 0;

                    v_in_ready := '1'; -- ready to accept data

                    -- when modexp has valid data, load values and go to next state
                    if valid_in = '1' then 

                        -- Calculate M_bar
                        state <= ST_M_TO_MONTGOMERY;
                        
                        a <= message;
                        b <= r_stuff;
                        v_monpro_in_valid := '1'; -- monpro can now recieve valid data

                    end if;
            
            ---------------------------
            when ST_M_TO_MONTGOMERY =>
            ---------------------------
                v_monpro_in_valid := '1'; -- telling monpro the data is ready untill i get a response

                if monpro_in_ready = '1' then
                --hanshake is done
                    state <= ST_CALC;
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
                        if calc_type < 2 then
                            calc_type <= calc_type + 1;

                        elsif calc_type = 2 and key(C_block_size - 1 - to_integer(loop_counter)) = '1' then
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

      	end if;
    end process;

end architecture;
