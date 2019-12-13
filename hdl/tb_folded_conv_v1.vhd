

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
library work;
use work.mypackage.ALL;


entity tb_folded_conv_v1 is
end tb_folded_conv_v1;

architecture Behavioral of tb_folded_conv_v1 is
    
    constant IMAGE_SIZE         : positive := 32;
    constant KERNEL_SIZE        : positive := 12;
    constant CHANNELS_IN        : positive := 3;
    constant GRADIENT_BITS      : positive := 8;
    constant CHANNELS_OUT       : positive := 16;
    constant STRIDE_STEPS       : positive := 4;
    constant ZERO_PADDING       : natural := 4;
    constant RELU_ACTIVATION    : boolean := FALSE;

    signal RELU_INT : natural;
    signal Aclk            : std_logic := '1';
    signal Aresetn         : std_logic := '0';
    signal Input_Image     : GridType(
        1 to IMAGE_SIZE, 
        1 to IMAGE_SIZE, 
        1 to CHANNELS_IN
        ) (GRADIENT_BITS - 1 downto 0);
    signal Kernel_Weights  : GridType(
        1 to KERNEL_SIZE, 
        1 to KERNEL_SIZE, 
        1 to CHANNELS_IN * CHANNELS_OUT
        ) (GRADIENT_BITS - 1 downto 0);
    signal Output_Feature  : GridType(
        1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
        1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
        1 to CHANNELS_OUT
        ) (GRADIENT_BITS - 1 downto 0);
    signal conv_complete   : boolean;

begin

    Aclk <= not Aclk after 5 ns;

    uut : folded_conv_v1 
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
            Aclk            => Aclk,
            Aresetn         => Aresetn,
            Input_Image     => Input_Image,
            Kernel_Weights  => Kernel_Weights,
            Output_Feature  => Output_Feature,
            conv_complete   => conv_complete
            );

    RELU_INT <= 1 when RELU_ACTIVATION else 0;

    process
        -- Seeds for random number generator
        variable s1 : positive := 123;
        variable s2 : positive := 12345;
        variable s3 : positive := 123456;
        variable s4 : positive := 1234567;
        -- Output file handles/variables
        file file_input : text;
        file file_kernel : text;
        file file_output : text;
        variable line_buf : line;
        variable file_status : FILE_OPEN_STATUS;
    begin
        -- Open files
        file_open(file_status, file_input, "input_data.txt", write_mode);
        file_open(file_status, file_kernel, "kernel_data.txt", write_mode);
        file_open(file_status, file_output, "output_data.txt", write_mode);
        -- Write convolution parameters to the input data file
        write(line_buf, integer'image(integer(IMAGE_SIZE))); writeline(file_input, line_buf);
        write(line_buf, integer'image(integer(KERNEL_SIZE))); writeline(file_input, line_buf);
        write(line_buf, integer'image(integer(CHANNELS_IN))); writeline(file_input, line_buf);
        write(line_buf, integer'image(integer(GRADIENT_BITS))); writeline(file_input, line_buf);
        write(line_buf, integer'image(integer(CHANNELS_OUT))); writeline(file_input, line_buf);
        write(line_buf, integer'image(integer(STRIDE_STEPS))); writeline(file_input, line_buf);
        write(line_buf, integer'image(integer(ZERO_PADDING))); writeline(file_input, line_buf);
        write(line_buf, integer'image(RELU_INT)); writeline(file_input, line_buf);
        -- Start simulation
        Aresetn <= '0';
        wait for 99.9 ns;
        Aresetn <= '1';
        for i in 1 to 10 loop
            -- Generate pseudo-random input data
            random_grid(2**GRADIENT_BITS, GRADIENT_BITS, s1, s2, Input_Image);
            random_grid(2**GRADIENT_BITS, GRADIENT_BITS, s2, s3, Kernel_Weights);
            wait for 10 ns;
            -- Wait for initial convolution to complete
            while not conv_complete loop
                wait for 10 ns;
            end loop;
            -- Write input data to file
            for row in Input_Image'range(1) loop
                for col in Input_Image'range(2) loop
                    for chn in Input_Image'range(3) loop
                        write(line_buf, integer'image(to_integer(Input_Image(row, col, chn))));
                        writeline(file_input, line_buf);
                    end loop;
               end loop;
            end loop;
            -- Write kernel weights to file
            for row in Kernel_Weights'range(1) loop
                for col in Kernel_Weights'range(2) loop
                    for chn in Kernel_Weights'range(3) loop
                        write(line_buf, integer'image(to_integer(Kernel_Weights(row, col, chn))));
                        writeline(file_kernel, line_buf);
                    end loop;
               end loop;
            end loop;
            -- Write output data to file
            for row in Output_Feature'range(1) loop
                for col in Output_Feature'range(2) loop
                    for chn in Output_Feature'range(3) loop
                        write(line_buf, integer'image(to_integer(Output_Feature(row, col, chn))));
                        writeline(file_output, line_buf);
                    end loop;
               end loop;
            end loop;
        end loop;
        -- Close files
        file_close(file_input);
        file_close(file_kernel);
        file_close(file_output);
        wait;
    end process;

end Behavioral;
