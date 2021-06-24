----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date: 
-- Design Name: 
-- Module Name: folded_pool
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
-- 
-- Dependencies: VHDL-2008
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

entity folded_pool is
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
        Input_Ready     : out boolean;
        Input_Valid     : in boolean;
        Feature_Out     : out GridType( 
            1 to FEATURE_SIZE/POOL_SIZE,
            1 to FEATURE_SIZE/POOL_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS-1 downto 0);
        Output_Ready    : in boolean;
        Output_Valid    : out boolean
    );
end folded_pool;

architecture Behavioral of folded_pool is

    signal hold : boolean;
    signal row  : 
    signal row : integer range Feature_Out'range(1);
    signal col : integer range Feature_Out'range(2);
    signal channel : integer range Feature_Out'range(3);

begin

    process(Aclk, Aresetn)
        variable max_val : signed(GRADIENT_BITS-1 downto 0);
    begin
        if Aresetn = '0' then
            Input_Ready <= TRUE;
            Output_Valid <= FALSE;
            Feature_Out <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            ---------------MAX FUNCTION--------------
            max_val := (max_val'high => '1', others => '0');
            for ri in (row - 1) * POOL_SIZE + 1 to row * POOL_SIZE loop
                for ci in (col - 1) * POOL_SIZE + 1 to col * POOL_SIZE loop
                    if Feature_In(ri, ci, channel) > max_val then
                        max_val := Feature_In(ri, ci, channel);
                    end if;
                end loop;
            end loop;
            Feature_Out(row, col, channel) <= max_val;
            -----------------------------------------
            if (not Input_Ready) and (not Output_Valid) and (row = Feature_Out'high(1)) and (col = Feature_Out'high(2)) and (channel = Feature_Out'high(3)) then
                Input_Ready <= TRUE;
                Output_Valid <= TRUE;
            elsif Input_Ready and Input_Valid and Output_Ready then
                Input_Ready <= FALSE;
                Output_Valid <= FALSE;
            end if;
        end if;
    end process;

    iterator_pool_folding : grid_iterator
        generic map (
            GRID_SIZE       => Feature_Out'high(1),
            CHANNEL_COUNT   => Feature_Out'high(3)
            )
        port map (
            Aclk    => Aclk,
            Aresetn => Aresetn,
            hold    => Input_Ready,
            row     => row,
            column  => col,
            channel => channel
            );

end Behavioral;

