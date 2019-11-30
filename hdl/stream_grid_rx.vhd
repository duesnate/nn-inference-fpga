----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/28/2019 09:17:28 PM
-- Design Name: 
-- Module Name: stream_grid_rx - Behavioral
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

entity stream_grid_rx is
    Generic (
        GRID_SIZE       : natural := 6;
        CHANNEL_COUNT   : natural := 3;
        GRADIENT_BITS   : natural := 8
    );
    Port (
        Aclk     : in std_logic;
        Aresetn  : in std_logic;
        -- AXIS
        Stream_Data     : in std_logic_vector(GRADIENT_BITS-1 downto 0);
        Stream_Valid    : in boolean;
        Stream_Ready    : out boolean;
        -- Data
        Grid_Data : out GridType(
            1 to GRID_SIZE,
            1 to GRID_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS - 1 downto 0);
        -- Control
        Transfer_Complete   : in boolean
    );
end stream_grid_rx;

architecture Behavioral of stream_grid_rx is

    signal grid_hold : boolean;
    signal grid_row : integer range Grid_Data'range(1);
    signal grid_col : integer range Grid_Data'range(2);
    signal grid_chn : integer range Grid_Data'range(3);

begin

    process(Aclk, Aresetn)
    begin
        if Aresetn = '0' then
            Grid_Data <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            if not grid_hold then
                Grid_Data(grid_row, grid_col, grid_chn) <= signed(Stream_Data);
            end if;
        end if;
    end process;

    iterator_stream_grid : grid_iterator
        generic map (
            GRID_SIZE       => Grid_Data'high(1),
            CHANNEL_COUNT   => Grid_Data'high(3)
            )
        port map (
            Aclk    => Aclk,
            Aresetn => Aresetn,
            hold    => grid_hold,
            row     => grid_row,
            column  => grid_col,
            channel => grid_chn
            );

    Stream_Ready  <= FALSE when grid_row + grid_col + grid_chn = 3 and not Transfer_Complete else TRUE;
    grid_hold     <= FALSE when Stream_Valid and Stream_Ready else TRUE;

end Behavioral;
