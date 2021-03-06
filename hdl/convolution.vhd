----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: convolution
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description:
--              Fully unrolled convolution module. Realizes a modular and 
--              scalable building block that can be used to define a variety of
--              convolutional layer types by using generic parameters. 
--              Parameters allow the module to support any image size or input
--              feature map of four or less dimensions.
--
--              This module is designed as a fully loop-unrolled single-clock 
--              convolution accelerator. This means that a successful
--              implementation will process one full image (or feature map)
--              input in just one clock cycle. If desired, all kernel weights
--              can be updated for every image that is processed. The obvious
--              drawback to this fully parallelized implementation is the high
--              utilization of logic slice look-up tables (LUTs).
----------------------------------------------------------------
-- 
-- Dependencies: VHDL-2008
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
-- convolution.vhd

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
library xil_defaultlib;
use xil_defaultlib.mypackage.ALL;

entity convolution is
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
    Kernel_Weights  : in GridType(  
      1 to KERNEL_SIZE,
      1 to KERNEL_SIZE,
      1 to CHANNELS_IN * CHANNELS_OUT
      ) (GRADIENT_BITS - 1 downto 0);
    Output_Feature  : out GridType( 
      1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
      1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
      1 to CHANNELS_OUT
      ) (GRADIENT_BITS - 1 downto 0)
  );
end convolution;

architecture Behavioral of convolution is

  -- Prevents overflow during summation (subtract one because signed)
  constant BITS4SUM : integer := integer(ceil(log2(real(KERNEL_SIZE**2)))) - 1;

  -- Grid after applying zero-padding
  signal Padded_Image : GridType(
    1 to IMAGE_SIZE + 2 * ZERO_PADDING,
    1 to IMAGE_SIZE + 2 * ZERO_PADDING,
    1 to CHANNELS_IN
    ) (GRADIENT_BITS - 1 downto 0);

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

  --------------- Convolution Process --------------
  convolution_process : process(Aclk, Aresetn)
    variable feature_sum : signed(2 * GRADIENT_BITS + BITS4SUM - 1 downto 0);
  begin
    if Aresetn = '0' then
      Output_Feature <= (others => (others => (others => (others => '0'))));
    elsif rising_edge(Aclk) then
      for conv_row in Output_Feature'range(1) loop
        for conv_col in Output_Feature'range(2) loop
          for conv_chn in Output_Feature'range(3) loop
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
          end loop;
        end loop;
      end loop;
    end if;
  end process;
  --------------------------------------------------

end Behavioral;
