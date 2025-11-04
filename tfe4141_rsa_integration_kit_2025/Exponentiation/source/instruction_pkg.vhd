-- This file has been generated using a python script,
-- please do not make any modifications to this file directly.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package instruction_pkg is

    constant C_NUMBER_OF_INSTRUCTIONS : integer := 33;
    constant C_INSTRUCTION_LENGTH : integer := 16;

    type T_INSTRUCTION_SET is array(0 to C_NUMBER_OF_INSTRUCTIONS - 1) of std_logic_vector(C_INSTRUCTION_LENGTH - 1 downto 0);

    constant C_INSTRUCTION_SET : T_INSTRUCTION_SET := (
        b"0000000000000000",
        b"0111110001001001",
        b"1011110001001001",
        b"0000000000000010",
        b"0111110001001101",
        b"1011110001001101",
        b"0000000000010010",
        b"0111110001101101",
        b"1011110101101101",
        b"0000001010010010",
        b"0111111101101101",
        b"1011111101101101",
        b"0000001010010010",
        b"0111111101101101",
        b"1011111101101101",
        b"0000001010010010",
        b"0111111101101101",
        b"1011111101101101",
        b"0000001010010010",
        b"0111111101101101",
        b"1011111101101101",
        b"0000001010010010",
        b"0111111101101101",
        b"1011111101101101",
        b"0000001010010010",
        b"0111111101101101",
        b"1011111101101101",
        b"0000001010010010",
        b"0111111101101101",
        b"1011111101101101",
        b"0000001010010010",
        b"0111111101101101",
        b"1011111101101101"
    );

end package instruction_pkg;

package body instruction_pkg is
end package body instruction_pkg;
