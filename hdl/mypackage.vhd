
package mypackage is

	type RgbType is
		record
			R 	: std_logic_signed(7 downto 0);
			G	: std_logic_signed(7 downto 0);
			B	: std_logic_signed(7 downto 0);
		end record;


	type GridType is array(natural range <>, natural range <>, natural range <>) of std_logic_signed;

	--type KernalMatrix is array(natural range <>, natural range <>) of std_logic_signed(7 downto 0);

	component convolution
	    Generic(
	        IMAGE_SIZE      : unsigned := 4;
	        KERNEL_SIZE     : unsigned := 2;
	        CHANNEL_COUNT   : unsigned := 3
	        );
	    Port (  
	        Aclk            : in    std_logic;
	        Aresetn         : in    std_logic;
	        Input_Image     : in    GridType(1 to IMAGE_SIZE, 1 to IMAGE_SIZE, 1 to CHANNEL_COUNT)(7 downto 0);
	        Kernel_Weights  : in    GridType(1 to KERNEL_SIZE, 1 to KERNEL_SIZE, 1 to CHANNEL_COUNT)(7 downto 0);
	        Feature_Map     : out   GridType(1 to IMAGE_SIZE-KERNEL_SIZE+1, 1 to IMAGE_SIZE-KERNEL_SIZE+1, 1 to CHANNEL_COUNT)(15 downto 0)
	        );
	end component;

end package mypackage;

