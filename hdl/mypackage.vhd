
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.uniform;
use IEEE.math_real.floor;

package mypackage is

    --type RgbType is
    --    record
    --        R   : std_logic_signed(7 downto 0);
    --        G   : std_logic_signed(7 downto 0);
    --        B   : std_logic_signed(7 downto 0);
    --    end record;

    type GridType is array(natural range <>, natural range <>, natural range <>) of unsigned;

    component convolution
        Generic(
            IMAGE_SIZE      : natural := 4;
            KERNEL_SIZE     : natural := 2;
            CHANNEL_COUNT   : natural := 3
            );
        Port (  
            Aclk            : in std_logic;
            Aresetn         : in std_logic;
            Input_Image     : in std_logic_vector(8*IMAGE_SIZE**2-1 downto 0);
            Kernel_Weights  : in std_logic_vector(8*KERNEL_SIZE**2-1 downto 0);
            Feature_Map     : out std_logic_vector(16*(IMAGE_SIZE-KERNEL_SIZE+1)**2-1 downto 0)
            );
    end component;

    -- Functions
    subtype ByteVector is unsigned(7 downto 0);
    function get_rando (maxint, slvsize : positive) 
        return ByteVector;

    function random_grid (maxint, slvsize : positive; input_grid : GridType)
        return GridType;

end package mypackage;


package body mypackage is
    

    function get_rando (maxint, slvsize : positive) 
        return ByteVector is
        variable seed1, seed2 : positive := 1;
        variable x : real;
    begin
        uniform(seed1,seed2,x);
        return to_unsigned(integer(floor(x * Real(maxint))), slvsize);
    end function get_rando;


    function random_grid (maxint, slvsize : positive; input_grid : GridType)
        return GridType is
        variable return_grid : GridType(input_grid'range(1), input_grid'range(2), input_grid'range(3))(input_grid(1,1,1)'range);
    begin
        for i in input_grid'range(1) loop
            for j in input_grid'range(2) loop
                for k in input_grid'range(3) loop
                    return_grid(i,j,k) := get_rando(maxint, slvsize);
                end loop;
            end loop;
        end loop;
        return return_grid;
    end function random_grid;


end package body mypackage;
