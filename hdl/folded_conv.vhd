----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: folded_conv - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
library xil_defaultlib;
use xil_defaultlib.mypackage.ALL;

entity folded_conv is
    Generic(
        IMAGE_SIZE      : natural := 24;
        KERNEL_SIZE     : natural := 9;
        CHANNEL_COUNT   : natural := 3;
        GRADIENT_BITS   : natural := 8;
        STRIDE_STEPS    : natural := 1;
        ZERO_PADDING    : integer := 0
    );
    Port (  
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Input_Image     : in GridType(  
            1 to IMAGE_SIZE,
            1 to IMAGE_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS - 1 downto 0);
        Kernel_Weights  : in GridType(  
            1 to KERNEL_SIZE,
            1 to KERNEL_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS - 1 downto 0);
        Feature_Map     : out GridType( 
            1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
            1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS - 1 downto 0)
    );
end folded_conv;

architecture Behavioral of folded_conv is

    constant BITS4SUM : integer := integer(ceil(log2(real(KERNEL_SIZE**2))));

    signal Image_Padded : GridType(
        1 to IMAGE_SIZE + 2 * ZERO_PADDING,
        1 to IMAGE_SIZE + 2 * ZERO_PADDING,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    type stateType is (CHN_STATE, COL_STATE, ROW_STATE);
    signal iter_state : stateType;

    signal row_iter : integer range Feature_Map'range(1);
    signal col_iter : integer range Feature_Map'range(2);
    signal channel  : integer range Feature_Map'range(3);

begin

    -- Generate zero-padded image
    gen_row: for row in Image_Padded'range(1) generate
        gen_col: for col in Image_Padded'range(2) generate
            gen_chl: for channel in Image_Padded'range(3) generate
                -- Fill with input image when out of padding range
                gen_zp: if  (row > ZERO_PADDING) and 
                            (col > ZERO_PADDING) and 
                            (row <= Image_Padded'high(1)-ZERO_PADDING) and 
                            (col <= Image_Padded'high(2)-ZERO_PADDING) generate
                    Image_Padded(row, col, channel) <= Input_Image(row - ZERO_PADDING, col - ZERO_PADDING, channel);
                else generate
                    Image_Padded(row, col, channel) <= (others => '0');
                end generate gen_zp;
            end generate gen_chl;
        end generate gen_col;
    end generate gen_row;

    process(Aclk, Aresetn)
        variable feature_sum : signed(2 * GRADIENT_BITS + BITS4SUM - 1 downto 0);
    begin
        if Aresetn = '0' then
            Feature_Map <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            -- Clear summation
            feature_sum := (others => '0');
            for row in Kernel_Weights'range(1) loop
                for column in Kernel_Weights'range(2) loop
                    
                    feature_sum := feature_sum
                        -- Add Input Image
                        + Image_Padded(
                            STRIDE_STEPS * (row_iter - 1) + row, 
                            STRIDE_STEPS * (col_iter - 1) + column, 
                            channel)
                        -- Multiplied by Kernel Weight
                        * Kernel_Weights(row, column, channel);
                    
                end loop;
            end loop;
            -- Scale down Result
            Feature_Map(row_iter, col_iter, channel) <= feature_sum(feature_sum'high downto feature_sum'high - GRADIENT_BITS + 1);
        end if;
    end process;

    process(Aclk, Aresetn)
    begin
        if Aresetn = '0' then
            iter_state <= CHN_STATE;
            row_iter <= 1;
            col_iter <= 1;
            channel <= 1;
        elsif rising_edge(Aclk) then
            case iter_state is
                when CHN_STATE => 
                    if channel >= Feature_Map'high(3) then 
                        channel <= 1;
                        iter_state <= COL_STATE;
                    else
                        channel <= channel + 1;
                    end if;
                when COL_STATE =>
                    if col_iter >= Feature_Map'high(2) then 
                        col_iter <= 1;
                        iter_state <= ROW_STATE;
                    else 
                        col_iter <= col_iter + 1;
                        iter_state <= CHN_STATE;
                    end if;
                when ROW_STATE =>
                    if row_iter >= Feature_Map'high(1) then 
                        row_iter <= 1;
                        iter_state <= CHN_STATE;
                    else 
                        row_iter <= row_iter + 1;
                        iter_state <= CHN_STATE;
                    end if;
                when others => 
                    iter_state <= CHN_STATE;
            end case;
        end if;
    end process;

end Behavioral;
