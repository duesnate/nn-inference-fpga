----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: interface_relu
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
--              This module converts from the multi-dimensional array type 
--              "GridType" to/from std_logic_vector in order to allow for 
--              integration with external data streams.
--
--              Four dimensions must be mapped into a single std_logic_vector.
--              Each neuron is stored in contiguous bits of size GRADIENT_BITS.
--              The remaining three dimensions are stored by first iterating 
--              through channels, then columns, and then finally rows. This can 
--              be considered to be row-major in terms of rows and columns. Then
--              can be considered column-major in terms of columns and channels.
--
--              Requires the wrap_relu.vhd module prior to being dropped into
--              a Vivado block design.
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

entity interface_relu is
    Generic(
        FEATURE_SIZE    : natural := 6;
        CHANNEL_COUNT   : natural := 3;
        GRADIENT_BITS   : natural := 8
    );
    Port (  
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Input_Feature   : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*FEATURE_SIZE**2-1 downto 0);
        Output_Feature  : out std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*FEATURE_SIZE**2-1 downto 0)
    );
end interface_relu;

architecture Behavioral of interface_relu is
    
    signal Input_Feature_i    : GridType(1 to FEATURE_SIZE, 1 to FEATURE_SIZE, 1 to CHANNEL_COUNT) (GRADIENT_BITS-1 downto 0);
    signal Output_Feature_i   : GridType(1 to FEATURE_SIZE, 1 to FEATURE_SIZE, 1 to CHANNEL_COUNT) (GRADIENT_BITS-1 downto 0);

begin

    gen_in_row: for row in Input_Feature_i'range(1) generate
        gen_in_col: for column in Input_Feature_i'range(2) generate
            gen_in_chan: for channel in Input_Feature_i'range(3) generate
                Input_Feature_i(row, column, channel) 
                    <= signed(Input_Feature((channel + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT) * GRADIENT_BITS - 1 downto 
                                            (channel + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT - 1) * GRADIENT_BITS));
            end generate gen_in_chan;
        end generate gen_in_col;
    end generate gen_in_row;

    gen_out_row: for row in Output_Feature_i'range(1) generate
        gen_out_col: for column in Output_Feature_i'range(2) generate
            gen_out_chan: for channel in Output_Feature_i'range(3) generate
                Output_Feature( (channel + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT) * GRADIENT_BITS - 1 downto 
                                (channel + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT - 1) * GRADIENT_BITS)
                    <= std_logic_vector(Output_Feature_i(row, column, channel));
            end generate gen_out_chan;
        end generate gen_out_col;
    end generate gen_out_row;

    relu_00 : relu
        generic map (
            FEATURE_SIZE    => FEATURE_SIZE,
            CHANNEL_COUNT   => CHANNEL_COUNT,
            GRADIENT_BITS   => GRADIENT_BITS
        )
        port map (
            Aclk            => Aclk,
            Aresetn         => Aresetn,
            Input_Feature   => Input_Feature_i,
            Output_Feature  => Output_Feature_i
        );

end Behavioral;


