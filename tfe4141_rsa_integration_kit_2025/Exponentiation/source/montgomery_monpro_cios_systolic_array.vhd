library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;

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
        in_ready : out std_logic;
        out_valid : out std_logic;
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
    signal s_a : T_LIMBS_ARRAY;
    signal s_b : T_LIMBS_ARRAY;
    signal s_n : T_LIMBS_ARRAY;
    signal s_n_prime : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0); -- for CIOS we only need the first part of n_prime


    --------------------------------------------------
    -- Alpha module signals
    --------------------------------------------------
    type T_ALPHA_SIGNALS is array(0 to GC_NUM_ALPHA - 1) of std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal in_alpha_a : T_ALPHA_SIGNALS;
    signal in_alpha_b : T_ALPHA_SIGNALS;
    signal in_alpha_carry : T_ALPHA_SIGNALS;
    signal in_alpha_sum : T_ALPHA_SIGNALS;
    signal out_alpha_carry : T_ALPHA_SIGNALS;
    signal out_alpha_sum : T_ALPHA_SIGNALS;


    --------------------------------------------------
    -- Gamma module signals
    --------------------------------------------------
    type T_GAMMA_SIGNALS is array(0 to GC_NUM_GAMMA - 1) of std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal in_gamma_n : T_GAMMA_SIGNALS;
    signal in_gamma_m : T_GAMMA_SIGNALS;
    signal in_gamma_carry : T_GAMMA_SIGNALS;
    signal in_gamma_sum : T_GAMMA_SIGNALS;
    signal out_gamma_carry : T_GAMMA_SIGNALS;
    signal out_gamma_sum : T_GAMMA_SIGNALS;


    --------------------------------------------------
    -- Beta module signals
    --------------------------------------------------
    signal in_beta_sum : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal in_beta_n_0 : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal in_beta_n_0_prime : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal out_beta_m : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal out_beta_carry : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);


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
    signal state : T_FSM;


    --------------------------------------------------
    -- Instruction set
    --------------------------------------------------
    type T_INSTRUCTION_SET is array(0 to 66) of std_logic_vector(127 downto 0);
    signal instruction : std_logic_vector(127 downto 0);

    subtype mux_alpha_carry_input is std_logic_vector(0 downto 0);
    subtype mux_alpha_sum_input is std_logic_vector(1 downto 1);

    subtype mux_alpha_final_sum_input is std_logic_vector(2 downto 2);


