----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:
-- Design Name: 
-- Module Name: grid_iterator - Behavioral
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

    type stateType is (CHN_STATE, COL_STATE, ROW_STATE);

    signal iter_state   : stateType;
    signal row_iter     : integer range 1 to GRID_SIZE;
    signal col_iter     : integer range 1 to GRID_SIZE;
    signal chn_iter     : integer range 1 to CHANNEL_COUNT;

begin

    row     <= row_iter;
    column  <= col_iter;
    channel <= chn_iter;

    process(Aclk, Aresetn)
    begin
        if Aresetn = '0' then
            iter_state <= CHN_STATE;
            row_iter <= 1;
            col_iter <= 1;
            chn_iter <= 1;
        elsif rising_edge(Aclk) then
            -- Pause iterations while hold is asserted
            if not hold then 
                case iter_state is
                    when CHN_STATE => 
                        if chn_iter >= CHANNEL_COUNT then 
                            chn_iter <= 1;
                            iter_state <= COL_STATE;
                        else
                            chn_iter <= chn_iter + 1;
                        end if;
                    when COL_STATE =>
                        if col_iter >= GRID_SIZE then 
                            col_iter <= 1;
                            iter_state <= ROW_STATE;
                        else 
                            col_iter <= col_iter + 1;
                            iter_state <= CHN_STATE;
                        end if;
                    when ROW_STATE =>
                        if row_iter >= GRID_SIZE then 
                            row_iter <= 1;
                        else 
                            row_iter <= row_iter + 1;
                        end if;
                        iter_state <= CHN_STATE;
                    when others => 
                        iter_state <= CHN_STATE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
