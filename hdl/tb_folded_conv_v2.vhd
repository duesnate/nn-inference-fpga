

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
library work;
use work.mypackage.ALL;

entity tb_folded_conv_v2 is
end tb_folded_conv_v2;

architecture Behavioral of tb_folded_conv_v2 is

  constant IMAGE_SIZE      : positive := 3;     -- I
  constant KERNEL_SIZE     : positive := 2;     -- K
  constant CHANNELS_IN     : positive := 3;     -- Ci
  constant GRADIENT_BITS   : positive := 8;     -- B
  constant CHANNELS_OUT    : positive := 2;     -- Co
  constant STRIDE_STEPS    : positive := 1;     -- S
  constant ZERO_PADDING    : natural := 0;      -- P
  constant RELU_ACTIVATION : boolean := FALSE;
  -- Feature Size: F = (I+2*P-K)/S + 1
  -- Clock Cycles: C = Ch*F**2
  constant BATCH_COUNT     : positive := 10;

  signal RELU_INT       : natural;
  signal Aclk           : std_logic := '0';
  signal Aresetn        : std_logic := '0';
  signal Image_Stream   : std_logic_vector(GRADIENT_BITS-1 downto 0);
  signal Image_Valid    : boolean;
  signal Image_Ready    : boolean;
  signal Kernel_Stream  : std_logic_vector(GRADIENT_BITS-1 downto 0);
  signal Kernel_Valid   : boolean;
  signal Kernel_Ready   : boolean;
  signal Feature_Stream : std_logic_vector(GRADIENT_BITS-1 downto 0);
  signal Feature_Valid  : boolean;
  signal Feature_Ready  : boolean;

begin

  Aclk <= not Aclk after 5 ns;

  uut : folded_conv_v2
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
      Image_Stream    => Image_Stream,
      Image_Valid     => Image_Valid,
      Image_Ready     => Image_Ready,
      Kernel_Stream   => Kernel_Stream,
      Kernel_Valid    => Kernel_Valid,
      Kernel_Ready    => Kernel_Ready,
      Feature_Stream  => Feature_Stream,
      Feature_Valid   => Feature_Valid,
      Feature_Ready   => Feature_Ready
      );

  RELU_INT <= 1 when RELU_ACTIVATION else 0;

  process
    -- Seeds for random number generator
    variable s1 : positive := 123456;
    variable s2 : positive := 9876543;
    -- Output file handles/variables
    file file_input : text;
    variable line_buf : line;
    variable file_status : FILE_OPEN_STATUS;
    variable x : real;
  begin
    -- Open file
    file_open(file_status, file_input, "input_data.txt", write_mode);
    -- Write convolution parameters to the input data file
    write(line_buf, integer'image(integer(IMAGE_SIZE)));    writeline(file_input, line_buf);
    write(line_buf, integer'image(integer(KERNEL_SIZE)));   writeline(file_input, line_buf);
    write(line_buf, integer'image(integer(CHANNELS_IN)));   writeline(file_input, line_buf);
    write(line_buf, integer'image(integer(GRADIENT_BITS))); writeline(file_input, line_buf);
    write(line_buf, integer'image(integer(CHANNELS_OUT)));  writeline(file_input, line_buf);
    write(line_buf, integer'image(integer(STRIDE_STEPS)));  writeline(file_input, line_buf);
    write(line_buf, integer'image(integer(ZERO_PADDING)));  writeline(file_input, line_buf);
    write(line_buf, integer'image(RELU_INT));               writeline(file_input, line_buf);
    -- Start simulation
    Aresetn <= '0';
    Image_Valid <= FALSE;
    wait for 99.9 ns;
    Aresetn <= '1';
    Image_Valid <= TRUE;
    -- Loop for each image/feature
    for i in 1 to BATCH_COUNT loop
      while Image_Ready loop
        -- Generate random input data
        uniform(s1, s2, x);
        Image_Stream <= std_logic_vector(to_signed(integer(floor((x - 0.5) * real(2**GRADIENT_BITS))), GRADIENT_BITS));
        wait for 10 ns;
        -- Write to file
        write(line_buf, integer'image(to_integer(signed(Image_Stream))));
        writeline(file_input, line_buf);
      end loop;
      while not Image_Ready loop 
        wait for 10 ns;
      end loop;
    end loop;
    -- Close file
    file_close(file_input);
    wait;
  end process;

  process
    -- Seeds for random number generator
    variable s3, s4 : positive;
    -- Output file handles/variables
    file file_kernel : text;
    variable line_buf : line;
    variable file_status : FILE_OPEN_STATUS;
    variable x : real;
  begin
    -- Open file
    file_open(file_status, file_kernel, "kernel_data.txt", write_mode);
    -- Start simulation
    Kernel_Valid <= FALSE;
    wait for 99.9 ns;
    Kernel_Valid <= TRUE;
    -- Loop for each image/feature
    for i in 1 to BATCH_COUNT loop
      while Kernel_Ready loop
        -- Generate random weight data
        uniform(s3, s4, x);
        Kernel_Stream <= std_logic_vector(to_signed(integer(floor((x - 0.5) * real(2**GRADIENT_BITS))), GRADIENT_BITS));
        wait for 10 ns;
        -- Write to file
        write(line_buf, integer'image(to_integer(signed(Kernel_Stream))));
        writeline(file_kernel, line_buf);
      end loop;
      while not Kernel_Ready loop 
        wait for 10 ns;
      end loop;
    end loop;
    -- Close file
    file_close(file_kernel);
    wait;
  end process;

  process
    -- Output file handles/variables
    file file_output : text;
    variable line_buf : line;
    variable file_status : FILE_OPEN_STATUS;
  begin
    -- Open file
    file_open(file_status, file_output, "output_data.txt", write_mode);
    -- Start simulation
    Feature_Ready <= FALSE;
    wait for 99.9 ns;
    Aresetn <= '1';
    Feature_Ready <= TRUE;
    -- Skip first two zero-outputs
    for i in 1 to 2 loop
      while Feature_Valid loop wait for 10 ns; end loop;
      while not Feature_Valid loop wait for 10 ns; end loop;
    end loop;
    -- Loop for each image/feature
    for i in 1 to BATCH_COUNT loop
      while Feature_Valid loop
        wait for 10 ns;
        -- Write output results to file
        write(line_buf, integer'image(to_integer(signed(Feature_Stream))));
        writeline(file_output, line_buf);
      end loop;
      while not Feature_Valid loop 
        wait for 10 ns;
      end loop;
    end loop;
    -- Close file
    file_close(file_output);
    wait;
  end process;

end Behavioral;


