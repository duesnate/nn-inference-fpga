----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2019 09:17:28 PM
-- Design Name: 
-- Module Name: folded_conv_v1 - Behavioral
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

entity folded_conv_v1 is
    Generic(
        IMAGE_SIZE      : natural := 6;
        KERNEL_SIZE     : natural := 4;
        CHANNEL_COUNT   : natural := 1;
        GRADIENT_BITS   : natural := 8;
        STRIDE_STEPS    : natural := 1;
        ZERO_PADDING    : integer := 0;
        RELU_ACTIVATION : boolean := TRUE
    );
    Port (  
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Input_Image     : in GridType(  
            1 to IMAGE_SIZE,
            1 to IMAGE_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS - 1 downto 0);
        Input_Kernel    : in GridType(  
            1 to KERNEL_SIZE,
            1 to KERNEL_SIZE,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS - 1 downto 0);
        Output_Feature  : out GridType( 
            1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
            1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
            1 to CHANNEL_COUNT
            ) (GRADIENT_BITS - 1 downto 0);
        conv_complete : out boolean
    );
end folded_conv_v1;

architecture Behavioral of folded_conv_v1 is

    -- Prevents overflow during summation (subtract one because signed)
    constant BITS4SUM : integer := integer(ceil(log2(real(KERNEL_SIZE**2)))) - 1;

    signal Padded_Image : GridType(
        1 to IMAGE_SIZE + 2 * ZERO_PADDING,
        1 to IMAGE_SIZE + 2 * ZERO_PADDING,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    -- Convolution iterator signals
    signal conv_row  : integer range Output_Feature'range(1);
    signal conv_col  : integer range Output_Feature'range(2);
    signal conv_chn  : integer range Output_Feature'range(3);

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
            for mac_row in Input_Kernel'range(1) loop
                for mac_col in Input_Kernel'range(2) loop
                    ----- Multiply Accumulate -----
                    feature_sum := feature_sum
                        -- Add Input Neuron
                        + Padded_Image(
                            STRIDE_STEPS * (conv_row - 1) + mac_row, 
                            STRIDE_STEPS * (conv_col - 1) + mac_col, 
                            conv_chn)
                        -- Multiplied by Kernel Weight
                        * Input_Kernel(mac_row, mac_col, conv_chn);
                    -------------------------------
                end loop;
            end loop;
            -- Apply ReLU activation
            if RELU_ACTIVATION and to_integer(feature_sum) < 0 then
                Output_Feature(conv_row, conv_col, conv_chn) <= (others => '0');
            else
                -- Scale down Result
                Output_Feature(conv_row, conv_col, conv_chn) <= feature_sum(feature_sum'high downto feature_sum'high - GRADIENT_BITS + 1);
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
    conv_complete <= (conv_row = Output_Feature'high(1)) and (conv_col = Output_Feature'high(2));
    --------------------------------------------------

end Behavioral;
