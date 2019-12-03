----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: folded_conv - Behavioral
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

entity folded_conv is
    Generic (
        IMAGE_SIZE      : natural := 24;    -- I
        KERNEL_SIZE     : natural := 9;     -- K
        CHANNEL_COUNT   : natural := 3;     -- Ch
        GRADIENT_BITS   : natural := 8;     -- B
        STRIDE_STEPS    : natural := 1;     -- S
        ZERO_PADDING    : integer := 0;     -- P
        RELU_ACTIVATION : boolean := TRUE
        -- Feature Size: F = (I+2*P-K)/S + 1
        -- Clock Cycles: C = Ch*F**2
    );
    Port (
        Aclk           : in std_logic;
        Aresetn        : in std_logic;
        -- Image Stream Width:   Wi = 8*ceil(B*Ch*I**2/(8*C)) -- Image_Stream    : in std_logic_vector(8 * ceil(GRADIENT_BITS * IMAGE_SIZE**2 / (8 * ((IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1)**2)));
        Image_Stream   : in std_logic_vector(GRADIENT_BITS-1 downto 0);
        Image_Valid    : in boolean;
        Image_Ready    : out boolean;
        -- Kernel Stream Width:  Wk = 8*ceil(B*Ch*K**2/(8*C)) -- Kernel_Stream   : in std_logic_vector(8 * ceil(GRADIENT_BITS * IMAGE_SIZE**2 / (8 * ((IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1)**2)));
        Kernel_Stream  : in std_logic_vector(GRADIENT_BITS-1 downto 0);
        Kernel_Valid   : in boolean;
        Kernel_Ready   : out boolean;
        -- Feature Stream Width: Wf = 8*ceil(B/8) -- Feature_Stream  : out std_logic_vector(8 * ceil(GRADIENT_BITS / 8))
        Feature_Stream : out std_logic_vector(GRADIENT_BITS-1 downto 0);
        Feature_Valid  : out boolean;
        Feature_Ready  : in boolean
    );
end folded_conv;

architecture Behavioral of folded_conv is

    -- Prevents overflow during summation (subtract one because signed)
    constant BITS4SUM : integer := integer(ceil(log2(real(KERNEL_SIZE**2)))) - 1;

    signal Input_Image : GridType(
        1 to IMAGE_SIZE,
        1 to IMAGE_SIZE,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    signal Conv_Image : GridType(
        1 to IMAGE_SIZE,
        1 to IMAGE_SIZE,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    signal Input_Kernel : GridType(
        1 to KERNEL_SIZE,
        1 to KERNEL_SIZE,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    signal Conv_Kernel : GridType(
        1 to KERNEL_SIZE,
        1 to KERNEL_SIZE,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    signal Conv_Feature : GridType(
        1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
        1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    signal Output_Feature : GridType(
        1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
        1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);
    
    -- MAC iterator signals
    signal mac_hold : boolean;
    signal mac_row  : integer range Conv_Kernel'range(1);
    signal mac_col  : integer range Conv_Kernel'range(2);

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
            CHANNEL_COUNT   => CHANNEL_COUNT,
            GRADIENT_BITS   => GRADIENT_BITS,
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
            mac_hold            => mac_hold,
            mac_row             => mac_row,
            mac_col             => mac_col,
            conv_hold           => conv_hold,
            conv_row            => conv_row,
            conv_col            => conv_col,
            conv_chn            => conv_chn,
            transfer_complete   => transfer_complete
            );

    -- MAC folding iterator state machine
    iterator_mac_folding : grid_iterator
        generic map (
            GRID_SIZE       => Conv_Kernel'high(1),
            CHANNEL_COUNT   => 1
            )
        port map (
            Aclk    => Aclk,
            Aresetn => Aresetn,
            hold    => mac_hold,
            row     => mac_row,
            column  => mac_col,
            channel => open
            );
    mac_hold <= (conv_complete and (not transfer_complete))
                or ((mac_row = Conv_Kernel'high(1)) 
                and (mac_col = Conv_Kernel'high(2)) 
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
    conv_hold <= (not ((mac_row = Conv_Kernel'high(1)) and (mac_col = Conv_Kernel'high(2)))) or conv_complete;
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