begin

    --------------------------------------------------
    -- Main process
    --------------------------------------------------
    monpro_proc: process(clk, rst_n)

        variable v_out_valid : std_logic;
        variable v_in_ready : std_logic;

        variable v_carry_sum : T_CARRY_SUM_ARRAY := (others=> (others => '0'));
        variable v_carry : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0) := (others => '0');

        -- Intermediate result
        variable v_t : T_INTERMEDIATE_ARRAY := (others => (others => '0'));
        variable v_m : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
        variable v_m_temp : std_logic_vector(GC_LIMB_WIDTH * 2 - 1 downto 0);

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

            -- Reset output
            u <= (others => '0');

        --------------------------------------------------
        elsif rising_edge(clk) then
        --------------------------------------------------

            -- Reset all variables
            -- v_out_valid := '0';
            -- v_in_ready := '0';
            --
            -- v_carry_sum := (others => (others => '0'));
            -- v_carry := (others => '0');
            --
            v_t := (others => (others => '0'));
            -- v_m := (others => '0');
            -- v_m_temp := (others => '0');

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
                    if in_valid = '1' then

                        -- Load input to registers
                        for i in 0 to GC_NUM_LIMBS - 1 loop
                            s_a(i) <= a((GC_LIMB_WIDTH + (i * GC_LIMB_WIDTH) - 1) downto (i * GC_LIMB_WIDTH));
                            s_b(i) <= b((GC_LIMB_WIDTH + (i * GC_LIMB_WIDTH) - 1) downto (i * GC_LIMB_WIDTH));
                            s_n(i) <= n((GC_LIMB_WIDTH + (i * GC_LIMB_WIDTH) - 1) downto (i * GC_LIMB_WIDTH));
                        end loop;

                        s_n_prime <= n_prime;

                        state <= ST_CALC;

                    else
                        v_in_ready := '1';
                    end if;

                --------------------------------------------------
                when ST_CALC =>
                --------------------------------------------------

                --     for i in 0 to GC_NUM_LIMBS - 1 loop
                --
                --         v_carry := (others => '0');
                --
                --         for j in 0 to GC_NUM_LIMBS - 1 loop
                --
                --             v_carry_sum := carry_sum(v_t(j), s_a(j), s_b(i), v_carry);
                --             v_carry := v_carry_sum(0);
                --             v_t(j) := v_carry_sum(1);
                --
                --         end loop;
                --
                --         v_carry_sum := carry_sum(v_t(GC_NUM_LIMBS), (others=>'0'), (others => '0'), v_carry);
                --         v_t(GC_NUM_LIMBS + 1) := v_carry_sum(0);
                --         v_t(GC_NUM_LIMBS) := v_carry_sum(1);
                --
                --         v_carry := (others => '0');
                --         v_m_temp := std_logic_vector(unsigned(v_t(0)) * unsigned(s_n_prime));
                --         v_m := v_m_temp(GC_NUM_LIMBS - 1 downto 0);
                --
                --         v_carry_sum := carry_sum(v_t(0), v_m, s_n(0), (others => '0'));
                --         v_carry := v_carry_sum(0);
                --
                --         for j in 1 to GC_NUM_LIMBS - 1 loop
                --
                --             v_carry_sum := carry_sum(v_t(j), v_m, s_n(j), v_carry);
                --             v_carry := v_carry_sum(0);
                --             v_t(j-1) := v_carry_sum(1);
                --
                --         end loop;
                --
                --         v_carry_sum := carry_sum(v_t(GC_NUM_LIMBS), (others => '0'), (others => '0'), v_carry);
                --         v_carry := v_carry_sum(0);
                --         v_t(GC_NUM_LIMBS-1) := v_carry_sum(1);
                --
                --         v_t(GC_NUM_LIMBS) := std_logic_vector(unsigned(v_t(GC_NUM_LIMBS + 1)) + unsigned(v_carry));
                --
                --     end loop;

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

            for i in 0 to GC_NUM_LIMBS - 1 loop
                u(GC_LIMB_WIDTH + GC_LIMB_WIDTH * i - 1 downto GC_LIMB_WIDTH * i) <= v_t(i);
            end loop;
            
        end if; -- rising_edge
    end process monpro_proc;


    
    --------------------------------------------------
    -- Mux for alpha 1
    --------------------------------------------------
    p_alpha_1_input_mux: process(all)
    begin

        -- TODO shift register for input a and b
        in_alpha_a(0) <= (others => '0');
        in_alpha_b(0) <= (others => '0');

        case instruction(mux_alpha_carry_input'range) is
            when "0" => in_alpha_carry(0) <= (others => '0');
            when "1" => in_alpha_carry(0) <= out_gamma_sum(0);
            when others =>
        end case;

        case instruction(mux_alpha_sum_input'range) is
            when "00" => in_alpha_sum(0) <= (others => '0');
            when "01" => in_alpha_sum(0) <= out_gamma_sum(0);
            when "10" => in_alpha_sum(0) <= out_gamma_sum(1);
            when others =>
        end case;
        
    end process p_alpha_1_input_mux;
    
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
        
        -- TODO shift register for n and m
        -- Do we need to keep multiple versions of m stored to use different m per limb?
        in_gamma_n(0) <= (others => '0');
        in_gamma_m(0) <= out_beta_m;

        in_gamma_carry(0) <= out_beta_carry;
        in_gamma_sum(0) <= out_alpha_sum(0);

    end process p_gamma_1_input_mux;


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
    -- Mux for last alpha
    --------------------------------------------------
    p_alpha_last_input_mux: process(all)
    begin

        

    end process p_alpha_last_input_mux;


    --------------------------------------------------
    -- Instantiate all processing elements
    --------------------------------------------------

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
                alpha_sum => out_alpha_carry(i)
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
