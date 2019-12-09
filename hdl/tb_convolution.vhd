

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
library xil_defaultlib;
use xil_defaultlib.mypackage.ALL;


entity tb_convolution is
end tb_convolution;

architecture Behavioral of tb_convolution is
    
    constant IMAGE_SIZE         : natural := 4;
    constant KERNEL_SIZE        : natural := 2;
    constant CHANNEL_COUNT      : natural := 3;
    constant GRADIENT_BITS      : natural := 8;
    constant STRIDE_STEPS       : natural := 1;
    constant ZERO_PADDING       : integer := 0;
    constant RELU_ACTIVATION    : boolean := TRUE;

    signal Aclk            : std_logic := '1';
    signal Aresetn         : std_logic := '0';
    signal Input_Image     : GridType(
        1 to IMAGE_SIZE, 
        1 to IMAGE_SIZE, 
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);
    signal Kernel_Weights  : GridType(
        1 to KERNEL_SIZE, 
        1 to KERNEL_SIZE, 
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);
    signal Output_Feature  : GridType(
        1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
        1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
        1 to CHANNEL_COUNT
        ) (GRADIENT_BITS - 1 downto 0);

    type IntFileType is file of integer;

begin

    Aclk <= not Aclk after 5 ns;

    uut : convolution 
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
            Aclk            => Aclk,
            Aresetn         => Aresetn,
            Input_Image     => Input_Image,
            Kernel_Weights  => Kernel_Weights,
            Output_Feature  => Output_Feature
            );

    process
        -- Seeds for random number generator
        variable s1, s2 : positive;
        -- Output file handle
        file file_handle : IntFileType;
        variable file_status : FILE_OPEN_STATUS;
    begin

        file_open(file_status, file_handle, "output.txt", write_mode);

        Aresetn <= '0';
        wait for 100 ns;
        Aresetn <= '1';
        for i in 1 to 1 loop
            random_grid(256, GRADIENT_BITS, s1, s2, Input_Image);
            random_grid(256, GRADIENT_BITS, s1, s2, Kernel_Weights);
            wait for 10 ns;
            for row in Output_Feature'range(1) loop
                for col in Output_Feature'range(2) loop
                    for chn in Output_Feature'range(3) loop
                        write(file_handle, to_integer(Output_Feature(row, col, chn)));
                    end loop;
               end loop;
            end loop;
        end loop;
        file_close(file_handle);
        wait;
    end process;

end Behavioral;
