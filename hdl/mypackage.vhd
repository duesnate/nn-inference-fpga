
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.uniform;
use IEEE.math_real.floor;

package mypackage is

    type GridType is array(natural range <>, natural range <>, natural range <>) of signed;

    component convolution
        Generic(
          IMAGE_SIZE      : positive;
          KERNEL_SIZE     : positive;
          CHANNELS_IN     : positive;
          GRADIENT_BITS   : positive;
          CHANNELS_OUT    : positive;
          STRIDE_STEPS    : positive;
          ZERO_PADDING    : natural;
          RELU_ACTIVATION : boolean
        );
        Port ( 
            Aclk            : in std_logic;
            Aresetn         : in std_logic;
            Input_Image     : in GridType(  
                1 to IMAGE_SIZE,
                1 to IMAGE_SIZE,
                1 to CHANNELS_IN
                ) (GRADIENT_BITS - 1 downto 0);
            Kernel_Weights  : in GridType(  
                1 to KERNEL_SIZE,
                1 to KERNEL_SIZE,
                1 to CHANNELS_IN * CHANNELS_OUT
                ) (GRADIENT_BITS - 1 downto 0);
            Output_Feature  : out GridType( 
                1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
                1 to (IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1,
                1 to CHANNELS_OUT
                ) (GRADIENT_BITS - 1 downto 0)
        );
    end component;

    component folded_conv
        Generic(
            IMAGE_SIZE      : natural := 6;
            KERNEL_SIZE     : natural := 3;
            CHANNEL_COUNT   : natural := 3;
            GRADIENT_BITS   : natural := 8;
            STRIDE_STEPS    : natural := 1;
            ZERO_PADDING    : integer := 0;
            RELU_ACTIVATION : boolean := TRUE
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
    end component;

    component process_conv
        Generic (
            IMAGE_SIZE      : natural := 24;
            KERNEL_SIZE     : natural := 9;
            CHANNEL_COUNT   : natural := 3;
            GRADIENT_BITS   : natural := 8;
            STRIDE_STEPS    : natural := 1;
            ZERO_PADDING    : integer := 0;
            RELU_ACTIVATION : boolean := TRUE
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
    end component;

    component relu
        Generic(
            FEATURE_SIZE    : natural := 6;
            CHANNEL_COUNT   : natural := 3;
            GRADIENT_BITS   : natural := 8
        );
        Port (
            Aclk            : in std_logic;
            Aresetn         : in std_logic;
            Input_Feature   : in GridType(
                1 to FEATURE_SIZE,
                1 to FEATURE_SIZE,
                1 to CHANNEL_COUNT
                ) (GRADIENT_BITS-1 downto 0);
            Output_Feature  : out GridType(
                1 to FEATURE_SIZE,
                1 to FEATURE_SIZE,
                1 to CHANNEL_COUNT
                ) (GRADIENT_BITS-1 downto 0)
        );
    end component;

    component pooling
        Generic(
            FEATURE_SIZE    : natural := 6;
            CHANNEL_COUNT   : natural := 3;
            GRADIENT_BITS   : natural := 8;
            POOL_SIZE       : natural := 2
        );
        Port (  
            Aclk            : in std_logic;
            Aresetn         : in std_logic;
            Feature_In      : in GridType(  
                1 to FEATURE_SIZE,
                1 to FEATURE_SIZE,
                1 to CHANNEL_COUNT
                ) (GRADIENT_BITS-1 downto 0);
            Feature_Out     : out GridType( 
                1 to FEATURE_SIZE/POOL_SIZE,
                1 to FEATURE_SIZE/POOL_SIZE,
                1 to CHANNEL_COUNT
                ) (GRADIENT_BITS-1 downto 0)
        );
    end component;

    component interface_conv
        Generic(
          IMAGE_SIZE      : positive;
          KERNEL_SIZE     : positive;
          CHANNELS_IN     : positive;
          GRADIENT_BITS   : positive;
          CHANNELS_OUT    : positive;
          STRIDE_STEPS    : positive;
          ZERO_PADDING    : natural;
          RELU_ACTIVATION : boolean
        );
        Port (  
          Aclk            : in std_logic;
          Aresetn         : in std_logic;
          Input_Image     : in std_logic_vector(
              GRADIENT_BITS * CHANNELS_IN * IMAGE_SIZE**2 - 1 downto 0);
          Kernel_Weights  : in std_logic_vector(
              GRADIENT_BITS * CHANNELS_IN * CHANNELS_OUT * KERNEL_SIZE**2 - 1 downto 0);
          Output_Feature  : out std_logic_vector(
              GRADIENT_BITS * CHANNELS_OUT 
              * ((IMAGE_SIZE + 2 * ZERO_PADDING - KERNEL_SIZE) / STRIDE_STEPS + 1)**2 - 1 downto 0)
        );
    end component;

    component interface_relu
        Generic(
            FEATURE_SIZE    : natural := 6;
            CHANNEL_COUNT   : natural := 3;
            GRADIENT_BITS   : natural := 8
        );
        Port (  
            Aclk            : in std_logic;
            Aresetn         : in std_logic;
            Input_Feature   : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*FEATURE_SIZE**2-1 downto 0);
            Output_Feature  : out std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*FEATURE_SIZE**2-1 downto 0)
        );
    end component;
 
    component interface_pool
        Generic(
            FEATURE_SIZE    : natural := 6;
            CHANNEL_COUNT   : natural := 3;
            GRADIENT_BITS   : natural := 8;
            POOL_SIZE       : natural := 2
        );
        Port (
            Aclk        : in std_logic;
            Aresetn     : in std_logic;
            Feature_In  : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*FEATURE_SIZE**2-1 downto 0);
            Feature_Out : out std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*(FEATURE_SIZE/POOL_SIZE)**2-1 downto 0)
        );
    end component;

    component grid_iterator
        Generic(
            GRID_SIZE       : natural := 8;
            CHANNEL_COUNT   : natural := 3
        );
        Port (
            Aclk    : in std_logic;
            Aresetn : in std_logic;
            hold    : in boolean;
            row     : out integer range 1 to GRID_SIZE;
            column  : out integer range 1 to GRID_SIZE;
            channel : out integer range 1 to CHANNEL_COUNT
        );
    end component;

    component stream_grid_tx
        Generic (
            GRID_SIZE       : natural := 6;
            CHANNEL_COUNT   : natural := 3;
            GRADIENT_BITS   : natural := 8
        );
        Port (
            Aclk     : in std_logic;
            Aresetn  : in std_logic;
            Stream_Data     : out std_logic_vector(GRADIENT_BITS-1 downto 0);
            Stream_Valid    : out boolean;
            Stream_Ready    : in boolean;
            Grid_Data : in GridType(
                1 to GRID_SIZE,
                1 to GRID_SIZE,
                1 to CHANNEL_COUNT
                ) (GRADIENT_BITS - 1 downto 0);
            Transfer_Complete   : in boolean;
            Stream_Complete     : out boolean
        );
    end component;

    component stream_grid_rx
        Generic (
            GRID_SIZE       : natural := 6;
            CHANNEL_COUNT   : natural := 3;
            GRADIENT_BITS   : natural := 8
        );
        Port (
            Aclk     : in std_logic;
            Aresetn  : in std_logic;
            Stream_Data     : in std_logic_vector(GRADIENT_BITS-1 downto 0);
            Stream_Valid    : in boolean;
            Stream_Ready    : out boolean;
            Grid_Data : out GridType(
                1 to GRID_SIZE,
                1 to GRID_SIZE,
                1 to CHANNEL_COUNT
                ) (GRADIENT_BITS - 1 downto 0);
            Transfer_Complete   : in boolean;
            Stream_Complete     : out boolean
        );
    end component;


    -- Functions
    function get_random(urange, bitwidth : positive) return signed;

    -- Procedures
    procedure random_grid(
        urange, bitwidth : in positive; 
        variable s1, s2 : inout positive; 
        signal input_grid : inout GridType);

end package mypackage;



package body mypackage is
    
    function get_random(urange, bitwidth : positive) return signed is
        variable s1, s2 : positive;
        variable x : real;
        variable uout : signed(bitwidth - 1 downto 0);
    begin
        uniform(s1, s2, x);
        report "x = " & real'image(x);
        uout := to_signed(integer(floor((x - 0.5) * real(urange))), bitwidth);
        report "uout = " & integer'image(to_integer(uout));
        return uout;
    end get_random;


    procedure random_grid(
        urange, bitwidth : in positive; 
        variable s1, s2 : inout positive;
        signal input_grid : inout GridType) is
        variable x : real;
    begin
        for i in input_grid'range(1) loop
            for j in input_grid'range(2) loop
                for k in input_grid'range(3) loop
                    uniform(s1, s2, x);
                    input_grid(i,j,k) <= to_signed(integer(floor((x - 0.5) * real(urange))), bitwidth);
                end loop;
            end loop;
        end loop;
    end random_grid;

end package body mypackage;
