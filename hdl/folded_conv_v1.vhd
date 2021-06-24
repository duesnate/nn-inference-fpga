----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: folded_conv_v1
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
--              This design applied folding such that each kernel step required
--              one clock cycle. This extended the convolution operation over a
--              number of clocks equal to the number of neurons in the 
--              feature-map output. For example, an 8x8 3-channel input with a
--              4x4 kernel would require 3*(8-4+1)^2 = 75 clocks. In this
--              design, a 4x4 kernel will instantiate logic for 16 individual
--              multipliers and 15 adders in order to process the MACC operation
--              in a single clock. By time-multiplexing numerous MACC operations
--              on a single instance, this design provided great improvements in
--              resource usage.
--
--              Large kernels on this design will continue to prove difficult 
--              for resource constrained applications and is especially 
--              difficult for timing closure. The number of values to be summed 
--              in a MACC operation is equal to the number of weights in the 
--              kernel. For example, an 8x8 kernel would require 63 addition 
--              operations to be resolved before the next rising clock edge. As 
--              kernel sizes increase even further, place-and-route tools will 
--              have difficulty implementing physical logic that satisfies even 
--              a relatively slow running clock.
----------------------------------------------------------------
--
-- Dependencies: VHDL-2008
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
-- folded_conv_v1.vhd

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
library xil_defaultlib;
use xil_defaultlib.mypackage.ALL;

entity folded_conv_v1 is
  Generic(
    IMAGE_SIZE      : positive;
    KERNEL_SIZE     : positive;
    CHANNELS_IN     : positive;
    GRADIENT_BITS   : positive;
    CHANNELS_OUT    : positive;
    STRIDE_STEPS    : positive;
    ZERO_PADDING    : natural;
    RELU_ACTIVATION : boolean
  );
  Port (  
    Aclk            : in std_logic;
    Aresetn         : in std_logic;
    Input_Image     : in GridType(  
      1 to IMAGE_SIZE,
      1 to IMAGE_SIZE,
      1 to CHANNELS_IN
      ) (GRADIENT_BITS - 1 downto 0);
    Kernel_Weights    : in GridType(  
      1 to KERNEL_SIZE,
      1 to KERNEL_SIZE,
      1 to CHANNELS_IN * CHANNELS_OUT
      ) (GRADIENT_BITS - 1 downto 0);
    Output_Feature  : out GridType( 
      1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
      1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
      1 to CHANNELS_OUT
      ) (GRADIENT_BITS - 1 downto 0);
    conv_complete   : out boolean
  );
end folded_conv_v1;

architecture Behavioral of folded_conv_v1 is

  -- Prevents overflow during summation (subtract one because signed)
  constant BITS4SUM : integer := integer(ceil(log2(real(KERNEL_SIZE**2)))) - 1;

  -- Grid after applying zero-padding
  signal Padded_Image : GridType(
    1 to IMAGE_SIZE + 2 * ZERO_PADDING,
    1 to IMAGE_SIZE + 2 * ZERO_PADDING,
    1 to CHANNELS_IN
    ) (GRADIENT_BITS - 1 downto 0);

  -- Convolution iterator signals
  signal conv_row  : integer range Output_Feature'range(1);
  signal conv_col  : integer range Output_Feature'range(2);
  signal conv_chn  : integer range Output_Feature'range(3);

  signal conv_edge : boolean;

begin

  ----------- Generate zero-padded image -----------
  gen_row : for row in Padded_Image'range(1) generate
    gen_col : for col in Padded_Image'range(2) generate
      gen_chn : for chn in Padded_Image'range(3) generate
        -- Fill with input image when out of padding range
        gen_zp : if (row > ZERO_PADDING) and 
              (col > ZERO_PADDING) and 
              (row <= Padded_Image'high(1) - ZERO_PADDING) and 
              (col <= Padded_Image'high(2) - ZERO_PADDING) generate
          Padded_Image(row, col, chn) <= Input_Image(row - ZERO_PADDING, col - ZERO_PADDING, chn);
        else generate
          Padded_Image(row, col, chn) <= (others => '0');
        end generate gen_zp;
      end generate gen_chn;
    end generate gen_col;
  end generate gen_row;
  --------------------------------------------------

  --------------- Compute convolution --------------
  process(Aclk, Aresetn)
    variable feature_sum : signed(2 * GRADIENT_BITS + BITS4SUM - 1 downto 0);
  begin
    if Aresetn = '0' then
      Output_Feature <= (others => (others => (others => (others => '0'))));
    elsif rising_edge(Aclk) then
      -- Clear summation
      feature_sum := (others => '0');
      -- Un-rolled MACC operations
      for macc_row in Kernel_Weights'range(1) loop
        for macc_col in Kernel_Weights'range(2) loop
          for macc_chn in 1 to CHANNELS_IN loop
            ----- Multiply Accumulate -----
            feature_sum := feature_sum
              -- Add Input Neuron
              + Padded_Image(
                STRIDE_STEPS * (conv_row - 1) + macc_row, 
                STRIDE_STEPS * (conv_col - 1) + macc_col, 
                macc_chn)
              -- Multiplied by Kernel Weight
              * Kernel_Weights(
                macc_row, 
                macc_col, 
                CHANNELS_IN * (conv_chn - 1) + macc_chn);
            -------------------------------
          end loop;
        end loop;
      end loop;
      -- Apply ReLU activation
      if RELU_ACTIVATION and to_integer(feature_sum) < 0 then
        Output_Feature(conv_row, conv_col, conv_chn) <= (others => '0');
      else
        -- Scale down Result
        Output_Feature(conv_row, conv_col, conv_chn) 
          <= feature_sum(feature_sum'high downto feature_sum'high - GRADIENT_BITS + 1);
      end if;
    end if;
  end process;

  -- Convolution folding iterator state machine
  iterator_conv_folding : grid_iterator
    generic map (
      GRID_SIZE       => Output_Feature'high(1),
      CHANNEL_COUNT   => Output_Feature'high(3)
      )
    port map (
      Aclk    => Aclk,
      Aresetn => Aresetn,
      hold    => conv_complete,
      row     => conv_row,
      column  => conv_col,
      channel => conv_chn
      );
  conv_complete <= not conv_edge and (
                  (conv_row = Output_Feature'high(1)) 
              and (conv_col = Output_Feature'high(2))
              and (conv_chn = Output_Feature'high(3)));
  process(Aclk, Aresetn)
  begin
    if Aresetn = '0' then
      conv_edge <= FALSE;
    elsif rising_edge(Aclk) then
      conv_edge <= conv_complete;
    end if;
  end process;
  --------------------------------------------------

end Behavioral;
