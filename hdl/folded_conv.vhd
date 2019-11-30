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
        ZERO_PADDING    : integer := 0      -- P
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

    -- Prevents overflow during summation
    constant BITS4SUM : integer := integer(ceil(log2(real(KERNEL_SIZE**2))));

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

    signal Padded_Image : GridType(
        1 to IMAGE_SIZE + 2 * ZERO_PADDING,
        1 to IMAGE_SIZE + 2 * ZERO_PADDING,
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
    
    -- Convolution iterator signals
    signal conv_hold : boolean;
    signal conv_row : integer range Conv_Feature'range(1);
    signal conv_col : integer range Conv_Feature'range(2);
    signal conv_chn : integer range Conv_Feature'range(3);

    -- Data-flow control signals
    signal convolution_complete : boolean;
    signal all_iters_complete   : boolean;
    signal transfer_complete    : boolean;

begin

    --------------- Data-flow controller -------------
    process(Aclk, Aresetn)
    begin
        if Aresetn = '0' then
            transfer_complete <= FALSE;
            Conv_Kernel     <= (others => (others => (others => (others => '0'))));
            Conv_Image      <= (others => (others => (others => (others => '0'))));
            Output_Feature  <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            if transfer_complete then
                transfer_complete <= FALSE;
            elsif all_iters_complete and Kernel_Valid and Image_Valid and Feature_Ready then
                Conv_Kernel <= Input_Kernel;
                Conv_Image <= Input_Image;
                Output_Feature <= Conv_Feature;
                transfer_complete <= TRUE;
            end if;
        end if;
    end process;
    all_iters_complete <= (not Image_Ready) and (not Kernel_Ready) and convolution_complete and (not Feature_Valid);
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
            Transfer_Complete   => transfer_complete
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
            Transfer_Complete   => transfer_complete
            );
    --------------------------------------------------

    ----------- Generate zero-padded image -----------
    gen_row: for row in Padded_Image'range(1) generate
        gen_col: for col in Padded_Image'range(2) generate
            gen_chl: for chn in Padded_Image'range(3) generate
                -- Fill with input image when out of padding range
                gen_zp: if  (row > ZERO_PADDING) and 
                            (col > ZERO_PADDING) and 
                            (row <= Padded_Image'high(1) - ZERO_PADDING) and 
                            (col <= Padded_Image'high(2) - ZERO_PADDING) generate
                    Padded_Image(row, col, chn) <= Conv_Image(row - ZERO_PADDING, col - ZERO_PADDING, chn);
                else generate
                    Padded_Image(row, col, chn) <= (others => '0');
                end generate gen_zp;
            end generate gen_chl;
        end generate gen_col;
    end generate gen_row;
    --------------------------------------------------

    --------------- Compute convolution --------------
    process(Aclk, Aresetn)
        variable feature_sum : signed(2 * GRADIENT_BITS + BITS4SUM - 1 downto 0);
    begin
        if Aresetn = '0' then
            Conv_Feature <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            feature_sum := (others => '0');
            for row in Conv_Kernel'range(1) loop
                for column in Conv_Kernel'range(2) loop
                    ----- Multiply Accumulate -----
                    feature_sum := feature_sum
                        -- Add Input Neuron
                        + Padded_Image(
                            STRIDE_STEPS * (conv_row - 1) + row, 
                            STRIDE_STEPS * (conv_col - 1) + column, 
                            conv_chn)
                        -- Multiplied by Kernel Weight
                        * Conv_Kernel(row, column, conv_chn);
                    -------------------------------
                end loop;
            end loop;
            -- Scale down Result
            Conv_Feature(conv_row, conv_col, conv_chn) <= feature_sum(feature_sum'high downto feature_sum'high - GRADIENT_BITS + 1);
        end if;
    end process;

    convolution_complete <= TRUE when conv_row + conv_col + conv_chn = 3 and not transfer_complete else FALSE;

    -- Convolution folding iterator state machine
    iterator_conv_folding : grid_iterator
        generic map (
            GRID_SIZE    => Conv_Feature'high(1),
            CHANNEL_COUNT   => Conv_Feature'high(3)
            )
        port map (
            Aclk    => Aclk,
            Aresetn => Aresetn,
            hold    => convolution_complete,
            row     => conv_row,
            column  => conv_col,
            channel => conv_chn
            );
    --------------------------------------------------

    -------------- TX out feature grid ---------------
    grid_tx_kernel : stream_grid_tx
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
            Transfer_Complete   => transfer_complete
            );
    --------------------------------------------------

end Behavioral;


