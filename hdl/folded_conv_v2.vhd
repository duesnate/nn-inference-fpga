----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: folded_conv_v2
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
--              This design applies additional folding of the convolution block 
--              such that a single MACC will now sequentially process the entire 
--              convolution using just one multiply and one addition. The number 
--              of clocks required for this implementation will be equal to the 
--              number of neuron outputs multiplied by the number of weights in 
--              the kernel. The same 8x8 3-channel input with a 4x4 kernel will 
--              now require 3*4^2*(8-4+1)^2 = 1200 clock cycles to complete. 
--              Although this will provide additional resource savings, it will 
--              be at the cost of much greater latency and throughput.
--            
--              Additional resources are required to facilitate coordination of 
--              iterative operation sequences and in-turn drives up design 
--              complexity. The high degree of folding applied using iterator 
--              modules and data-flow logic in this design demonstrated poor 
--              resource utilization trade-offs given the massive increase in 
--              throughput and latency. Much of the logic resources saved by the 
--              reduction in MACC units was consumed by the additional iterator 
--              control logic required to orchestrate the folding process. This 
--              implementation method can certainly be changed, optimized, and 
--              improved upon in order to achieve greater efficiency trade-offs. 
--              The effort to make these improvements is difficult to justify 
--              though because a "fully-folded" sequential architecture will in 
--              a way defeat the purpose of using FPGAs to begin with. 
--              Regardless, this design exercise was beneficial for both the 
--              analysis and experience provided.
--
--              This design incorporates an input and output data streaming 
--              architecture for the input image and kernel weights and output 
--              feature map using streaming modules.
----------------------------------------------------------------
-- 
-- Dependencies: VHDL-2008
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
-- folded_conv_v2.vhd

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
library xil_defaultlib;
use xil_defaultlib.mypackage.ALL;

entity folded_conv_v2 is
  Generic (
    IMAGE_SIZE      : positive;     -- I
    KERNEL_SIZE     : positive;     -- K
    CHANNELS_IN     : positive;     -- Ci
    GRADIENT_BITS   : positive;     -- B
    CHANNELS_OUT    : positive;     -- Co
    STRIDE_STEPS    : positive;     -- S
    ZERO_PADDING    : natural;      -- P
    RELU_ACTIVATION : boolean
    -- Feature Size: F = (I+2*P-K)/S + 1
    -- Clock Cycles: C = Ci*Co*F**2
  );
  Port (
    Aclk           : in std_logic;
    Aresetn        : in std_logic;
    Image_Stream   : in std_logic_vector(GRADIENT_BITS-1 downto 0);
    Image_Valid    : in boolean;
    Image_Ready    : out boolean;
    Kernel_Stream  : in std_logic_vector(GRADIENT_BITS-1 downto 0);
    Kernel_Valid   : in boolean;
    Kernel_Ready   : out boolean;
    Feature_Stream : out std_logic_vector(GRADIENT_BITS-1 downto 0);
    Feature_Valid  : out boolean;
    Feature_Ready  : in boolean
  );
end folded_conv_v2;

architecture Behavioral of folded_conv_v2 is

  -- Prevents overflow during summation (subtract one because signed)
  constant BITS4SUM : integer := integer(ceil(log2(real(KERNEL_SIZE**2)))) - 1;

  signal Input_Image : GridType(
    1 to IMAGE_SIZE,
    1 to IMAGE_SIZE,
    1 to CHANNELS_IN
    ) (GRADIENT_BITS - 1 downto 0);

  signal Conv_Image : GridType(
    1 to IMAGE_SIZE,
    1 to IMAGE_SIZE,
    1 to CHANNELS_IN
    ) (GRADIENT_BITS - 1 downto 0);

  signal Input_Kernel : GridType(
    1 to KERNEL_SIZE,
    1 to KERNEL_SIZE,
    1 to CHANNELS_IN * CHANNELS_OUT
    ) (GRADIENT_BITS - 1 downto 0);

  signal Conv_Kernel : GridType(
    1 to KERNEL_SIZE,
    1 to KERNEL_SIZE,
    1 to CHANNELS_IN * CHANNELS_OUT
    ) (GRADIENT_BITS - 1 downto 0);

  signal Conv_Feature : GridType(
    1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
    1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
    1 to CHANNELS_OUT
    ) (GRADIENT_BITS - 1 downto 0);

  signal Output_Feature : GridType(
    1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
    1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
    1 to CHANNELS_OUT
    ) (GRADIENT_BITS - 1 downto 0);
  
  -- MAC iterator signals
  signal macc_hold : boolean;
  signal macc_row  : integer range Conv_Kernel'range(1);
  signal macc_col  : integer range Conv_Kernel'range(2);
  signal macc_chn  : integer range Conv_Kernel'range(3);

  -- Convolution iterator signals
  signal conv_hold : boolean;
  signal conv_row : integer range Conv_Feature'range(1);
  signal conv_col : integer range Conv_Feature'range(2);
  signal conv_chn : integer range Conv_Feature'range(3);

  -- Data-flow control signals
  signal image_complete       : boolean;
  signal kernel_complete      : boolean;
  signal conv_complete        : boolean;
  signal feature_complete     : boolean;
  signal transfer_complete    : boolean;

