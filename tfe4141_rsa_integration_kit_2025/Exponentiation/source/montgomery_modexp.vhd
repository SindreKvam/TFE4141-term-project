library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity montgomery_modexp is
  
  generic(
        GC_DATA_WIDTH : positive := 32
    );

  port (
    clk : in std_logic;

    --left side of my drawing--
    --logic--
    reset_n : in std_logic;
    valid_in : in std_logic;
    ready_out : out std_logic;

    --incoming signals--
    M : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    e : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    n : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    n_prime : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    r : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);


    --right side of my drawing--
    valid_out : out std_logic;
    ready_in : in std_logic;
    result : out std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := (others => '0')
  ) ;
end montgomery_modexp ; 

architecture rtl of montgomery_modexp is
    -- make finite state machine
    type FSM is (ST_IDLE, ST_CALC_M_BAR, ST_CALC_X_BAR_0, ST_CALC_X_BAR_1, ST_HOLD);
    signal state : FSM;

    --make internal signals
    signal a : std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    signal b : std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    signal M_bar : std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    signal x_bar : std_logic_vector(GC_DATA_WIDTH - 1 downto 0);

	signal s_calc_counter : unsigned(7 downto 0);

    --monpro logic--
    signal monpro_in_valid : std_logic;
    signal monpro_in_ready : std_logic;
    signal monpro_out_valid : std_logic;
    signal monpro_out_ready : std_logic;
    signal monpro_data : std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    
begin
    --include montgomery monpro--
    monpro : entity work.montgomery_monpro
    port map(
            clk => clk,
            rst_n => reset_n,
            --------------------------------------------------
            in_valid => monpro_in_valid,
            in_ready => monpro_in_ready,
            out_valid => monpro_out_valid,
            out_ready => monpro_out_ready,
            --------------------------------------------------
            a => a,
            b => b,
            --------------------------------------------------
            n => n,
            n_prime => n_prime,
            --------------------------------------------------
            u => monpro_data
        );
    --starting process--
    modexp_proc : process(clk)

        variable v_in_valid : std_logic; --temporary monpro in valid
        variable v_out_ready : std_logic; --variables are serial not concurrent--

    begin
        v_in_valid := '0';
        v_out_ready := '0';

    	if reset_n = '0' then
        	result <= (others => '0');
			s_calc_counter <= (others => '0'); --resets counter--

      	elsif rising_edge(clk) then
            s_calc_counter <= s_calc_counter + 1;
            --finite state machine--
        	case state is
          	---------------------------
          	when ST_IDLE =>
          	---------------------------
            	if valid_in = '1' then
              		state <= ST_CALC_M_BAR;
            	end if;
          	---------------------------
          	when ST_CALC_M_BAR =>
          	---------------------------
            	a <= M;
            	b <= STD_LOGIC_VECTOR((unsigned(r) * unsigned(r)) mod unsigned(n));
                if s_calc_counter >= 2 then
                    v_in_valid := '1';
                end if;
            	if monpro_in_ready = '1' then
                    monpro_in_valid <= '0';
				end if;
          	---------------------------
          	when ST_CALC_X_BAR_0 =>
          	---------------------------
          	---------------------------
          	when ST_CALC_X_BAR_1 =>
          	---------------------------
        	end case;
            

      	end if;
    end process;



end architecture ;