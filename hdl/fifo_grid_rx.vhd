----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: fifo_grid_rx - Behavioral
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

entity fifo_grid_rx is
    Generic (
    	GRADIENT_BITS : natural := 8
    );
    Port (
        Aclk         : in std_logic;
        Aresetn      : in std_logic;
        -- AXIS
        AXIS_FIFO_Data 		: in std_logic_vector(GRADIENT_BITS-1 downto 0);
        AXIS_FIFO_Valid  	: in std_logic;
        AXIS_FIFO_Ready  	: out std_logic;
        -- 
        Fifo_Grid : out GridType(
	        1 to IMAGE_SIZE,
	        1 to IMAGE_SIZE,
	        1 to CHANNEL_COUNT
	        ) (GRADIENT_BITS - 1 downto 0);

        transfer_complete 	: in boolean;
        stream_in_complete 	: out boolean
    );
end fifo_grid_rx;

architecture Behavioral of fifo_grid_rx is

    signal fifo_hold : boolean;
    signal fifo_row : integer range Fifo_Grid'range(1);
    signal fifo_col : integer range Fifo_Grid'range(2);
    signal fifo_chn : integer range Fifo_Grid'range(3);

begin

    ---------------- RX in image FIFO ----------------
    process(Aclk, Aresetn)
    begin
        if Aresetn = '0' then
            Fifo_Grid <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            if not fifo_hold then
                Fifo_Grid(fifo_row, fifo_col, fifo_chn) <= AXIS_FIFO_Data;
            end if;
        end if;
    end process;

    iterator_fifo_grid : feature_iterator
        generic map (
            FEATURE_SIZE    => Fifo_Grid'high(1),
            CHANNEL_COUNT   => Fifo_Grid'high(3)
            )
        port map (
            Aclk    => Aclk,
            Aresetn => Aresetn,
            hold    => fifo_hold,
            row     => fifo_row,
            column  => fifo_col,
            channel => fifo_chn
            );

    stream_in_complete  <= TRUE when fifo_row + fifo_col + fifo_chn = 3 and not transfer_complete else FALSE;
    AXIS_FIFO_Ready     <= not stream_in_complete;
    fifo_hold     		<= FALSE when AXIS_FIFO_Valid and AXIS_FIFO_Ready else TRUE;
    --------------------------------------------------

end Behavioral;
