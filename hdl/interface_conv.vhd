----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: interface_conv - Behavioral
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

entity interface_conv is
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
        Input_Image     : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*IMAGE_SIZE**2-1 downto 0);
        Kernel_Weights  : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*KERNEL_SIZE**2-1 downto 0);
        Feature_Map     : out std_logic_vector(2*GRADIENT_BITS*CHANNEL_COUNT*((IMAGE_SIZE+2*ZERO_PADDING-KERNEL_SIZE)/STRIDE_STEPS+1)**2-1 downto 0)
    );
end interface_conv;

architecture Behavioral of interface_conv is

    constant FEATURE_SIZE : natural := (IMAGE_SIZE+2*ZERO_PADDING-KERNEL_SIZE) / STRIDE_STEPS + 1;
    
    signal Input_Image_i    : GridType(1 to IMAGE_SIZE, 1 to IMAGE_SIZE, 1 to CHANNEL_COUNT) (GRADIENT_BITS-1 downto 0);
    signal Kernel_Weights_i : GridType(1 to KERNEL_SIZE, 1 to KERNEL_SIZE, 1 to CHANNEL_COUNT) (GRADIENT_BITS-1 downto 0);
    signal Feature_Map_i    : GridType(1 to FEATURE_SIZE, 1 to FEATURE_SIZE, 1 to CHANNEL_COUNT) (2*GRADIENT_BITS-1 downto 0);

begin

    gen_image_row: for row in Input_Image_i'range(1) generate
        gen_image_col: for column in Input_Image_i'range(2) generate
            gen_image_chan: for channel in Input_Image_i'range(3) generate
                Input_Image_i(row, column, channel) 
                    <= signed(Input_Image((channel + ((column - 1) + (row - 1) * IMAGE_SIZE) * CHANNEL_COUNT) * GRADIENT_BITS - 1 downto 
                                            (channel + ((column - 1) + (row - 1) * IMAGE_SIZE) * CHANNEL_COUNT - 1) * GRADIENT_BITS));
            end generate gen_image_chan;
        end generate gen_image_col;
    end generate gen_image_row;

    gen_kernel_row: for row in Kernel_Weights_i'range(1) generate
        gen_kernel_col: for column in Kernel_Weights_i'range(2) generate
            gen_kernel_chan: for channel in Kernel_Weights_i'range(3) generate
                Kernel_Weights_i(row, column, channel) 
                    <= signed(Kernel_Weights( (channel + ((column - 1) + (row - 1) * KERNEL_SIZE) * CHANNEL_COUNT) * GRADIENT_BITS - 1 downto 
                                                (channel + ((column - 1) + (row - 1) * KERNEL_SIZE) * CHANNEL_COUNT - 1) * GRADIENT_BITS));
            end generate gen_kernel_chan;
        end generate gen_kernel_col;
    end generate gen_kernel_row;

    gen_feature_row: for row in Feature_Map_i'range(1) generate
        gen_feature_col: for column in Feature_Map_i'range(2) generate
            gen_feature_chan: for channel in Feature_Map_i'range(3) generate
                Feature_Map(2 * (channel + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT) * GRADIENT_BITS - 1 downto 
                            2 * (channel + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT - 1) * GRADIENT_BITS)
                    <= std_logic_vector(Feature_Map_i(row, column, channel));
            end generate gen_feature_chan;
        end generate gen_feature_col;
    end generate gen_feature_row;

    convolution_00 : convolution
        generic map (
            IMAGE_SIZE      => IMAGE_SIZE,
            KERNEL_SIZE     => KERNEL_SIZE,
            CHANNEL_COUNT   => CHANNEL_COUNT,
            GRADIENT_BITS   => GRADIENT_BITS,
            STRIDE_STEPS    => STRIDE_STEPS,
            ZERO_PADDING    => ZERO_PADDING
        )
        port map (
            Aclk            => Aclk,
            Aresetn         => Aresetn,
            Input_Image     => Input_Image_i,
            Kernel_Weights  => Kernel_Weights_i,
            Feature_Map     => Feature_Map_i
        );

end Behavioral;


