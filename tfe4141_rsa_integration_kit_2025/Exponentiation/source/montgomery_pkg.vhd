library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package montgomery_pkg is
    
    --------------------------------------------------
    -- Constants
    --------------------------------------------------
    constant C_DATA_WIDTH : integer := 256;
    constant C_LIMB_WIDTH : integer := 16;
    constant C_NUM_LIMBS  : integer := 16;
    constant C_NUM_ALPHA  : integer := 6;
    constant C_NUM_GAMMA  : integer := 6;

    --------------------------------------------------
    -- Data types
    --------------------------------------------------
    type T_INTERMEDIATE_ARRAY is array(0 to C_NUM_LIMBS + 1) of std_logic_vector(C_LIMB_WIDTH - 1 downto 0);
    type T_CARRY_SUM_ARRAY is array(0 to 1) of std_logic_vector(C_LIMB_WIDTH - 1 downto 0);

    --------------------------------------------------
    -- Function declarations
    --------------------------------------------------
    pure function carry_sum(
        a : in std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
        x : in std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
        y : in std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
        b : in std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0'))
    return T_CARRY_SUM_ARRAY;

    
end package montgomery_pkg;

package body montgomery_pkg is
    
    --------------------------------------------------
    -- Carry sum function
    --------------------------------------------------
    pure function carry_sum(
        a : in std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
        x : in std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
        y : in std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0');
        b : in std_logic_vector(C_LIMB_WIDTH - 1 downto 0) := (others => '0'))
    return T_CARRY_SUM_ARRAY is 

        variable v_carry_sum_result : std_logic_vector(C_LIMB_WIDTH * 2 - 1 downto 0);
        variable v_carry_sum_array : T_CARRY_SUM_ARRAY := (others => (others => '0'));

    begin

        v_carry_sum_result := std_logic_vector(unsigned(a) + unsigned(x) * unsigned(y) + unsigned(b));


        v_carry_sum_array(0) := v_carry_sum_result(C_LIMB_WIDTH * 2 - 1 downto C_LIMB_WIDTH);
        v_carry_sum_array(1) := v_carry_sum_result(C_LIMB_WIDTH - 1 downto 0);

        return v_carry_sum_array;
    end function carry_sum;
    
end package body montgomery_pkg;
