----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nathan Duescher
-- 
-- Create Date: 10/2019
-- Design Name: 
-- Module Name: fully_connected
-- Project Name: nn-inference-fpga
-- Target Devices: 
-- Tool Versions: Vivado 2019.1
-- Description: 
--              The fully connected (FC) layer of a CNN is primarily used at the 
--              final stage of the network model and serves to transform the 
--              resulting feature activations into the final image 
--              classification. Multiple FC layers may, however, be used 
--              throughout the model as hidden layers. It is most common, 
--              however, for these to be instantiated in sequence of decreasing 
--              neuron size at the end of a model. The number of neurons used in 
--              each hidden layer can be adjusted during the design and training 
--              phase for optimizing performance. It is important to note though 
--              that the number of possible image classifications will determine 
--              the number of neurons in the final FC layer. Each classification 
--              label will be assigned to an output neuron and whichever neuron 
--              is most favored will be used as the network's prediction. As the 
--              name suggests, FC layers require that each neuron be connected 
--              to all the neurons of neighboring FC layers making them 
--              particularly resource heavy. Each neuron requires one trained 
--              bias value and a number of trained weight values equal to the 
--              number of neurons in the following FC layer. These layers 
--              require a large overhead of trained values that must be stored 
--              in memory and made available to the model when needed.
----------------------------------------------------------------
-- 
-- Dependencies: VHDL-2008
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

entity fully_connected is
    Generic(
        FEATURE_SIZE    : natural := 6;
        CHANNEL_COUNT   : natural := 3;
        GRADIENT_BITS   : natural := 8;
        NEURON_COUNT    : natural := 10
    );
    Port (  
        Aclk            : in std_logic;
        Aresetn         : in std_logic;
        Feature_In      : in std_logic_vector(GRADIENT_BITS * CHANNEL_COUNT * FEATURE_SIZE**2 - 1 downto 0);
        Weights         : in std_logic_vector(NEURON_COUNT * GRADIENT_BITS * CHANNEL_COUNT * FEATURE_SIZE**2 - 1 downto 0);
        Bias            : in std_logic_vector(NEURON_COUNT * GRADIENT_BITS - 1 downto 0);
        Neuron_Out      : out std_logic_vector(NEURON_COUNT * GRADIENT_BITS - 1 downto 0)
    );
end fully_connected;

architecture Behavioral of fully_connected is

    constant BITS4SUM   : integer := integer(ceil(log2(real(CHANNEL_COUNT * FEATURE_SIZE**2))));
    constant NEURON_MAX : integer := 2**(GRADIENT_BITS - 1) - 1;
    constant NEURON_MIN : integer := -1 * 2**(GRADIENT_BITS - 1);

begin

    process(Aclk, Aresetn)
        variable neuron_sum     : signed(2 * GRADIENT_BITS + BITS4SUM - 1 downto 0);
        variable neuron_scaled  : signed(GRADIENT_BITS downto 0);
    begin
        if Aresetn = '0' then
            Neuron_Out <= (others => '0');
            neuron_scaled := (others => '0');
        elsif rising_edge(Aclk) then
            for neuron in 1 to NEURON_COUNT loop
                -- Clear summation
                neuron_sum := (others => '0');
                for row in 1 to FEATURE_SIZE loop
                    for col in 1 to FEATURE_SIZE loop
                        for channel in 1 to CHANNEL_COUNT loop

                            neuron_sum := neuron_sum
                                -- Add Input Node
                                + signed(Feature_In(        (channel      + ((col - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT                    ) * GRADIENT_BITS - 1 
                                          downto            (channel      + ((col - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT                 - 1) * GRADIENT_BITS))
                                -- Multiplied by Weight
                                * signed(Weights((neuron + ((channel - 1) + ((col - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT) * NEURON_COUNT    ) * GRADIENT_BITS - 1 
                                          downto (neuron + ((channel - 1) + ((col - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT) * NEURON_COUNT - 1) * GRADIENT_BITS));
                            
                        end loop;
                    end loop;
                end loop;
                -- Scale Down Results and Add Bias
                neuron_scaled := neuron_sum(neuron_sum'high downto neuron_sum'high - GRADIENT_BITS + 1)
                    + resize(signed(Bias(neuron * GRADIENT_BITS - 1 downto (neuron - 1) * GRADIENT_BITS)), GRADIENT_BITS + 1);
                -- Prevent Overflow / Underflow
                if to_integer(neuron_scaled) > NEURON_MAX then
                    Neuron_Out(neuron * GRADIENT_BITS - 1 downto (neuron - 1) * GRADIENT_BITS) <= std_logic_vector(to_signed(NEURON_MAX, GRADIENT_BITS));
                elsif to_integer(neuron_scaled) < NEURON_MIN then
                    Neuron_Out(neuron * GRADIENT_BITS - 1 downto (neuron - 1) * GRADIENT_BITS) <= std_logic_vector(to_signed(NEURON_MIN, GRADIENT_BITS));
                else
                    Neuron_Out(neuron * GRADIENT_BITS - 1 downto (neuron - 1) * GRADIENT_BITS) <= std_logic_vector(resize(neuron_scaled, GRADIENT_BITS));
                end if;
            end loop;
        end if;
    end process;

end Behavioral;


