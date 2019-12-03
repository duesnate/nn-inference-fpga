
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.uniform;
use IEEE.math_real.floor;

package mypackage is

    type GridType is array(natural range <>, natural range <>, natural range <>) of signed;

    component convolution
        Generic(
            IMAGE_SIZE      : natural := 6;
            KERNEL_SIZE     : natural := 3;
            CHANNEL_COUNT   : natural := 3;
            GRADIENT_BITS   : natural := 8;
            STRIDE_STEPS    : natural := 1;
            ZERO_PADDING    : integer := 0
        );
        Port (  
            Aclk            : in std_logic;
            Aresetn         : in std_logic;
            Input_Image     : in GridType(  
                1 to IMAGE_SIZE,
                1 to IMAGE_SIZE,
                1 to CHANNEL_COUNT
                ) (GRADIENT_BITS-1 downto 0);
            Kernel_Weights  : in GridType(  
                1 to KERNEL_SIZE,
                1 to KERNEL_SIZE,
                1 to CHANNEL_COUNT
                ) (GRADIENT_BITS-1 downto 0);
            Feature_Map     : out GridType( 
                1 to (IMAGE_SIZE+2*ZERO_PADDING-KERNEL_SIZE)/STRIDE_STEPS+1,
                1 to (IMAGE_SIZE+2*ZERO_PADDING-KERNEL_SIZE)/STRIDE_STEPS+1,
                1 to CHANNEL_COUNT
                ) (GRADIENT_BITS-1 downto 0)
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
            FOLDING         : boolean := TRUE;
            IMAGE_SIZE      : natural := 6;
            KERNEL_SIZE     : natural := 3;
            CHANNEL_COUNT   : natural := 3;
            GRADIENT_BITS   : natural := 8;
            STRIDE_STEPS    : natural := 1;
            ZERO_PADDING    : integer := 0
        );
        Port (  
            Aclk            : in std_logic;
            Aresetn         : in std_logic;
            Input_Image     : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*IMAGE_SIZE**2-1 downto 0);
            Kernel_Weights  : in std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*KERNEL_SIZE**2-1 downto 0);
            Feature_Map     : out std_logic_vector(GRADIENT_BITS*CHANNEL_COUNT*((IMAGE_SIZE+2*ZERO_PADDING-KERNEL_SIZE)/STRIDE_STEPS+1)**2-1 downto 0)
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

    ---- Functions
    --subtype ByteVector is unsigned(7 downto 0);
    --function get_rando (maxint, slvsize : positive) 
    --    return ByteVector;

    --function random_grid (maxint, slvsize : positive; input_grid : GridType)
    --    return GridType;

end package mypackage;


--package body mypackage is
    

    --function get_rando (maxint, slvsize : positive) 
    --    return ByteVector is
    --    variable seed1, seed2 : positive := 1;
    --    variable x : real;
    --begin
    --    uniform(seed1,seed2,x);
    --    return to_unsigned(integer(floor(x * Real(maxint))), slvsize);
    --end function get_rando;


    --function random_grid (maxint, slvsize : positive; input_grid : GridType)
    --    return GridType is
    --    variable return_grid : GridType(input_grid'range(1), input_grid'range(2), input_grid'range(3))(input_grid(1,1,1)'range);
    --begin
    --    for i in input_grid'range(1) loop
    --        for j in input_grid'range(2) loop
    --            for k in input_grid'range(3) loop
    --                return_grid(i,j,k) := get_rando(maxint, slvsize);
    --            end loop;
    --        end loop;
    --    end loop;
    --    return return_grid;
    --end function random_grid;


--end package body mypackage;
