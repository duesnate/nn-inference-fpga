----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 
-- Design Name: 
-- Module Name: pooling - Behavioral
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
                        ------------------MAX--------------------
                        max_val := (GRADIENT_BITS-1 => '1', others => '0');
                        for ri in (row-1)*POOL_SIZE+1 to row*POOL_SIZE loop
                            for ci in (col-1)*POOL_SIZE+1 to col*POOL_SIZE loop
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

