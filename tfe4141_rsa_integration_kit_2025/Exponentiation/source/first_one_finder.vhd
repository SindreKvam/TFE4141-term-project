library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

use work.montgomery_pkg.all;

entity first_one_finder is
    generic (
        C_block_size : integer := 16;
        C_block_size_log2 : integer := 4
    );
    port (
        clk : in STD_LOGIC;
        reset_n : in STD_LOGIC;
        data : in STD_LOGIC_VECTOR(C_block_size - 1 downto 0);

        --output
        first_one_index : out STD_LOGIC_VECTOR(C_block_size_log2 - 1 downto 0);

        --handshake signals
        in_ready : out STD_LOGIC;
        in_valid : in STD_LOGIC;

        out_ready : in STD_LOGIC;
        out_valid : out STD_LOGIC
    );
end first_one_finder;

architecture rtl of first_one_finder is
    --make fsm
    type FSM is (ST_IDLE, ST_LOOP, ST_FINISHED);
    signal state : FSM := ST_IDLE;

    signal s_data : STD_LOGIC_VECTOR(C_block_size - 1 downto 0);
    signal s_index : unsigned(C_block_size_log2 - 1 downto 0);

    --handshake signals
    signal s_in_ready : STD_LOGIC;
    signal s_in_valid : STD_LOGIC;

    signal s_out_ready : STD_LOGIC;
    signal s_out_valid : STD_LOGIC;

begin
    first_one_finder_proc: process(clk, reset_n)
    variable count : integer := C_block_size;

begin
    s_out_valid <= '0'; 
    s_in_ready <= '1';

    if reset_n = '0' then
        s_index <= (others => '1'); --set index to leftmost bit
        s_out_valid <= '0';
        s_in_ready <= '1';

        first_one_index <= (others => '0');

    elsif rising_edge(clk) then
        -------------------------------
            --fsm implementation--
        -------------------------------
        case state is 
        
        when ST_IDLE =>
            out_valid <= '0';
            s_index <= (others => '1');

            if in_valid = '1' then 
                state <= ST_LOOP;
                in_ready <= '0';
            else 
                state <= ST_IDLE;
                in_ready <= '1'; 
            end if;

        when ST_LOOP =>
            in_ready <= '0';

            if data(to_integer(s_index)) = '1' then
                s_data <= s_data;

                state <= ST_FINISHED;
                out_valid <= '1'; 
                first_one_index <= std_logic_vector(s_index);

            else 
                s_data <= s_data(C_block_size - 2 downto 0) & '0'; --shift all bits left

                state <= ST_LOOP;
                out_valid <= '0'; 
                s_index <= s_index - 1;
            end if;

        when ST_FINISHED =>
            if out_ready = '1' then
                state <= ST_IDLE;
                in_ready <= '1';
                out_valid <= '0';  
            else 
                state <= ST_FINISHED;
                in_ready <= '0'; 
                out_valid <= '1'; 
            end if;

        when others =>
            state <= ST_IDLE;
            s_in_ready <= '1';

        end case;

    end if;

end process first_one_finder_proc;

end rtl;