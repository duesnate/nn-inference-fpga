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
library work;
use work.mypackage.ALL;

entity convolution is
    Generic(
        IMAGE_SIZE      : unsigned := 4;
        KERNEL_SIZE     : unsigned := 2;
        CHANNEL_COUNT   : unsigned := 3
        );
    Port (  
        Aclk            : in    std_logic;
        Aresetn         : in    std_logic;
        Input_Image     : in    GridType(1 to IMAGE_SIZE, 1 to IMAGE_SIZE, 1 to CHANNEL_COUNT)(7 downto 0);
        Kernel_Weights  : in    GridType(1 to KERNEL_SIZE, 1 to KERNEL_SIZE, 1 to CHANNEL_COUNT)(7 downto 0);
        Feature_Map     : out   GridType(1 to IMAGE_SIZE-KERNEL_SIZE+1, 1 to IMAGE_SIZE-KERNEL_SIZE+1, 1 to CHANNEL_COUNT)(15 downto 0)
        );
end convolution;

architecture Behavioral of convolution is

begin

    process(Aclk)
    begin
        if Aresetn = '0' then
            product <= (others => (others => '0'));
            Feature_Map <= (others => (others => '0'));
        elsif rising_edge(Aclk) then
            for row_iter in 1 to IMAGE_SIZE-KERNEL_SIZE+1 loop
                for col_iter in 1 to IMAGE_SIZE-KERNEL_SIZE+1 loop
                    for row in row_iter to KERNEL_SIZE+row_iter-1 loop
                        for column in col_iter to KERNEL_SIZE+col_iter-1 loop
                            for channel in 1 to CHANNEL_COUNT loop
                                Feature_Map(row_iter,col_iter,channel) <= Feature_Map(row_iter,col_iter,channel) + (Input_Image(row,column,channel) * Kernel_Weights(row,column,channel));
                            end loop;
                        end loop;
                    end loop;
                end loop;
            end loop;
        end if;
    end process;

end Behavioral;


