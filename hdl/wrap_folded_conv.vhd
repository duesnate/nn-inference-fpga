----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date: 11/29/2019 11:13:54 AM
-- Design Name: 
-- Module Name: wrap_folded_conv
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
--              This wrapper is required for dropping the folded_conv_v2 module
--              into a Vivado block design. Currently, Vivado does not support
--              dropping VHDL-2008 module files directly into a block design.
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

entity wrap_folded_conv is
    generic (
        IMAGE_SIZE    : natural := 6;
        KERNEL_SIZE   : natural := 3;
        CHANNEL_COUNT : natural := 3;
        GRADIENT_BITS : natural := 8;
        STRIDE_STEPS  : natural := 1;
        ZERO_PADDING  : integer := 0;
        RELU_ACTIVATION : boolean
        );
    port (
        Aclk           : in std_logic;
        Aresetn        : in std_logic;
        Image_Stream   : in std_logic_vector(GRADIENT_BITS-1 downto 0);
        Image_Valid    : in boolean;
        Image_Ready    : out boolean;
        Kernel_Stream  : in std_logic_vector(GRADIENT_BITS-1 downto 0);
        Kernel_Valid   : in boolean;
        Kernel_Ready   : out boolean;
        Feature_Stream : out std_logic_vector(GRADIENT_BITS-1 downto 0);
        Feature_Valid  : out boolean;
        Feature_Ready  : in boolean
        );
end wrap_folded_conv;

architecture Behavioral of wrap_folded_conv is
begin

    folded_conv_00 : folded_conv_v2
        generic map (
            IMAGE_SIZE      => IMAGE_SIZE,
            KERNEL_SIZE     => KERNEL_SIZE,
            CHANNEL_COUNT   => CHANNEL_COUNT,
            GRADIENT_BITS   => GRADIENT_BITS,
            STRIDE_STEPS    => STRIDE_STEPS,
            ZERO_PADDING    => ZERO_PADDING,
            RELU_ACTIVATION => RELU_ACTIVATION
            )
        port map (
            Aclk           => Aclk,
            Aresetn        => Aresetn,
            Image_Stream   => Image_Stream,
            Image_Valid    => Image_Valid,
            Image_Ready    => Image_Ready,
            Kernel_Stream  => Kernel_Stream,
            Kernel_Valid   => Kernel_Valid,
            Kernel_Ready   => Kernel_Ready,
            Feature_Stream => Feature_Stream,
            Feature_Valid  => Feature_Valid,
            Feature_Ready  => Feature_Ready
            );

end Behavioral;
