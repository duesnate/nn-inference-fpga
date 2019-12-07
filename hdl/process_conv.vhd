----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/02/2019 09:17:28 PM
-- Design Name: 
-- Module Name: process_conv - Behavioral
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

entity process_conv is
  Generic (
    IMAGE_SIZE      : natural := 24;    -- I
    KERNEL_SIZE     : natural := 9;     -- K
    CHANNEL_COUNT   : natural := 3;     -- Ch
    GRADIENT_BITS   : natural := 8;     -- B
    STRIDE_STEPS    : natural := 1;     -- S
    ZERO_PADDING    : integer := 0;     -- P
    RELU_ACTIVATION : boolean := TRUE
    -- Feature Size: F = (I+2*P-K)/S + 1
    -- Clock Cycles: C = Ch * K**2 * F**2
    );
  Port (
    Aclk    : in std_logic;
    Aresetn : in std_logic;
    Conv_Image : in GridType(
      1 to IMAGE_SIZE,
      1 to IMAGE_SIZE,
      1 to CHANNEL_COUNT
      ) (GRADIENT_BITS - 1 downto 0);
    Conv_Kernel : in GridType(
      1 to KERNEL_SIZE,
      1 to KERNEL_SIZE,
      1 to CHANNEL_COUNT
      ) (GRADIENT_BITS - 1 downto 0);
    Conv_Feature : out GridType(
      1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
      1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
      1 to CHANNEL_COUNT
      ) (GRADIENT_BITS - 1 downto 0);
    mac_hold            : in boolean;
    mac_row             : in integer range 1 to KERNEL_SIZE;
    mac_col             : in integer range 1 to KERNEL_SIZE;
    conv_hold           : in boolean;
    conv_row            : in integer range 1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1;
    conv_col            : in integer range 1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1;
    conv_chn            : in integer range 1 to CHANNEL_COUNT;
    transfer_complete   : in boolean;
    conv_complete       : out boolean
    );
end process_conv;

architecture Behavioral of process_conv is

  -- Prevents overflow during summation (subtract one because signed)
  constant BITS4SUM : integer := integer(ceil(log2(real(KERNEL_SIZE**2)))) - 1;

  signal Padded_Image : GridType(
    1 to IMAGE_SIZE + 2 * ZERO_PADDING,
    1 to IMAGE_SIZE + 2 * ZERO_PADDING,
    1 to CHANNEL_COUNT
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
          Padded_Image(row, col, chn) <= Conv_Image(row - ZERO_PADDING, col - ZERO_PADDING, chn);
        else generate
          Padded_Image(row, col, chn) <= (others => '0');
        end generate gen_zp;
      end generate gen_chn;
    end generate gen_col;
  end generate gen_row;
  --------------------------------------------------

  --------------- Compute convolution --------------
  convolution_process : process(Aclk, Aresetn)
    variable feature_sum : signed(2 * GRADIENT_BITS + BITS4SUM - 1 downto 0);
  begin
    if Aresetn = '0' then
      conv_complete <= FALSE;
      feature_sum := (others => '0');
      Conv_Feature <= (others => (others => (others => (others => '0'))));
    elsif rising_edge(Aclk) then
      if not conv_complete then
        ----- Multiply Accumulate -----
        feature_sum := feature_sum
          -- Add Input Neuron
          + Padded_Image(
            STRIDE_STEPS * (conv_row - 1) + mac_row, 
            STRIDE_STEPS * (conv_col - 1) + mac_col, 
            conv_chn)
          -- Multiplied by Kernel Weight
          * Conv_Kernel(mac_row, mac_col, conv_chn);
        -------------------------------
        if not conv_hold then
          -- Apply ReLU activation
          if RELU_ACTIVATION and to_integer(feature_sum) < 0 then
            Conv_Feature(conv_row, conv_col, conv_chn) <= (others => '0');
          else
            -- Scale down Result
            Conv_Feature(conv_row, conv_col, conv_chn) 
              <= feature_sum(feature_sum'high downto feature_sum'high - GRADIENT_BITS + 1);
          end if;
          feature_sum := (others => '0');
          -- Check if convolution is complete
          if mac_hold then
            conv_complete <= TRUE;
          end if;
        end if;
        -------------------------------
      elsif transfer_complete then
        conv_complete <= FALSE;
      end if;
    end if;
  end process;
  --------------------------------------------------

end Behavioral;

