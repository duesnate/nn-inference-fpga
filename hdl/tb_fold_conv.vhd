

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
library work;
use work.mypackage.ALL;

entity tb_folded_conv is
end tb_folded_conv;

architecture Behavioral of tb_folded_conv is

    constant IMAGE_SIZE      : natural := 4;    -- I
    constant KERNEL_SIZE     : natural := 2;     -- K
    constant CHANNEL_COUNT   : natural := 1;     -- Ch
    constant GRADIENT_BITS   : natural := 8;     -- B
    constant STRIDE_STEPS    : natural := 1;     -- S
    constant ZERO_PADDING    : integer := 0;     -- P
    constant RELU_ACTIVATION : boolean := TRUE;
    -- Feature Size: F = (I+2*P-K)/S + 1
    -- Clock Cycles: C = Ch*F**2
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

    uut : folded_conv
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

    process
        variable image_counter : signed(GRADIENT_BITS-1 downto 0) := (others => '0');
    begin
        Aresetn <= '0';
        Image_Valid <= FALSE;
        wait for 100 ns;
        Aresetn <= '1';
        Image_Valid <= TRUE;
        Feature_Ready <= TRUE;
        loop
            while Image_Ready loop
                Image_Stream <= std_logic_vector(image_counter);
                image_counter := image_counter + 10;
                wait for 10 ns;
            end loop;
            while not Image_Ready loop 
                wait for 10 ns;
            end loop;
        end loop;
        wait;
    end process;

    process
        variable kernel_counter : signed(GRADIENT_BITS-1 downto 0) := (others => '0');
    begin
        Kernel_Valid <= FALSE;
        wait for 100 ns;
        Kernel_Valid <= TRUE;
        loop
            while Kernel_Ready loop
                Kernel_Stream <= std_logic_vector(kernel_counter);
                kernel_counter := kernel_counter + 10;
                wait for 10 ns;
            end loop;
            while not Kernel_Ready loop 
                wait for 10 ns;
            end loop;
        end loop;
        wait;
    end process;

end Behavioral;


