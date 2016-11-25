library ieee;
	use	ieee.std_logic_unsigned.all;
	use	ieee.std_logic_1164.all;
	use	ieee.numeric_std.all;
	use	ieee.math_real.all;

library work;
	use work.cnn_types.all;

--
--                    ----------------
--                   |                |
-- in_data   ________|                |______ out_data
-- in_dv     ________|                |______ out_dv
-- in_fv     ________|       SE       |______ ou_fv
--                   |    (single)    |
-- in_bias  _________|                |
--                   |                |
--                    ----------------



entity sumElement_single is

    generic(
        PIXEL_SIZE      :   integer
    );

    port(
        clk	            :	in 	std_logic;
        reset_n	        :	in	std_logic;
        enable          :	in	std_logic;
        in_data         :   in  std_logic_vector (SUM_WIDTH - 1 downto 0);
        in_dv           :   in  std_logic;
        in_fv           :   in  std_logic;
        in_bias         :   in  std_logic_vector (PIXEL_SIZE - 1 downto 0);
        out_data        :   out std_logic_vector (PIXEL_SIZE - 1 downto 0);
        out_dv          :   out std_logic;
        out_fv          :   out std_logic
    );
end entity;
--
architecture bhv of sumElement_single is

    constant THIS_SUM_WIDTH    :   integer := SUM_WIDTH;
    constant LOWER_THRESHHOLD  :   integer := -32258;
    constant UPPER_THRESHHOLD  :   integer :=  32258;
    constant LOWER_TANH_VALUE  :   integer := -127;
    constant UPPER_TANH_VALUE  :   integer :=  127;

    constant T2  :   integer := 24193;
    constant T1  :   integer := 8065;
    constant V2  :   integer := 127;
    constant V1  :   integer := 32;
    constant A1  :   integer := PIXEL_SIZE - 1;
    constant A2  :   integer := PIXEL_SIZE;

    signal  sum_s             :   signed (THIS_SUM_WIDTH-1 downto 0);
    signal  s_bias128         :   signed (THIS_SUM_WIDTH-1 downto 0);
    signal  s_bias            :   signed (2*PIXEL_SIZE-1   downto 0);
    signal  tmp_bias          :   std_logic_vector (THIS_SUM_WIDTH-1 downto 0);

    begin
    tmp_bias  <= std_logic_vector(resize(signed(in_bias), tmp_bias'length));
    -- s_bias    <= SHIFT_LEFT(signed(tmp_bias),PIXEL_SIZE-1);
    s_bias    <= signed(in_bias)*127;

    process(clk)
        variable sum          :   signed (THIS_SUM_WIDTH-1 downto 0);
    -- TODO : Overflow management

        begin
            if (reset_n ='0') then
                sum   := (others=>'0');
            elsif (RISING_EDGE(clk)) then
                if (enable='1') then
                    sum  := signed(signed(in_data) + signed(s_bias));
                    sum_s <= sum;
                    sum  := (others=>'0');
                end if;
            end if;
        end process;

    --------------------------------------------------------------------------
    -- Apply Activation function : TanH (approx)
    --------------------------------------------------------------------------

    -- out_data   <=   std_logic_vector(to_signed(LOWER_TANH_VALUE,PIXEL_SIZE))   when (sum_s < to_signed(LOWER_THRESHHOLD,THIS_SUM_WIDTH)) else
    --                 std_logic_vector(to_signed(UPPER_TANH_VALUE,PIXEL_SIZE))   when (sum_s > to_signed(UPPER_THRESHHOLD,THIS_SUM_WIDTH)) else
    --                 std_logic_vector(SHIFT_RIGHT(sum_s,PIXEL_SIZE)(PIXEL_SIZE-1 downto 0));
    --
    out_data   <=   std_logic_vector(to_signed(-V2,PIXEL_SIZE))                                                    when ( sum_s <= to_signed(-T2,THIS_SUM_WIDTH)) else
                    std_logic_vector(to_signed(-V1,PIXEL_SIZE) + (SHIFT_RIGHT(sum_s,A2)(PIXEL_SIZE-1 downto 0)))   when ((sum_s >  to_signed(-T2,THIS_SUM_WIDTH)) and (sum_s <  to_signed(-T1,THIS_SUM_WIDTH))) else
                    std_logic_vector((SHIFT_RIGHT(sum_s,A1)(PIXEL_SIZE-1 downto 0)))                               when ((sum_s >= to_signed(-T1,THIS_SUM_WIDTH)) and (sum_s <= to_signed( T1,THIS_SUM_WIDTH))) else
                    std_logic_vector(to_signed( V1,PIXEL_SIZE) + (SHIFT_RIGHT(sum_s,A2)(PIXEL_SIZE-1 downto 0)))   when ((sum_s >  to_signed( T1,THIS_SUM_WIDTH)) and (sum_s <  to_signed( T2,THIS_SUM_WIDTH))) else
                    std_logic_vector(to_signed( V2,PIXEL_SIZE));


    --------------------------------------------------------------------------
    -- DataValid and FlowValid Management :
    --------------------------------------------------------------------------
    -- out_dv => '1' when all in_dvs (plural) are at 1
    -- TODO : Unary operators : Only supported in VHDL-2008

    out_dv <= in_dv;
    out_fv <= in_fv;
    end bhv;