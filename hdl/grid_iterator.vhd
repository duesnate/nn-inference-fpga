----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date:
-- Design Name: 
-- Module Name: grid_iterator
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
--              This module was developed for the purpose of iterating through
--              multi-dimensional "GridType" arrays over multiple clock cycles.
--              This module is instanciated within folded convolution 
--              implementations.
----------------------------------------------------------------
-- 
-- Dependencies: VHDL-2008
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
-- grid_iterator.vhd

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
library xil_defaultlib;
use xil_defaultlib.mypackage.ALL;

entity grid_iterator is
    Generic(
        GRID_SIZE    : natural := 8;
        CHANNEL_COUNT   : natural := 3
    );
    Port (
        Aclk    : in std_logic;
        Aresetn : in std_logic;
        hold    : in boolean;
        row     : out integer range 1 to GRID_SIZE;
        column  : out integer range 1 to GRID_SIZE;
        channel : out integer range 1 to CHANNEL_COUNT
    );
end grid_iterator;

architecture Behavioral of grid_iterator is

begin

    process(Aclk, Aresetn)
    begin
        if Aresetn = '0' then
            row <= 1;
            column <= 1;
            channel <= 1;
        elsif rising_edge(Aclk) then
            -- Pause iterations while hold is asserted
            if not hold then 
                if channel >= CHANNEL_COUNT then
                    if column >= GRID_SIZE then
                        if row >= GRID_SIZE then
                            row <= 1;
                        else
                            row <= row + 1;
                        end if;
                        column <= 1;
                    else
                        column <= column + 1;
                    end if;
                    channel <= 1;
                else
                    channel <= channel + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
