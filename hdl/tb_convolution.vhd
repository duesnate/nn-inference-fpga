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

	signal Aclk            : std_logic;
	signal Aresetn         : std_logic;
	signal Input_Image     : GridType(1 to IMAGE_SIZE, 1 to IMAGE_SIZE, 1 to CHANNEL_COUNT)(7 downto 0);
	signal Kernel_Weights  : GridType(1 to KERNEL_SIZE, 1 to KERNEL_SIZE, 1 to CHANNEL_COUNT)(7 downto 0);
	signal Feature_Map     : GridType(1 to IMAGE_SIZE-KERNEL_SIZE+1, 1 to IMAGE_SIZE-KERNEL_SIZE+1, 1 to CHANNEL_COUNT)(15 downto 0);

begin

	uut: convolution 
		generic map (
			IMAGE_SIZE      <= 4,
	        KERNEL_SIZE     <= 2,
	        CHANNEL_COUNT  	<= 3
			)
		port map (
			Aclk			<= Aclk,
			Aresetn			<= Aresetn,
			Input_Image		<= Input_Image,
			Kernel_Weights	<= Kernel_Weights,
			Feature_Map		<= Feature_Map
			);



end Behavioral;