begin

  --------------- Data-flow controller -------------
  process_dataflow_control : process(Aclk, Aresetn)
  begin
    if Aresetn = '0' then
      transfer_complete <= FALSE;
      Conv_Kernel     <= (others => (others => (others => (others => '0'))));
      Conv_Image      <= (others => (others => (others => (others => '0'))));
      Output_Feature  <= (others => (others => (others => (others => '0'))));
    elsif rising_edge(Aclk) then
      if transfer_complete then
        transfer_complete <= FALSE;
      elsif image_complete and kernel_complete and conv_complete and feature_complete then
        Conv_Kernel     <= Input_Kernel;
        Conv_Image      <= Input_Image;
        Output_Feature  <= Conv_Feature;
        transfer_complete <= TRUE;
      end if;
    end if;
  end process;
  --------------------------------------------------

  ---------------- RX in image grid ----------------
  grid_rx_image : stream_grid_rx
    generic map(
      GRID_SIZE       => Input_Image'high(1),
      CHANNEL_COUNT   => Input_Image'high(3),
      GRADIENT_BITS   => GRADIENT_BITS
      )
    port map(
      Aclk                => Aclk,
      Aresetn             => Aresetn,
      Stream_Data         => Image_Stream,
      Stream_Valid        => Image_Valid,
      Stream_Ready        => Image_Ready,
      Grid_Data           => Input_Image,
      Transfer_Complete   => transfer_complete,
      Stream_Complete     => image_complete
      );
  --------------------------------------------------

  ---------------- RX in kernel grid ----------------
  grid_rx_kernel : stream_grid_rx
    generic map(
      GRID_SIZE       => Input_Kernel'high(1),
      CHANNEL_COUNT   => Input_Kernel'high(3),
      GRADIENT_BITS   => GRADIENT_BITS
      )
    port map(
      Aclk                => Aclk,
      Aresetn             => Aresetn,
      Stream_Data         => Kernel_Stream,
      Stream_Valid        => Kernel_Valid,
      Stream_Ready        => Kernel_Ready,
      Grid_Data           => Input_Kernel,
      Transfer_Complete   => transfer_complete,
      Stream_Complete     => kernel_complete
      );
  --------------------------------------------------

  --------------- Compute convolution --------------
  convolution_process : process_conv
    generic map (
      IMAGE_SIZE      => IMAGE_SIZE,
      KERNEL_SIZE     => KERNEL_SIZE,
      CHANNELS_IN     => CHANNELS_IN,
      GRADIENT_BITS   => GRADIENT_BITS,
      CHANNELS_OUT    => CHANNELS_OUT,
      STRIDE_STEPS    => STRIDE_STEPS,
      ZERO_PADDING    => ZERO_PADDING,
      RELU_ACTIVATION => RELU_ACTIVATION
      )
    port map (
      Aclk                => Aclk,
      Aresetn             => Aresetn,
      Conv_Image          => Conv_Image,
      Conv_Kernel         => Conv_Kernel,
      Conv_Feature        => Conv_Feature,
      conv_complete       => conv_complete,
      macc_hold           => macc_hold,
      macc_row            => macc_row,
      macc_col            => macc_col,
      macc_chn            => macc_chn,
      conv_hold           => conv_hold,
      conv_row            => conv_row,
      conv_col            => conv_col,
      conv_chn            => conv_chn,
      transfer_complete   => transfer_complete
      );

  -- MACC folding iterator state machine
  iterator_macc_folding : grid_iterator
    generic map (
      GRID_SIZE       => Conv_Kernel'high(1),
      CHANNEL_COUNT   => CHANNELS_IN
      )
    port map (
      Aclk    => Aclk,
      Aresetn => Aresetn,
      hold    => macc_hold,
      row     => macc_row,
      column  => macc_col,
      channel => macc_chn
      );
  macc_hold <= (conv_complete and (not transfer_complete))
            or ((macc_row = Conv_Kernel'high(1)) 
            and (macc_col = Conv_Kernel'high(2)) 
            and (macc_chn = CHANNELS_IN)
            and (conv_row = Conv_Feature'high(1)) 
            and (conv_col = Conv_Feature'high(2)) 
            and (conv_chn = Conv_Feature'high(3)));

  -- Convolution folding iterator state machine
  iterator_conv_folding : grid_iterator
    generic map (
      GRID_SIZE       => Conv_Feature'high(1),
      CHANNEL_COUNT   => Conv_Feature'high(3)
      )
    port map (
      Aclk    => Aclk,
      Aresetn => Aresetn,
      hold    => conv_hold,
      row     => conv_row,
      column  => conv_col,
      channel => conv_chn
      );
  conv_hold <= (not (
    (macc_row = Conv_Kernel'high(1)) and 
    (macc_col = Conv_Kernel'high(2)) and
    (macc_chn = CHANNELS_IN))) or conv_complete;
  --------------------------------------------------

  -------------- TX out feature grid ---------------
  grid_tx_feature : stream_grid_tx
    generic map(
      GRID_SIZE       => Output_Feature'high(1),
      CHANNEL_COUNT   => Output_Feature'high(3),
      GRADIENT_BITS   => GRADIENT_BITS
      )
    port map(
      Aclk                => Aclk,
      Aresetn             => Aresetn,
      Stream_Data         => Feature_Stream,
      Stream_Valid        => Feature_Valid,
      Stream_Ready        => Feature_Ready,
      Grid_Data           => Output_Feature,
      Transfer_Complete   => transfer_complete,
      Stream_Complete     => feature_complete
      );
  --------------------------------------------------

end Behavioral;

