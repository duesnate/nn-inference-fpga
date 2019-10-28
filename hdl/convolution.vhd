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
        CHANNEL_COUNT   : natural := 3
        );
    Port (  
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Input_Image     : in std_logic_vector(8*IMAGE_SIZE**2-1 downto 0);
        Kernel_Weights  : in std_logic_vector(8*KERNEL_SIZE**2-1 downto 0);
        Feature_Map     : out std_logic_vector(16*(IMAGE_SIZE-KERNEL_SIZE+1)**2-1 downto 0)
        );
end convolution;

architecture Behavioral of convolution is

    constant FEATURE_SIZE : natural := IMAGE_SIZE-KERNEL_SIZE+1;

    signal Input_Image_i       : GridType(1 to IMAGE_SIZE, 1 to IMAGE_SIZE, 1 to CHANNEL_COUNT)(7 downto 0);
    signal Kernel_Weights_i    : GridType(1 to KERNEL_SIZE, 1 to KERNEL_SIZE, 1 to CHANNEL_COUNT)(7 downto 0);
    signal Feature_Map_i       : GridType(1 to FEATURE_SIZE, 1 to FEATURE_SIZE, 1 to CHANNEL_COUNT)(15 downto 0);

begin

    process(Aclk, Aresetn)
        variable var_feature : GridType(Feature_Map_i'range(1), Feature_Map_i'range(2), 1 to CHANNEL_COUNT)(15 downto 0);
    begin
        var_feature := (others => (others => (others => (others => '0'))));
        if Aresetn = '0' then
            Feature_Map_i <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            for row_iter in Feature_Map_i'range(1) loop
                for col_iter in Feature_Map_i'range(2) loop
                    for row in Kernel_Weights_i'range(1) loop
                        for column in Kernel_Weights_i'range(2) loop
                            for channel in 1 to CHANNEL_COUNT loop
                                var_feature(row_iter,col_iter,channel) := var_feature(row_iter,col_iter,channel) + (Input_Image_i(row+row_iter-1,column+col_iter-1,channel) * Kernel_Weights_i(row,column,channel));
                            end loop;
                        end loop;
                    end loop;
                end loop;
            end loop;
            Feature_Map_i <= var_feature;
        end if;
    end process;


    gen_image_row: for row in Input_Image_i'range(1) generate
        gen_image_col: for column in Input_Image_i'range(2) generate
            gen_image_chan: for channel in 1 to CHANNEL_COUNT generate
                Input_Image_i(row,column,channel) <= unsigned(Input_Image(8*(column+IMAGE_SIZE*(row-1))-1 downto 8*(column+IMAGE_SIZE*(row-1))-8));
            end generate gen_image_chan;
        end generate gen_image_col;
    end generate gen_image_row;

    gen_kernel_row: for row in Kernel_Weights_i'range(1) generate
        gen_kernel_col: for column in Kernel_Weights_i'range(2) generate
            gen_kernel_chan: for channel in 1 to CHANNEL_COUNT generate
                Kernel_Weights_i(row,column,channel) <= unsigned(Kernel_Weights(8*(column+KERNEL_SIZE*(row-1))-1 downto 8*(column+KERNEL_SIZE*(row-1))-8));
            end generate gen_kernel_chan;
        end generate gen_kernel_col;
    end generate gen_kernel_row;

    gen_feature_row: for row in Feature_Map_i'range(1) generate
        gen_feature_col: for column in Feature_Map_i'range(2) generate
            gen_feature_chan: for channel in 1 to CHANNEL_COUNT generate
                Feature_Map(16*(column+(FEATURE_SIZE)*(row-1))-1 downto 16*(column+(FEATURE_SIZE)*(row-1))-16) <= std_logic_vector(Feature_Map_i(row,column,channel));
            end generate gen_feature_chan;
        end generate gen_feature_col;
    end generate gen_feature_row;

end Behavioral;


