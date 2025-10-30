library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.montgomery_pkg.all;

entity montgomery_monpro_cios_small is
    generic(
        GC_DATA_WIDTH : integer := C_DATA_WIDTH;
        GC_LIMB_WIDTH : integer := C_LIMB_WIDTH;
        GC_NUM_LIMBS  : integer := C_NUM_LIMBS
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
end entity montgomery_monpro_cios_small;


architecture rtl of montgomery_monpro_cios_small is

    constant C_NUM_CLOCK_CYCLES : integer := 100;
    signal s_calc_counter : unsigned(7 downto 0);

    --------------------------------------------------
    -- Limb arrays to store input signals
    --------------------------------------------------
    type T_LIMBS_ARRAY is array(0 to GC_NUM_LIMBS - 1) of std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal s_a : T_LIMBS_ARRAY;
    signal s_b : T_LIMBS_ARRAY;
    signal s_n : T_LIMBS_ARRAY;

    signal s_n_prime : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0); -- for CIOS we only need the first part of n_prime

    --------------------------------------------------
    -- Finite State Machine
    --------------------------------------------------
    type T_FSM is (ST_IDLE, ST_CALC, ST_HOLD); -- Calc is short for Calculate btw.
    signal state : T_FSM;

begin

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

        -- Reset all variables
        v_out_valid := '0';
        v_in_ready := '0';

        v_carry_sum := (others => (others => '0'));
        v_carry := (others => '0');

        v_t := (others => (others => '0'));
        v_m := (others => '0');
        v_m_temp := (others => '0');


        --------------------------------------------------
        -- If reset is set
        --------------------------------------------------
        if rst_n = '0' then
        --------------------------------------------------

            s_calc_counter <= (others => '0');

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

                    for i in 0 to GC_NUM_LIMBS - 1 loop

                        v_carry := (others => '0');

                        for j in 0 to GC_NUM_LIMBS - 1 loop

                            v_carry_sum := carry_sum(v_t(j), s_a(j), s_b(i), v_carry);
                            v_carry := v_carry_sum(0);
                            v_t(j) := v_carry_sum(1);

                        end loop;

                        v_carry_sum := carry_sum(v_t(GC_NUM_LIMBS), (others=>'0'), (others => '0'), v_carry);
                        v_t(GC_NUM_LIMBS + 1) := v_carry_sum(0);
                        v_t(GC_NUM_LIMBS) := v_carry_sum(1);

                        v_carry := (others => '0');
                        v_m_temp := std_logic_vector(unsigned(v_t(0)) * unsigned(s_n_prime));
                        v_m := v_m_temp(GC_NUM_LIMBS - 1 downto 0);

                        v_carry_sum := carry_sum(v_t(0), v_m, s_n(0), (others => '0'));
                        v_carry := v_carry_sum(0);

                        for j in 1 to GC_NUM_LIMBS - 1 loop

                            v_carry_sum := carry_sum(v_t(j), v_m, s_n(j), v_carry);
                            v_carry := v_carry_sum(0);
                            v_t(j-1) := v_carry_sum(1);

                        end loop;

                        v_carry_sum := carry_sum(v_t(GC_NUM_LIMBS), (others => '0'), (others => '0'), v_carry);
                        v_carry := v_carry_sum(0);
                        v_t(GC_NUM_LIMBS-1) := v_carry_sum(1);

                        v_t(GC_NUM_LIMBS) := std_logic_vector(unsigned(v_t(GC_NUM_LIMBS + 1)) + unsigned(v_carry));

                    end loop;

                    -- Handle when to go out of state
                    if s_calc_counter > C_NUM_CLOCK_CYCLES then
                        state <= ST_HOLD;
                        s_calc_counter <= (others => '0');
                    else
                        s_calc_counter <= s_calc_counter + 1;
                    end if;

                --------------------------------------------------
                when ST_HOLD =>
                --------------------------------------------------

                    v_out_valid := '1';

                    if out_ready = '1' then
                        state <= ST_IDLE;
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
    
end architecture rtl;
