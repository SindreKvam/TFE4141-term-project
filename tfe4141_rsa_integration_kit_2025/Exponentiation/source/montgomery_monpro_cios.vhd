library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity montgomery_monpro_cios is
    generic(
        GC_DATA_WIDTH : integer := 256;
        GC_LIMB_WIDTH : integer := 16;
        GC_NUM_LIMBS  : integer := 16
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
end entity montgomery_monpro_cios;


architecture rtl of montgomery_monpro_cios is

    -- constant C_NUM_CALC_CYCLES : natural := 4;
    -- signal s_calc_counter : unsigned(7 downto 0);

    type T_ARRAY is array(0 to GC_NUM_LIMBS - 1) of std_logic_vector(GC_LIMB_WIDTH - 1 downto 0);
    signal input_limbs : T_ARRAY;

    -- Buffered signals for input Values
    signal s_a : T_ARRAY;--std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    signal s_b : T_ARRAY;
    signal s_n : T_ARRAY;
    signal s_n_prime : std_logic_vector(GC_LIMB_WIDTH - 1 downto 0); -- for CIOS we only need the first part of n_prime

    -- signal t : unsigned(GC_DATA_WIDTH * 2 - 1 downto 0);
    -- signal m : unsigned(GC_DATA_WIDTH - 1 downto 0);
    -- signal u_shift : unsigned(GC_DATA_WIDTH - 1 downto 0);

    type T_FSM is (ST_IDLE, ST_CALC, ST_HOLD);
    signal state : T_FSM;


begin

    monpro_proc: process(clk, rst_n)

        -- variable v_m : unsigned(GC_DATA_WIDTH * 3 - 1 downto 0) := (others => '0');
        --
        variable v_out_valid : std_logic;
        variable v_in_ready : std_logic;
        --
        -- variable v_u_pre : unsigned(GC_DATA_WIDTH * 2 - 1 downto 0) := (others => '0');

    begin

        -- v_m := (others => '0');

        v_out_valid := '0';
        v_in_ready := '0';
 
        -- v_u_pre := (others => '0');

        if rst_n = '0' then

            -- s_calc_counter <= (others => '0');

            -- Reset output
            u <= (others => '0');

        elsif rising_edge(clk) then

            -- Finite State Machine
            case state is

                --------------------------------------------------
                when ST_IDLE =>
                --------------------------------------------------
                    if in_valid = '1' then
                        -- s_calc_counter <= (others => '0');

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

                    -- t should be calculated on the first clock cycle
                    -- t <= unsigned(s_a) * unsigned(s_b);

                    -- m is calculated on the second clock cycle (dependent on t)
                    -- v_m := (t * unsigned(n_prime));
                    -- m <= v_m(GC_DATA_WIDTH - 1 downto 0);

                    -- rest is calculated on the third clock-cycle (dependent on m and t)
                    -- v_u_pre := (t + m * unsigned(n));
                    -- u_shift <= v_u_pre(v_u_pre'left downto GC_DATA_WIDTH);

                    -- Output should be ready after 4 clock cycles
                    -- -- if u_shift >= unsigned(n) then
                    --     u <= std_logic_vector(u_shift - unsigned(n));
                    -- else
                    --     u <= std_logic_vector(u_shift);
                    -- end if;
                    --
                    -- if s_calc_counter >= C_NUM_CALC_CYCLES then
                    --     state <= ST_HOLD;
                    -- end if;

                    -- s_calc_counter <= s_calc_counter + 1;

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
            
        end if; -- rising_edge
    end process monpro_proc;
    
end architecture rtl;
