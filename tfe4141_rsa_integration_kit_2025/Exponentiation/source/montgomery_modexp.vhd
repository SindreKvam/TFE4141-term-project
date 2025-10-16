library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity montgomery_modexp is
    generic (
		C_block_size : integer := 256
	);
	port (
		--input controll
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC;

		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput controll
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;

		--output data
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		-- modulus
		r 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);
        n   : in STD_LOGIC_VECTOR(C_block_size-1 downto 0);
        n_prime : in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC
	);
end montgomery_modexp ; 

architecture rtl of montgomery_modexp is
    -- make finite state machine
    type FSM is (ST_IDLE, ST_LOAD, ST_CALC, ST_HOLD);
    signal state : FSM;

    --make internal signals
    signal a : std_logic_vector(C_block_size - 1 downto 0);
    signal b : std_logic_vector(C_block_size - 1 downto 0);
    signal M_bar : std_logic_vector(C_block_size - 1 downto 0);
    signal C_bar : std_logic_vector(C_block_size - 1 downto 0);

	signal s_calc_counter : unsigned(7 downto 0);
    signal loop_counter : unsigned(7 downto 0);-- keep track of index of e
    signal calc_type : unsigned(1 downto 0);-- there are 4 different monpro variations
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
            out_ready => monpro_out_ready,
            in_ready => monpro_in_ready,
            out_valid => monpro_out_valid,
            --------------------------------------------------
            a => a,
            b => b,
            --------------------------------------------------
            n => n,
            n_prime => n_prime,
            --------------------------------------------------
            u => monpro_data
        );


    --------------------    
    --starting process--
    --------------------
    modexp_proc : process(clk, reset_n)

        variable v_out_valid : std_logic; --temporary monpro in valid
        variable v_out_ready : std_logic; --variables are serial not concurrent--

    begin
        v_out_valid := '0';
        v_out_ready := '0';

    	if reset_n = '0' then
        	result <= (others => '0');
			s_calc_counter <= (others => '0'); --resets counter--
            loop_counter <= (others => '0');
            calc_type <= (others => '0');
            state <= ST_IDLE;

      	elsif rising_edge(clk) then
            ------------------------
            --finite state machine--
            ------------------------
        	case state is
          	---------------------------
          	when ST_IDLE =>
          	---------------------------

                v_out_ready := '1'; -- ready to accept data
                v_out_valid := '0'; -- output is not ready
                
                calc_type <= (others => '0');-- allways start new modexp with 0 --> M_bar <= monpro(1,(r*r)%n)
                loop_counter <= (others => '0');

            	if valid_in = '1' then -- when modexp has valid_in change state
              		state <= ST_LOAD;
            	end if;
          	---------------------------
          	when ST_LOAD =>
          	---------------------------
                v_out_ready := '0';
                v_out_valid := '0';

                monpro_in_ready <= '0';
                monpro_in_valid <= '1'; --telling monpro there is data
                
                if calc_type = 0  then
                    a <= std_logic_vector(to_unsigned(message, a'length)); -- puts value 1 into a
                    b <= std_logic_vector((unsigned(r)*unsigned(r)) mod unsigned(n));
                elsif calc_type = 1 then
                    a <= std_logic_vector(to_unsigned(1, a'length)); -- puts value 1 into a
                    b <= std_logic_vector((unsigned(r)*unsigned(r)) mod unsigned(n));
                elsif calc_type = 2 then
                    a <= C_bar;
                    b <= C_bar;
                elsif calc_type = 3 then
                    a <= M_bar;
                    b <= C_bar;
                else
                    state <= ST_IDLE; -- this state cant happen
                end if;

                if monpro_out_valid = '1' then -- monpro no longer waiting for input
                    state <= ST_CALC; -- lets get the calculation
                end if;
                -- 0 --> M_bar <= monpro(M,(r*r)%n)
                -- 1 --> C_bar <= monpro(1,(r*r)%n)
                -- 2 --> C_bar <= monpro(C_bar, C_bar)
                -- 3 --> C_bar <= monpro(M_bar, C_bar)

            ---------------------------    
          	when ST_CALC =>
            ---------------------------
                v_out_ready := '0';
                v_out_valid := '0';

                monpro_in_ready <= '1';
                monpro_in_valid <= '0';

                if calc_type = 0 then
                    M_bar <= monpro_data;

                elsif calc_type = 1 then
                    C_bar <= monpro_data;

                elsif calc_type = 2 then
                    C_bar <= monpro_data;

                elsif calc_type = 3 then
                    C_bar <= monpro_data;

                else
                    state <= ST_IDLE; -- can not happen
                end if;
                -- 0 --> M_bar <= monpro(1,(r*r)%n)
                -- 1 --> C_bar <= monpro(1,(r*r)%n)
                -- 2 --> C_bar <= monpro(C_bar, C_bar)
                -- 3 --> C_bar <= monpro(M_bar, C_bar)


                -- check next calc type
                if calc_type < 2 then
                    calc_type <= calc_type + 1;

                elsif calc_type = 2 and key(C_block_size - to_integer(loop_counter)) = '1' then
                    calc_type <= calc_type + 1;

                elsif calc_type = 3 then
                    calc_type <= calc_type - 1;-- go back in the loop
                    loop_counter <= loop_counter + 1;

                else
                    calc_type <= calc_type; -- no change in calc type
                    loop_counter <= loop_counter + 1; 
                    
                end if;

                -- is the calculation done ?
                if loop_counter >= C_block_size then
                    state <= ST_HOLD;
                else
                    state <= ST_LOAD;
                end if;


            when ST_HOLD =>
                v_out_ready := '0';
                v_out_valid := '1';

                if ready_in = '1' then
                    state <= ST_IDLE; --is this change to fast?
                end if;
                
            ---------------------------
        	end case;
            valid_out <= v_out_valid;
            ready_out <= v_out_ready;


      	end if;
    end process;



end architecture ;