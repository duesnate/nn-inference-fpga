----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: relu - Behavioral
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

entity relu is
    Generic(
        FEATURE_SIZE    : natural := 6;
        CHANNEL_COUNT   : natural := 3;
        GRADIENT_BITS   : natural := 8
    );
    Port (
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Input_Feature   : in GridType(
            1 to FEATURE_SIZE,
            1 to FEATURE_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS-1 downto 0);
        Output_Feature  : out GridType(
            1 to FEATURE_SIZE,
            1 to FEATURE_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS-1 downto 0)
    );
end relu;

architecture Behavioral of relu is
begin
    process(Aclk, Aresetn)
    begin
        if Aresetn = '0' then
            Output_Feature <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            for row in Input_Feature'range(1) loop
                for col in Input_Feature'range(2) loop
                    for channel in Input_Feature'range(3) loop
                        if to_integer(Input_Feature(row, col, channel)) < 0 then
                            Output_Feature(row, col, channel) <= (others => '0');
                        else
                            Output_Feature(row, col, channel) <= Input_Feature(row, col, channel);
                        end if;
                    end loop;
                end loop;
            end loop;
        end if;
    end process;
end Behavioral;
