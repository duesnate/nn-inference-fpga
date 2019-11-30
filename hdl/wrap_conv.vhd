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
        IMAGE_SIZE    : natural := 6;
        KERNEL_SIZE   : natural := 3;
        CHANNEL_COUNT : natural := 3;
        GRADIENT_BITS : natural := 8;
        STRIDE_STEPS  : natural := 1;
        ZERO_PADDING  : integer := 0
        );
    port (
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Input_Image     : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*IMAGE_SIZE**2-1 downto 0);
        Kernel_Weights  : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*KERNEL_SIZE**2-1 downto 0);
        Feature_Map     : out std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*((IMAGE_SIZE+2*ZERO_PADDING-KERNEL_SIZE)/STRIDE_STEPS+1)**2-1 downto 0)
        );
end wrap_conv;

architecture Behavioral of wrap_conv is
begin
    interface_conv_00 : interface_conv
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
            Input_Image     => Input_Image,
            Kernel_Weights  => Kernel_Weights,
            Feature_Map     => Feature_Map
            );
end Behavioral;
