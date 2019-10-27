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
        IMAGE_SIZE  := 6;
        KERNEL_SIZE := 3
        );
    Port (  
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        --Input_Image     : in std_logic_vector(IMAGE_SIZE**2-1 downto 0);
        Input_Image     : in ImageMatrix(0 to IMAGE_SIZE-1, 0 to IMAGE_SIZE-1);
        --Kernel_Weights  : in std_logic_vector(KERNEL_SIZE**2-1 downto 0);
        Kernel_Weights  : in KernalMatrix(0 to KERNEL_SIZE-1, 0 to KERNEL_SIZE-1);
        --Feature_Map     : out std_logic_vector((IMAGE_SIZE-KERNEL_SIZE+1)**2-1 downto 0)
        Feature_Map     : out ImageMatrix(0 to IMAGE_SIZE-KERNEL_SIZE, 0 to IMAGE_SIZE-KERNEL_SIZE)
        );
end convolution;

architecture Behavioral of convolution is
    
begin

    process(Aclk)
    begin
        if Aresetn = '0' then
            Feature_Map <= (others => '0');
        elsif rising_edge(Aclk) then
            Input_Image
        end if;
    end process;

end Behavioral;
