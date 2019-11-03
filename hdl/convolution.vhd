----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: convolution - Behavioral
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
library xil_defaultlib;
use xil_defaultlib.mypackage.ALL;

entity convolution is
    Generic(
        IMAGE_SIZE      : natural := 6;
        KERNEL_SIZE     : natural := 3;
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
            ) (GRADIENT_BITS-1 downto 0);
        Kernel_Weights  : in GridType(  
            1 to KERNEL_SIZE,
            1 to KERNEL_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS-1 downto 0);
        Feature_Map     : out GridType( 
            1 to (IMAGE_SIZE+2*ZERO_PADDING-KERNEL_SIZE)/STRIDE_STEPS+1,
            1 to (IMAGE_SIZE+2*ZERO_PADDING-KERNEL_SIZE)/STRIDE_STEPS+1,
            1 to CHANNEL_COUNT
            ) (2*GRADIENT_BITS-1 downto 0)
    );
end convolution;

architecture Behavioral of convolution is

    signal Image_Padded : GridType(
        1 to IMAGE_SIZE+2*ZERO_PADDING,
        1 to IMAGE_SIZE+2*ZERO_PADDING,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS-1 downto 0);

begin

    gen_row: for row in Image_Padded'range(1) generate
        gen_col: for col in Image_Padded'range(2) generate
            gen_chl: for channel in Image_Padded'range(3) generate
                gen_zp: if  (row > ZERO_PADDING) or 
                            (col > ZERO_PADDING) or 
                            (row <= Image_Padded'high(1)-ZERO_PADDING) or 
                            (col <= Image_Padded'high(2)-ZERO_PADDING) generate
                    Image_Padded(row, col, channel) <= Input_Image(row - ZERO_PADDING, col - ZERO_PADDING, channel);
                else generate
                    Image_Padded(row, col, channel) <= (others => '0');
                end generate gen_zp;
            end generate gen_chl;
        end generate gen_col;
    end generate gen_row;

    process(Aclk, Aresetn)
        variable var_feature : GridType(
            Feature_Map'range(1), 
            Feature_Map'range(2), 
            Feature_Map'range(3)
            ) (2*GRADIENT_BITS-1 downto 0);
    begin
        var_feature := (others => (others => (others => (others => '0'))));
        if Aresetn = '0' then
            Feature_Map <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            for row_iter in Feature_Map'range(1) loop
                for col_iter in Feature_Map'range(2) loop
                    for row in Kernel_Weights'range(1) loop
                        for column in Kernel_Weights'range(2) loop
                            for channel in Kernel_Weights'range(3) loop
                                var_feature(row_iter, col_iter, channel) := (
                                    var_feature(row_iter, col_iter, channel) + (
                                        Image_Padded(   
                                            STRIDE_STEPS * (row_iter - 1) + row, 
                                            STRIDE_STEPS * (col_iter - 1) + column, 
                                            channel) 
                                        * Kernel_Weights(row, column, channel)
                                        )
                                    );
                            end loop;
                        end loop;
                    end loop;
                end loop;
            end loop;
            Feature_Map <= var_feature;
        end if;
    end process;

end Behavioral;
