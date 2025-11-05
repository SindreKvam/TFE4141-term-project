library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;
use work.instruction_pkg.all;

entity montgomery_monpro_cios_systolic_array is
    generic(
        GC_DATA_WIDTH : integer := C_DATA_WIDTH;
        GC_LIMB_WIDTH : integer := C_LIMB_WIDTH;
        GC_NUM_LIMBS  : integer := C_NUM_LIMBS;
        GC_NUM_ALPHA  : integer := C_NUM_ALPHA;
        GC_NUM_GAMMA  : integer := C_NUM_GAMMA
    );
    port (
        clk : in std_logic;
        rst_n : in std_logic;
    --------------------------------------------------
    -- Control signals
    --------------------------------------------------
        in_valid : in std_logic;
        in_ready : out std_logic := '0';
        out_valid : out std_logic := '0';
        out_ready : in std_logic;
    --------------------------------------------------
    -- Values to be multiplicated
    --------------------------------------------------
        a : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
        b : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    --------------------------------------------------
        n : in std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
        n_prime : in std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    --------------------------------------------------
    -- Outputs
    --------------------------------------------------
        u : out std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := (others => '0')
   );
end entity montgomery_monpro_cios_systolic_array;


architecture rtl of montgomery_monpro_cios_systolic_array is

    --------------------------------------------------
    -- Limb arrays to store input signals
    --------------------------------------------------
    type T_LIMBS_ARRAY is array(0 to GC_NUM_LIMBS - 1) of std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal s_a : T_LIMBS_ARRAY := (others => (others => '0'));
    signal s_b : T_LIMBS_ARRAY := (others => (others => '0'));
    signal s_n : T_LIMBS_ARRAY := (others => (others => '0'));
    signal s_n_prime : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0) := (others => '0'); -- for CIOS we only need the first part of n_prime


    --------------------------------------------------
    -- Alpha module signals
    --------------------------------------------------
    type T_ALPHA_SIGNALS is array(0 to GC_NUM_ALPHA - 1) of std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal in_alpha_a : T_ALPHA_SIGNALS := (others => (others => '0'));
    signal in_alpha_b : T_ALPHA_SIGNALS := (others => (others => '0'));
    signal in_alpha_carry : T_ALPHA_SIGNALS := (others => (others => '0'));
    signal in_alpha_sum : T_ALPHA_SIGNALS := (others => (others => '0'));
    signal out_alpha_carry : T_ALPHA_SIGNALS := (others => (others => '0'));
    signal out_alpha_sum : T_ALPHA_SIGNALS := (others => (others => '0'));


    --------------------------------------------------
    -- Gamma module signals
    --------------------------------------------------
    type T_GAMMA_SIGNALS is array(0 to GC_NUM_GAMMA - 1) of std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal in_gamma_n : T_GAMMA_SIGNALS := (others => (others => '0'));
    signal in_gamma_m : T_GAMMA_SIGNALS := (others => (others => '0'));
    signal in_gamma_carry : T_GAMMA_SIGNALS := (others => (others => '0'));
    signal in_gamma_sum : T_GAMMA_SIGNALS := (others => (others => '0'));
    signal out_gamma_carry : T_GAMMA_SIGNALS := (others => (others => '0'));
    signal out_gamma_sum : T_GAMMA_SIGNALS := (others => (others => '0'));


    --------------------------------------------------
    -- Beta module signals
    --------------------------------------------------
    signal in_beta_sum : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal in_beta_n_0 : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal in_beta_n_0_prime : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal out_beta_m : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0) := (others => '0');
    signal out_beta_carry : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0) := (others => '0');


    --------------------------------------------------
    -- Alpha final module signals
    --------------------------------------------------
    signal in_alpha_final_carry : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal in_alpha_final_sum : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal out_alpha_final_carry : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal out_alpha_final_sum : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);


    --------------------------------------------------
    -- Gamma final module signals
    --------------------------------------------------
    signal in_gamma_final_carry : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal in_gamma_final_sum_1 : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal in_gamma_final_sum_2 : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal out_gamma_final_sum_1 : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal out_gamma_final_sum_2 : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);


    --------------------------------------------------
    -- Finite State Machine
    --------------------------------------------------
    type T_FSM is (ST_IDLE, ST_CALC, ST_HOLD); -- Calc is short for Calculate btw.
    signal state : T_FSM := ST_IDLE;


    --------------------------------------------------
    -- Instruction set
    --------------------------------------------------
    signal instruction_set : T_INSTRUCTION_SET := C_INSTRUCTION_SET;
    signal instruction : std_logic_vector(C_INSTRUCTION_LENGTH - 1 downto 0);

    subtype mux_alpha_1_carry_input is std_logic_vector(0 downto 0);
    subtype mux_alpha_1_sum_input is std_logic_vector(2 downto 1);

    subtype mux_alpha_2_carry_input is std_logic_vector(3 downto 3);
    subtype mux_alpha_2_sum_input is std_logic_vector(5 downto 4);

    subtype mux_alpha_3_carry_input is std_logic_vector(6 downto 6);
    subtype mux_alpha_3_sum_input is std_logic_vector(8 downto 7);

    subtype mux_alpha_final_sum_input is std_logic_vector(9 downto 9);

    subtype mux_gamma_2_carry_input is std_logic_vector(10 downto 10);
    subtype mux_gamma_2_sum_input is std_logic_vector(11 downto 11);

    subtype mux_gamma_3_carry_input is std_logic_vector(12 downto 12);
    subtype mux_gamma_3_sum_input is std_logic_vector(13 downto 13);

    subtype mux_alpha_a_input is std_logic_vector(15 downto 14);
    subtype mux_gamma_n_input is std_logic_vector(17 downto 16);

    signal instruction_counter : integer range 0 to C_NUMBER_OF_INSTRUCTIONS - 1 := 0;

    signal alpha_1_b_counter : integer range 0 to GC_NUM_LIMBS - 1 := 0;
    signal alpha_2_b_counter : integer range 0 to GC_NUM_LIMBS - 1 := 0;
    signal alpha_3_b_counter : integer range 0 to GC_NUM_LIMBS - 1 := 0;


    type T_BETA_M is array(0 to GC_NUM_LIMBS - 1) of std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal beta_m : T_BETA_M := (others => (others => '0'));
    signal active_beta_counter : integer range 0 to GC_NUM_LIMBS - 1 := 0;

    signal gamma_1_beta_m_counter : integer range 0 to GC_NUM_LIMBS - 1 := 0;
    signal gamma_2_beta_m_counter : integer range 0 to GC_NUM_LIMBS - 1 := 0;
    signal gamma_3_beta_m_counter : integer range 0 to GC_NUM_LIMBS - 1 := 0;


    --------------------------------------------------
    -- Intermediate results
    --------------------------------------------------
    signal t : T_INTERMEDIATE_ARRAY := (others => (others => '0'));
    signal capture : std_logic := '0';
    signal capture_counter : integer range 0 to GC_NUM_LIMBS - 1 := 0;

