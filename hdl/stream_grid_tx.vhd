   ----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date: 11/28/2019 09:17:28 PM
-- Design Name: 
-- Module Name: stream_grid_tx
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
--              Used for streaming data to/from folded_conv_v2 module
-- 
-- Dependencies: VHDL-2008
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
-- stream_grid_tx.vhd

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
library xil_defaultlib;
use xil_defaultlib.mypackage.ALL;

entity stream_grid_tx is
  Generic (
    GRID_SIZE       : natural := 6;
    CHANNEL_COUNT   : natural := 3;
    GRADIENT_BITS   : natural := 8
  );
  Port (
    Aclk     : in std_logic;
    Aresetn  : in std_logic;
    -- AXIS
    Stream_Data     : out std_logic_vector(GRADIENT_BITS-1 downto 0);
    Stream_Valid    : out boolean;
    Stream_Ready    : in boolean;
    -- Data
    Grid_Data : in GridType(
      1 to GRID_SIZE,
      1 to GRID_SIZE,
      1 to CHANNEL_COUNT
      ) (GRADIENT_BITS - 1 downto 0);
    -- Control
    Transfer_Complete   : in boolean;
    Stream_Complete     : out boolean
  );
end stream_grid_tx;

architecture Behavioral of stream_grid_tx is

  signal grid_hold : boolean;
  signal grid_row : integer range Grid_Data'range(1);
  signal grid_col : integer range Grid_Data'range(2);
  signal grid_chn : integer range Grid_Data'range(3);

begin

  process(Aclk, Aresetn)
  begin
    if Aresetn = '0' then
      Stream_Complete <= FALSE;
      Stream_Data <= (others => '0');
    elsif rising_edge(Aclk) then
      -------------------------
      if not grid_hold then
        Stream_Data <= std_logic_vector(Grid_Data(grid_row, grid_col, grid_chn));
      end if;
      -------------------------
      if (not Stream_Complete)  and (grid_row = Grid_Data'high(1)) 
                                and (grid_col = Grid_Data'high(2)) 
                                and (grid_chn = Grid_Data'high(3)) then
        Stream_Complete <= TRUE;
      elsif Transfer_Complete then
        Stream_Complete <= FALSE;
      end if;
      -------------------------
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

  Stream_Valid <= Transfer_Complete or (not Stream_Complete);
  grid_hold    <= (not Stream_Valid) or (not Stream_Ready);

end Behavioral;

