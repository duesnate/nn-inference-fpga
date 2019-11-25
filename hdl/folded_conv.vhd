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
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        -- Image Stream Width:   Wi = 8*ceil(B*Ch*I**2/(8*C)) -- Image_Stream    : in std_logic_vector(8 * ceil(GRADIENT_BITS * IMAGE_SIZE**2 / (8 * ((IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1)**2)));
        Image_Stream : in std_logic_vector(GRADIENT_BITS-1 downto 0);
        Image_Valid  : in std_logic;
        Image_Ready  : out std_logic;
        -- Kernel Stream Width:  Wk = 8*ceil(B*Ch*K**2/(8*C)) -- Kernel_Stream   : in std_logic_vector(8 * ceil(GRADIENT_BITS * IMAGE_SIZE**2 / (8 * ((IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1)**2)));
        Kernel_Stream : in std_logic_vector(GRADIENT_BITS-1 downto 0);
        -- Feature Stream Width: Wf = 8*ceil(B/8) -- Feature_Stream  : out std_logic_vector(8 * ceil(GRADIENT_BITS / 8))
        Feature_Stream : out std_logic_vector(GRADIENT_BITS-1 downto 0);
        Feature_Valid  : out std_logic;
        Feature_Ready  : in std_logic
    );
end folded_conv;

architecture Behavioral of folded_conv is

    -- Prevents overflow of summation
    constant BITS4SUM : integer := integer(ceil(log2(real(KERNEL_SIZE**2))));

    signal Fifo_Image : GridType(
        1 to IMAGE_SIZE,
        1 to IMAGE_SIZE,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    signal Input_Image : GridType(
        1 to IMAGE_SIZE,
        1 to IMAGE_SIZE,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    signal Image_Padded : GridType(
        1 to IMAGE_SIZE + 2 * ZERO_PADDING,
        1 to IMAGE_SIZE + 2 * ZERO_PADDING,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    signal Kernel_Weights : GridType(
        1 to KERNEL_SIZE,
        1 to KERNEL_SIZE,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    signal Feature_Map : out GridType(
        1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
        1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    type stateType is (CHN_STATE, COL_STATE, ROW_STATE);
    
    signal conv_hold : boolean;
    signal conv_row : integer range Feature_Map'range(1);
    signal conv_col : integer range Feature_Map'range(2);
    signal conv_chn : integer range Feature_Map'range(3);
    signal fifo_hold : boolean;
    signal fifo_row : integer range Feature_Map'range(1);
    signal fifo_col : integer range Feature_Map'range(2);
    signal fifo_chn : integer range Feature_Map'range(3);

begin

    -- Data-flow controller
    process(Aclk, Aresetn)
    begin
        if Aresetn = '0' then
            transfer_complete <= FALSE;
            Input_Image <= (others => (others => (others => (others => '0'))));
            Fifo_Feature <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            if transfer_complete then
                transfer_complete <= FALSE;
            elsif stream_in_complete and convolution_complete and stream_out_complete then
                Input_Image <= Fifo_Image;
                Fifo_Feature <= Feature_Map;
                transfer_complete <= TRUE;
            end if;
        end if;
    end process;

    iterator_fifo_image : feature_iterator
        generic map (
            FEATURE_SIZE    => Fifo_Image'high(1),
            CHANNEL_COUNT   => Fifo_Image'high(3)
            )
        port map (
            Aclk    => Aclk,
            Aresetn => Aresetn,
            hold    => fifo_hold,
            row     => fifo_row,
            column  => fifo_col,
            channel => fifo_chn
            );

    fifo_hold <= TRUE when (Image_Valid = '0') or ( (fifo_row + fifo_col + fifo_chn = 3) and (not transfer_complete) ) else FALSE;

    Image_Ready <= not fifo_hold;

    -- Store image in FIFO
    process(Aclk, Aresetn)
    begin
        if Aresetn = '0' then
            stream_in_complete <= FALSE;
            Fifo_Image <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            if fifo_row + fifo_col + fifo_chn = fifo_row'high + fifo_col'high + fifo_chn'high then
                stream_in_complete <= TRUE;
            else
                Fifo_Image(fifo_row, fifo_col, fifo_chn) <= Image_Stream;
                stream_in_complete <= FALSE;
            end if;
        end if;
    end process;

    -- Generate zero-padded image
    gen_row: for row in Image_Padded'range(1) generate
        gen_col: for col in Image_Padded'range(2) generate
            gen_chl: for chn in Image_Padded'range(3) generate
                -- Fill with input image when out of padding range
                gen_zp: if  (row > ZERO_PADDING) and 
                            (col > ZERO_PADDING) and 
                            (row <= Image_Padded'high(1) - ZERO_PADDING) and 
                            (col <= Image_Padded'high(2) - ZERO_PADDING) generate
                    Image_Padded(row, col, chn) <= Input_Image(row - ZERO_PADDING, col - ZERO_PADDING, chn);
                else generate
                    Image_Padded(row, col, chn) <= (others => '0');
                end generate gen_zp;
            end generate gen_chl;
        end generate gen_col;
    end generate gen_row;

    -- Compute convolution
    process(Aclk, Aresetn)
        variable feature_sum : signed(2 * GRADIENT_BITS + BITS4SUM - 1 downto 0);
    begin
        if Aresetn = '0' then
            convolution_complete <= FALSE;
            Feature_Map <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(Aclk) then
            if conv_row + conv_col + conv_chn >= conv_row'high + conv_col'high + conv_chn'high then
                convolution_complete <= TRUE;
            else
                convolution_complete <= FALSE;
            end if;

            -- Clear summation
            feature_sum := (others => '0');
            for row in Kernel_Weights'range(1) loop
                for column in Kernel_Weights'range(2) loop
                    ----- Multiply Accumulate -----
                    feature_sum := feature_sum
                        -- Add Input Neuron
                        + Image_Padded(
                            STRIDE_STEPS * (conv_row - 1) + row, 
                            STRIDE_STEPS * (conv_col - 1) + column, 
                            conv_chn)
                        -- Multiplied by Kernel Weight
                        * Kernel_Weights(row, column, conv_chn);
                    -------------------------------
                end loop;
            end loop;
            -- Scale down Result
            Feature_Map(conv_row, conv_col, conv_chn) <= feature_sum(feature_sum'high downto feature_sum'high - GRADIENT_BITS + 1);
        end if;
    end process;

    -- Convolution folding iterator state machine
    iterator_conv_folding : feature_iterator
        generic map (
            FEATURE_SIZE    => Feature_Map'high(1),
            CHANNEL_COUNT   => Feature_Map'high(3)
            )
        port map (
            Aclk    => Aclk,
            Aresetn => Aresetn,
            hold    => conv_hold,
            row     => conv_row,
            column  => conv_col,
            channel => conv_chn
            );

    conv_hold <= TRUE when (conv_row + conv_col + conv_chn = 3) and (not transfer_complete) else FALSE;

end Behavioral;


-- Stream image in | convolve image | stream feature out
-- Transfer image for conv | transfer feature from conv


