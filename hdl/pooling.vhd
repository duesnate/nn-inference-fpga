----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date: 
-- Design Name: 
-- Module Name: pooling
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
--              UNTESTED!!
-- 
--              Max-pooling implementation
--
--              Pooling layers are useful in CNN designs because they limit 
--              computational complexity while also functioning to prevent over-
--              fitting during training. Pooling can be thought of as a process 
--              of down-sampling the feature maps at the output of a 
--              convolutional layer. There are a number of different pooling 
--              functions that are used in CNN designs. Two very common 
--              functions are average-pooling and max-pooling. As the name 
--              suggests, the pooling function moves across the range of the 
--              feature map and consolidates or "pools" individual sections down 
--              to a single value. A typical example of a pooling operation is a 
--              2x2 square that reduces every four feature map neurons down to a 
--              single max or averaged value neuron output. A 2x2 block that 
--              iterates over an 8x8 feature map without overlaps would 
--              effectively downsample the feature to a 4x4 output, cutting its 
--              dimensions in half
----------------------------------------------------------------
--
-- Dependencies: VHDL-2008
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

entity pooling is
    Generic(
        FEATURE_SIZE    : natural := 6;
        CHANNEL_COUNT   : natural := 3;
        GRADIENT_BITS   : natural := 8;
        POOL_SIZE       : natural := 2
    );
    Port (  
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Feature_In      : in GridType(  
            1 to FEATURE_SIZE,
            1 to FEATURE_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS-1 downto 0);
        Feature_Out     : out GridType( 
            1 to FEATURE_SIZE/POOL_SIZE,
            1 to FEATURE_SIZE/POOL_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS-1 downto 0)
    );
end pooling;

architecture Behavioral of pooling is

begin

    process(Aclk, Aresetn)
        variable max_val : signed(GRADIENT_BITS-1 downto 0);
    begin
        if Aresetn = '0' then
            Feature_Out <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            for row in Feature_Out'range(1) loop
                for col in Feature_Out'range(2) loop
                    for channel in Feature_Out'range(3) loop
                        ---------------MAX FUNCTION--------------
                        -- Set initial max value to largest negative number possible
                        max_val := (max_val'high => '1', others => '0');
                        for ri in (row - 1) * POOL_SIZE + 1 to row * POOL_SIZE loop
                            for ci in (col - 1) * POOL_SIZE + 1 to col * POOL_SIZE loop
                                if Feature_In(ri, ci, channel) > max_val then
                                    max_val := Feature_In(ri, ci, channel);
                                end if;
                            end loop;
                        end loop;
                        Feature_Out(row, col, channel) <= max_val;
                        -----------------------------------------
                    end loop;
                end loop;
            end loop;
        end if;
    end process;

end Behavioral;

