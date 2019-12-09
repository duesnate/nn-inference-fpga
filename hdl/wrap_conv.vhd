----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/27/2019 11:13:54 AM
-- Design Name: 
-- Module Name: wrap_conv - Behavioral
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

entity wrap_conv is
    generic (
        IMAGE_SIZE      : positive := 1;
        KERNEL_SIZE     : positive := 1;
        CHANNELS_IN     : positive := 1;
        GRADIENT_BITS   : positive := 1;
        CHANNELS_OUT    : positive := 1;
        STRIDE_STEPS    : positive := 1;
        ZERO_PADDING    : natural := 0;
        RELU_ACTIVATION : boolean := TRUE
        );
    port (
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Input_Image     : in std_logic_vector(GRADIENT_BITS * CHANNELS_IN * IMAGE_SIZE**2 - 1 downto 0);
        Kernel_Weights  : in std_logic_vector(GRADIENT_BITS * CHANNELS_IN * CHANNELS_OUT * KERNEL_SIZE**2 - 1 downto 0);
        Output_Feature  : out std_logic_vector(GRADIENT_BITS * CHANNELS_OUT * ((IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1)**2 - 1 downto 0)
        );
end wrap_conv;

architecture Behavioral of wrap_conv is
begin
    interface_conv_00 : interface_conv
        generic map (
            IMAGE_SIZE      => IMAGE_SIZE,
            KERNEL_SIZE     => KERNEL_SIZE,
            CHANNELS_IN     => CHANNELS_IN,
            GRADIENT_BITS   => GRADIENT_BITS,
            CHANNELS_OUT    => CHANNELS_OUT,
            STRIDE_STEPS    => STRIDE_STEPS,
            ZERO_PADDING    => ZERO_PADDING,
            RELU_ACTIVATION => RELU_ACTIVATION
            )
        port map (
            Aclk            => Aclk,
            Aresetn         => Aresetn,
            Input_Image     => Input_Image,
            Kernel_Weights  => Kernel_Weights,
            Output_Feature  => Output_Feature
            );
end Behavioral;
