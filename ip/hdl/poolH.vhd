library ieee;
	use	ieee.std_logic_1164.all;
	use	ieee.numeric_std.all;

library work;
	use work.cnn_types.all;

entity poolH is

    generic(
        PIXEL_SIZE      :   integer;
        IMAGE_WIDTH     :   integer;
        KERNEL_SIZE     :   integer
    );

    port(
        clk	            :	in 	std_logic;
        reset_n	        :	in	std_logic;
        enable          :   in  std_logic;
        in_data         :   in  std_logic_vector (PIXEL_SIZE - 1 downto 0);
        in_dv           :   in  std_logic;
        in_fv           :   in  std_logic;
        out_data        :   out std_logic_vector (PIXEL_SIZE - 1 downto 0);
        out_dv          :   out std_logic;
        out_fv          :   out std_logic
    );

end entity;

architecture bhv of poolH is
    signal tmp_dv : std_logic := '0';

    begin

        process (clk)
        begin
            if (reset_n = '0') then
                tmp_dv <='0';

            elsif (rising_edge(clk)) then
                if (enable = '1') then
                    if (in_fv = '1') then
                        if (in_dv = '1') then
                            -- KERNEL_SIZE  = 2
                            tmp_dv <= NOT(tmp_dv);
                        end if;
                    end if;
                end if;
            end if;
        end process;

        out_data <= in_data;
        out_fv   <= in_fv;
        out_dv   <= in_dv and tmp_dv;
        -- out_dv   <= tmp_dv ;

end bhv;
