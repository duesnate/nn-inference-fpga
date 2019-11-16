----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 
-- Design Name: 
-- Module Name: interface_pool - Behavioral
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

entity interface_pool is
    Generic(
        FEATURE_SIZE    : natural := 6;
        CHANNEL_COUNT   : natural := 3;
        GRADIENT_BITS   : natural := 8;
        POOL_SIZE       : natural := 2
    );
    Port (
        Aclk        : in std_logic;
        Aresetn     : in std_logic;
        Feature_In  : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*FEATURE_SIZE**2-1 downto 0);
        Feature_Out : out std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*(FEATURE_SIZE/POOL_SIZE)**2-1 downto 0)
    );
end interface_pool;

architecture Behavioral of interface_pool is
    
    signal Feature_In_i    : GridType(1 to FEATURE_SIZE, 1 to FEATURE_SIZE, 1 to CHANNEL_COUNT) (GRADIENT_BITS-1 downto 0);
    signal Feature_Out_i   : GridType(1 to FEATURE_SIZE/POOL_SIZE, 1 to FEATURE_SIZE/POOL_SIZE, 1 to CHANNEL_COUNT) (GRADIENT_BITS-1 downto 0);

begin

    gen_image_row: for row in Feature_In_i'range(1) generate
        gen_image_col: for column in Feature_In_i'range(2) generate
            gen_image_chan: for channel in Feature_In_i'range(3) generate
                Feature_In_i(row, column, channel) 
                    <= signed(Feature_In(   (channel + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT) * GRADIENT_BITS - 1 downto 
                                            (channel + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT - 1) * GRADIENT_BITS));
            end generate gen_image_chan;
        end generate gen_image_col;
    end generate gen_image_row;

    gen_feature_row: for row in Feature_Out_i'range(1) generate
        gen_feature_col: for column in Feature_Out_i'range(2) generate
            gen_feature_chan: for channel in Feature_Out_i'range(3) generate
                Feature_Out((channel + ((column - 1) + (row - 1) * (FEATURE_SIZE/POOL_SIZE)) * CHANNEL_COUNT) * GRADIENT_BITS - 1 downto 
                            (channel + ((column - 1) + (row - 1) * (FEATURE_SIZE/POOL_SIZE)) * CHANNEL_COUNT - 1) * GRADIENT_BITS)
                    <= std_logic_vector(Feature_Out_i(row, column, channel));
            end generate gen_feature_chan;
        end generate gen_feature_col;
    end generate gen_feature_row;

    pooling_00 : pooling
        generic map (
            FEATURE_SIZE    => FEATURE_SIZE,
            CHANNEL_COUNT   => CHANNEL_COUNT,
            GRADIENT_BITS   => GRADIENT_BITS,
            POOL_SIZE       => POOL_SIZE
        )
        port map (
            Aclk            => Aclk,
            Aresetn         => Aresetn,
            Feature_in      => Feature_in_i,
            Feature_Out     => Feature_Out_i
        );

end Behavioral;


