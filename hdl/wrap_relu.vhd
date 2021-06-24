----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date: 11/07/2019 11:13:54 AM
-- Design Name: 
-- Module Name: wrap_relu
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
--              This wrapper is required for dropping the relu module
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

entity wrap_relu is
    generic (
        FEATURE_SIZE  : natural := 6;
        CHANNEL_COUNT : natural := 3;
        GRADIENT_BITS : natural := 8
        );
    port (
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Input_Feature   : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*FEATURE_SIZE**2-1 downto 0);
        Output_Feature  : out std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*FEATURE_SIZE**2-1 downto 0)
        );
end wrap_relu;

architecture Behavioral of wrap_relu is
begin
    interface_relu_00 : interface_relu
        generic map (
            FEATURE_SIZE    => FEATURE_SIZE,
            CHANNEL_COUNT   => CHANNEL_COUNT,
            GRADIENT_BITS   => GRADIENT_BITS
            )
        port map (
            Aclk            => Aclk,
            Aresetn         => Aresetn,
            Input_Feature   => Input_Feature,
            Output_Feature  => Output_Feature
            );
end Behavioral;
