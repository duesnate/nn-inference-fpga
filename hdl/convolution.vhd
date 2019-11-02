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
        CHANNEL_COUNT   : natural := 3;
        GRADIENT_BITS   : natural := 8
    );
    Port (  
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Input_Image     : in GridType(  
            1 to IMAGE_SIZE, 
            1 to IMAGE_SIZE, 
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS-1 downto 0);
        Kernel_Weights  : in GridType(  
            1 to KERNEL_SIZE, 
            1 to KERNEL_SIZE, 
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS-1 downto 0);
        Feature_Map     : out GridType( 
            1 to (IMAGE_SIZE-KERNEL_SIZE+1), 
            1 to (IMAGE_SIZE-KERNEL_SIZE+1), 
            1 to CHANNEL_COUNT
            ) (2*GRADIENT_BITS-1 downto 0)
    );
end convolution;

architecture Behavioral of convolution is
begin

    process(Aclk, Aresetn)
        variable var_feature : GridType(
            Feature_Map'range(1), 
            Feature_Map'range(2), 
            Feature_Map'range(3)
            ) (2*GRADIENT_BITS-1 downto 0);
    begin
        var_feature := (others => (others => (others => (others => '0'))));
        if Aresetn = '0' then
            Feature_Map <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            for row_iter in Feature_Map'range(1) loop
                for col_iter in Feature_Map'range(2) loop
                    for row in Kernel_Weights'range(1) loop
                        for column in Kernel_Weights'range(2) loop
                            for channel in 1 to CHANNEL_COUNT loop
                                var_feature(row_iter, col_iter, channel) := (
                                    var_feature(row_iter, col_iter, channel) + (
                                        Input_Image(row + row_iter - 1, column + col_iter - 1, channel) 
                                        * Kernel_Weights(row, column, channel)
                                        )
                                    );
                            end loop;
                        end loop;
                    end loop;
                end loop;
            end loop;
            Feature_Map <= var_feature;
        end if;
    end process;

end Behavioral;
