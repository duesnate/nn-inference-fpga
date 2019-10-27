----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/27/2019 01:33:02 AM
-- Design Name: 
-- Module Name: tb_convolution - Behavioral
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


entity tb_convolution is
--  Port ( );
end tb_convolution;

architecture Behavioral of tb_convolution is
    
    constant IMAGE_SIZE    : natural := 4;
    constant KERNEL_SIZE   : natural := 2;
    constant CHANNEL_COUNT : natural := 3;

    signal Aclk            : std_logic := '1';
    signal Aresetn         : std_logic := '0';
    signal Input_Image     : GridType(1 to IMAGE_SIZE, 1 to IMAGE_SIZE, 1 to CHANNEL_COUNT)(7 downto 0);
    signal Kernel_Weights  : GridType(1 to KERNEL_SIZE, 1 to KERNEL_SIZE, 1 to CHANNEL_COUNT)(7 downto 0);
    signal Feature_Map     : GridType(1 to IMAGE_SIZE-KERNEL_SIZE+1, 1 to IMAGE_SIZE-KERNEL_SIZE+1, 1 to CHANNEL_COUNT)(15 downto 0);


begin

    Aclk <= not Aclk after 5 ns;

    uut: convolution 
        generic map (
            IMAGE_SIZE      => IMAGE_SIZE,
            KERNEL_SIZE     => KERNEL_SIZE,
            CHANNEL_COUNT   => CHANNEL_COUNT
            )
        port map (
            Aclk            => Aclk,
            Aresetn         => Aresetn,
            Input_Image     => Input_Image,
            Kernel_Weights  => Kernel_Weights,
            Feature_Map     => Feature_Map
            );

    process
    begin
        Aresetn <= '0';
        wait for 100 ns;
        Input_Image <= random_grid(4, 8, Input_Image);
        Kernel_Weights <= random_grid(4, 8, Kernel_Weights);
        Aresetn <= '1';
        wait for 10 ns;
        wait for 10 ns;
        wait for 10 ns;
        wait for 10 ns;
        wait for 10 ns;
        Input_Image <= random_grid(4, 8, Input_Image);
        Kernel_Weights <= random_grid(4, 8, Kernel_Weights);
        wait for 10 ns;
        Input_Image <= random_grid(4, 8, Input_Image);
        Kernel_Weights <= random_grid(4, 8, Kernel_Weights);
        wait for 10 ns;
        wait for 10 ns;
        Input_Image <= random_grid(4, 8, Input_Image);
        Kernel_Weights <= random_grid(4, 8, Kernel_Weights);
        wait;

    end process;


end Behavioral;