begin


    --------------------------------------------------
    -- Main process
    --------------------------------------------------
    monpro_proc: process(clk, rst_n)

        variable v_out_valid : std_logic;
        variable v_in_ready : std_logic;
        variable v_capture : std_logic;

    begin

        --------------------------------------------------
        -- If reset is set
        --------------------------------------------------
        if rst_n = '0' then
        --------------------------------------------------

            -- Reset loaded input values
            s_a <= (others => (others => '0'));
            s_b <= (others => (others => '0'));
            s_n <= (others => (others => '0'));
            s_n_prime <= (others => '0');

            -- Reset state machine
            state <= ST_IDLE;

            -- Reset counters
            instruction_counter <= 0;

            alpha_1_b_counter <= 0;
            alpha_2_b_counter <= 0;
            alpha_3_b_counter <= 0;

            active_beta_counter <= 0;

            gamma_1_beta_m_counter <= 0;
            gamma_2_beta_m_counter <= 0;
            gamma_3_beta_m_counter <= 0;

            -- Reset output
            u <= (others => '0');

        --------------------------------------------------
        elsif rising_edge(clk) then
        --------------------------------------------------

            -- Reset all variables
            v_out_valid := '0';
            v_in_ready := '0';
            v_capture := '0';

            --------------------------------------------------
            -- Finite State Machine
            --------------------------------------------------
            case state is
                --------------------------------------------------
                -- Wait for input data to be valid
                -- Once valid, load input values to registers.
                --------------------------------------------------
                when ST_IDLE =>
                --------------------------------------------------
                    v_in_ready := '1';

                    if in_valid = '1' then

                        -- Load input to registers
                        for i in 0 to GC_NUM_LIMBS - 1 loop
                            s_a(i) <= a((GC_LIMB_WIDTH + (i * GC_LIMB_WIDTH) - 1) downto (i * GC_LIMB_WIDTH));
                            s_b(i) <= b((GC_LIMB_WIDTH + (i * GC_LIMB_WIDTH) - 1) downto (i * GC_LIMB_WIDTH));
                            s_n(i) <= n((GC_LIMB_WIDTH + (i * GC_LIMB_WIDTH) - 1) downto (i * GC_LIMB_WIDTH));
                        end loop;

                        s_n_prime <= n_prime;

                        -- Reset counters to be used
                        instruction_counter <= 1;
                        alpha_1_b_counter <= 0;
                        alpha_2_b_counter <= 0;
                        alpha_3_b_counter <= 0;

                        active_beta_counter <= 0;
                        gamma_1_beta_m_counter <= 0;
                        gamma_2_beta_m_counter <= 0;
                        gamma_3_beta_m_counter <= 0;

                        instruction <= instruction_set(0);

                        state <= ST_CALC;

                    end if;

                --------------------------------------------------
                when ST_CALC =>
                --------------------------------------------------

                    --------------------------------------------------
                    -- Go through the entire instruction set
                    --------------------------------------------------
                    instruction <= instruction_set(instruction_counter);

                    if instruction_counter >= C_NUMBER_OF_INSTRUCTIONS - 1 then
                        state <= ST_HOLD;
                        instruction_counter <= 0;
                        v_out_valid := '1';
                    else
                        instruction_counter <= instruction_counter + 1;
                    end if;

                    --------------------------------------------------
                    -- Handle the counter for the input b
                    --------------------------------------------------
                    if instruction_counter mod 3 = 0 and instruction_counter /= 0 then

                        if alpha_1_b_counter < GC_NUM_LIMBS - 1 then
                            alpha_1_b_counter <= alpha_1_b_counter + 1;
                        end if;

                        if alpha_1_b_counter >= 1 and alpha_2_b_counter < GC_NUM_LIMBS - 1 then
                            alpha_2_b_counter <= alpha_2_b_counter + 1;
                        end if;

                        if alpha_2_b_counter >= 1 and alpha_3_b_counter < GC_NUM_LIMBS - 1 then
                            alpha_3_b_counter <= alpha_3_b_counter + 1;
                        end if;

                    end if;

                    --------------------------------------------------
                    -- Handle the counters to store beta_m values
                    --------------------------------------------------
                    if instruction_counter mod 3 = 0 and instruction_counter /= 0 and active_beta_counter <= GC_NUM_LIMBS - 1 then

                        beta_m(active_beta_counter) <= out_beta_m;

                        if active_beta_counter < GC_NUM_LIMBS then
                            active_beta_counter <= active_beta_counter + 1;
                        end if;

                    end if;

                    --------------------------------------------------
                    -- Handle the gamma_beta_m counters
                    --------------------------------------------------
                    if instruction_counter mod 3 = 0 and instruction_counter > 3 then

                        if gamma_1_beta_m_counter < GC_NUM_LIMBS - 1 then
                            gamma_1_beta_m_counter <= gamma_1_beta_m_counter + 1;
                        end if;

                        if gamma_2_beta_m_counter >= 1 and gamma_2_beta_m_counter < GC_NUM_LIMBS - 1 then
                            gamma_2_beta_m_counter <= gamma_2_beta_m_counter + 1;
                        end if;

                        if gamma_3_beta_m_counter >= 1 and gamma_3_beta_m_counter < GC_NUM_LIMBS - 1 then
                            gamma_3_beta_m_counter <= gamma_3_beta_m_counter + 1;
                        end if;

                    end if;

                    --------------------------------------------------
                    -- Handle when to capture the values that should be on the output
                    --------------------------------------------------
                    if instruction_counter >= C_NUMBER_OF_INSTRUCTIONS - 9 then
                        v_capture := '1';
                    end if;


                --------------------------------------------------
                when ST_HOLD =>
                --------------------------------------------------

                    v_out_valid := '1';

                    if out_ready = '1' then
                        state <= ST_IDLE;
                        v_out_valid := '0';
                    end if;

                --------------------------------------------------
                when others => state <= ST_IDLE;
                --------------------------------------------------
            end case;
            
            out_valid <= v_out_valid;
            in_ready <= v_in_ready;
            capture <= v_capture;

            for i in 0 to GC_NUM_LIMBS - 1 loop
                u(GC_LIMB_WIDTH + GC_LIMB_WIDTH * i - 1 downto GC_LIMB_WIDTH * i) <= t(i);
            end loop;
            
        end if; -- rising_edge
    end process monpro_proc;


    --------------------------------------------------
    -- Capture output
    --------------------------------------------------
    p_capture_output: process(clk)
    begin

        if rising_edge(clk) then

            if rst_n = '0' then

                capture_counter <= 0;
            
            else

                case capture_counter is
                    when 0 => t(0) <= out_gamma_sum(0);
                    when 1 => t(1) <= out_gamma_sum(1);
                    when 2 => t(2) <= out_gamma_sum(1);
                    when 3 => t(3) <= out_gamma_sum(1);
                    when 4 => t(4) <= out_gamma_sum(2);
                    when 5 => t(5) <= out_gamma_sum(2);
                    when 6 => t(6) <= out_gamma_sum(2);
                    when 7 => 
                        t(7) <= out_gamma_final_sum_1;
                        t(8) <= out_gamma_final_sum_2;
                    when others =>
                end case;

                if capture = '1' then
                    capture_counter <= capture_counter + 1;
                end if;

                if capture_counter > GC_NUM_LIMBS - 1 then
                    capture_counter <= 0;
                end if;

            end if;

        end if;

    end process p_capture_output;

    --------------------------------------------------
    -- Mux for alpha 1
    --------------------------------------------------
    p_alpha_1_input_mux: process(all)
    begin

        in_alpha_b(0) <= s_b(alpha_1_b_counter);

        case instruction(mux_alpha_1_carry_input'range) is
            when "0" => in_alpha_carry(0) <= (others => '0');
            when "1" => in_alpha_carry(0) <= out_alpha_carry(0);
            when others =>
        end case;

        case instruction(mux_alpha_1_sum_input'range) is
            when "00" => in_alpha_sum(0) <= (others => '0');
            when "01" => in_alpha_sum(0) <= out_gamma_sum(0);
            when "10" => in_alpha_sum(0) <= out_gamma_sum(1);
            when others => in_alpha_sum(0) <= (others => '0');
        end case;

        case instruction(mux_alpha_a_input'range) is
            when "00" => in_alpha_a(0) <= s_a(0);
            when "01" => in_alpha_a(0) <= s_a(1);
            when "10" => in_alpha_a(0) <= s_a(2);
            when others => in_alpha_a(0) <= (others => '0');
        end case;

    end process p_alpha_1_input_mux;


    --------------------------------------------------
    -- Mux for second alpha module
    --------------------------------------------------
    p_alpha_2_input_mux: process(all)
    begin

        in_alpha_b(1) <= s_b(alpha_2_b_counter);

        case instruction(mux_alpha_2_carry_input'range) is
            when "0" => in_alpha_carry(1) <= out_alpha_carry(0);
            when "1" => in_alpha_carry(1) <= out_alpha_carry(1);
            when others =>
        end case;

        case instruction(mux_alpha_2_sum_input'range) is
            when "00" => in_alpha_sum(1) <= (others => '0');
            when "01" => in_alpha_sum(1) <= out_gamma_sum(1);
            when "10" => in_alpha_sum(1) <= out_gamma_sum(2);
            when others => in_alpha_sum(1) <= (others => '0');
        end case;

        case instruction(mux_alpha_a_input'range) is
            when "00" => in_alpha_a(1) <= s_a(3);
            when "01" => in_alpha_a(1) <= s_a(4);
            when "10" => in_alpha_a(1) <= s_a(5);
            when others => in_alpha_a(1) <= (others => '0');
        end case;

    end process p_alpha_2_input_mux;


    --------------------------------------------------
    -- Mux for last alpha module
    --------------------------------------------------
    p_alpha_3_input_mux: process(all)
    begin

        in_alpha_b(2) <= s_b(alpha_3_b_counter);
        
        case instruction(mux_alpha_3_carry_input'range) is
            when "0" => in_alpha_carry(2) <= out_alpha_carry(1);
            when "1" => in_alpha_carry(2) <= out_alpha_carry(2);
            when others =>
        end case;

        case instruction(mux_alpha_3_sum_input'range) is
            when "00" => in_alpha_sum(2) <= (others => '0');
            when "01" => in_alpha_sum(2) <= out_gamma_sum(2);
            when "10" => in_alpha_sum(2) <= out_gamma_final_sum_1;
            when others => in_alpha_sum(2) <= (others => '0');
        end case;

        case instruction(mux_alpha_a_input'range) is
            when "00" => in_alpha_a(2) <= s_a(6);
            when "01" => in_alpha_a(2) <= s_a(7);
            when others => in_alpha_a(2) <= (others => '0');
        end case;

    end process p_alpha_3_input_mux;

    
    --------------------------------------------------
    -- Mux for alpha final
    --------------------------------------------------
    p_alpha_final_input_mux: process(all)
    begin

        in_alpha_final_carry <= out_alpha_carry(GC_NUM_ALPHA - 1);

        case instruction(mux_alpha_final_sum_input'range) is
            when "0" => in_alpha_final_sum <= (others => '0');
            when "1" => in_alpha_final_sum <= out_gamma_final_sum_2;
            when others =>
        end case;

    end process p_alpha_final_input_mux;


    --------------------------------------------------
    -- Mux for gamma 1
    --------------------------------------------------
    p_gamma_1_input_mux: process(all)
    begin
        
        in_gamma_n(0) <= s_n(1);
        in_gamma_m(0) <= out_beta_m;

        in_gamma_carry(0) <= out_beta_carry;
        in_gamma_sum(0) <= out_alpha_sum(0);

    end process p_gamma_1_input_mux;

    
    --------------------------------------------------
    -- Mux for gamma 2
    --------------------------------------------------
    p_gamma_2_input_mux: process(all)
    begin
        
        in_gamma_m(1) <= beta_m(gamma_2_beta_m_counter);

        case instruction(mux_gamma_2_carry_input'range) is
            when "0" => in_gamma_carry(1) <= out_gamma_carry(0);
            when "1" => in_gamma_carry(1) <= out_gamma_carry(1);
            when others =>
        end case;

        case instruction(mux_gamma_2_sum_input'range) is
            when "0" => in_gamma_sum(1) <= out_alpha_sum(0);
            when "1" => in_gamma_sum(1) <= out_alpha_sum(1);
            when others =>
        end case;

        case instruction(mux_gamma_n_input'range) is
            when "00" => in_gamma_n(1) <= s_n(2);
            when "01" => in_gamma_n(1) <= s_n(3);
            when "10" => in_gamma_n(1) <= s_n(4);
            when others => in_gamma_n(1) <= (others => '0');
        end case;

    end process p_gamma_2_input_mux;


    --------------------------------------------------
    -- Mux for the last gamma module
    --------------------------------------------------
    p_gamma_3_input_mux: process(all)
    begin
        
        in_gamma_m(2) <= beta_m(gamma_3_beta_m_counter);

        case instruction(mux_gamma_3_carry_input'range) is
            when "0" => in_gamma_carry(2) <= out_gamma_carry(1);
            when "1" => in_gamma_carry(2) <= out_gamma_carry(2);
            when others =>
        end case;

        case instruction(mux_gamma_3_sum_input'range) is
            when "0" => in_gamma_sum(2) <= out_alpha_sum(1);
            when "1" => in_gamma_sum(2) <= out_alpha_sum(2);
            when others =>
        end case;

        case instruction(mux_gamma_n_input'range) is
            when "00" => in_gamma_n(2) <= s_n(5);
            when "01" => in_gamma_n(2) <= s_n(6);
            when "10" => in_gamma_n(2) <= s_n(7);
            when others => in_gamma_n(2) <= (others => '0');
        end case;

    end process p_gamma_3_input_mux;


    --------------------------------------------------
    -- Mux for gamma final
    --------------------------------------------------
    p_gamma_final_input_mux: process(all)
    begin
        
        in_gamma_final_carry <= out_gamma_carry(GC_NUM_GAMMA - 1);
        in_gamma_final_sum_1 <= out_alpha_final_sum;
        in_gamma_final_sum_2 <= out_alpha_final_carry;

    end process p_gamma_final_input_mux;


    --------------------------------------------------
    -- Mux for beta
    --------------------------------------------------
    p_beta_input_mux: process(all)
    begin

        in_beta_sum <= out_alpha_sum(0);
        in_beta_n_0 <= s_n(0);
        in_beta_n_0_prime <= s_n_prime;

    end process p_beta_input_mux;


    --------------------------------------------------
    -- Instantiate all processing elements
    --------------------------------------------------
    g_alpha_modules: for i in 0 to GC_NUM_ALPHA - 1 generate
        i_alpha: entity work.alpha(rtl)
            generic map(
                GC_LIMB_WIDTH => GC_LIMB_WIDTH
            )
            port map(
                clk => clk,
                rst_n => rst_n,
                a => in_alpha_a(i),
                b => in_alpha_b(i),
                carry_in => in_alpha_carry(i),
                sum_in => in_alpha_sum(i),
                alpha_carry => out_alpha_carry(i),
                alpha_sum => out_alpha_sum(i)
            );
    end generate;
    --------------------------------------------------

    --------------------------------------------------
    g_gamma_modules: for i in 0 to GC_NUM_GAMMA - 1 generate
        i_gamma: entity work.gamma(rtl)
            generic map(
                GC_LIMB_WIDTH => GC_LIMB_WIDTH
            )
            port map(
                clk => clk,
                rst_n => rst_n,
                n_i => in_gamma_n(i),
                m => in_gamma_m(i),
                carry_in => in_gamma_carry(i),
                sum_in => in_gamma_sum(i),
                gamma_carry => out_gamma_carry(i),
                gamma_sum => out_gamma_sum(i)
            );
    end generate;
    --------------------------------------------------

    --------------------------------------------------
    i_beta: entity work.beta(rtl)
        generic map(
            GC_LIMB_WIDTH => GC_LIMB_WIDTH
        )
        port map(
            clk => clk,
            rst_n => rst_n,
            sum_in => in_beta_sum,
            n_0 => in_beta_n_0,
            n_0_prime => in_beta_n_0_prime,
            m => out_beta_m,
            beta_carry => out_beta_carry
        );
    --------------------------------------------------

    --------------------------------------------------
    i_alpha_final: entity work.alpha_final(rtl)
        generic map(
            GC_LIMB_WIDTH => GC_LIMB_WIDTH
        )
        port map(
            clk => clk,
            rst_n => rst_n,
            carry_in => in_alpha_final_carry,
            sum_in => in_alpha_final_sum,
            alpha_carry => out_alpha_final_carry,
            alpha_sum => out_alpha_final_sum
        );
    --------------------------------------------------

    --------------------------------------------------
    i_gamma_final: entity work.gamma_final(rtl)
        generic map(
            GC_LIMB_WIDTH => GC_LIMB_WIDTH
        )
        port map(
            clk => clk,
            rst_n => rst_n,
            carry_in => in_gamma_final_carry,
            sum_1_in => in_gamma_final_sum_1,
            sum_2_in => in_gamma_final_sum_2,
            gamma_sum_1 => out_gamma_final_sum_1,
            gamma_sum_2 => out_gamma_final_sum_2
        );
    --------------------------------------------------
    
end architecture rtl;
