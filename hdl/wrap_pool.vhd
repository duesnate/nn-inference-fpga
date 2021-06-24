----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date:
-- Design Name: 
-- Module Name: wrap_pool
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
--              This wrapper is required for dropping the pooling module
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

entity wrap_pool is
    generic (
        FEATURE_SIZE    : natural := 6;
        CHANNEL_COUNT   : natural := 3;
        GRADIENT_BITS   : natural := 8;
        POOL_SIZE       : natural := 2
        );
    port (
        Aclk        : in std_logic;
        Aresetn     : in std_logic;
        Feature_In  : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*FEATURE_SIZE**2-1 downto 0);
        Feature_Out : out std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*(FEATURE_SIZE/POOL_SIZE)**2-1 downto 0)
        );
end wrap_pool;

architecture Behavioral of wrap_pool is
begin
    interface_pool_00 : interface_pool
        generic map (
            FEATURE_SIZE    => FEATURE_SIZE,
            CHANNEL_COUNT   => CHANNEL_COUNT,
            GRADIENT_BITS   => GRADIENT_BITS,
            POOL_SIZE       => POOL_SIZE
            )
        port map (
            Aclk            => Aclk,
            Aresetn         => Aresetn,
            Feature_In      => Feature_In,
            Feature_Out     => Feature_Out
            );
end Behavioral;
