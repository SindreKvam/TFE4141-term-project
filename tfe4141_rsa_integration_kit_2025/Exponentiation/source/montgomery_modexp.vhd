library ieee;
use ieee.std_logic_1164.all;

entity montgomery_modexp is
    generic(
        block_size = 128
    );
    