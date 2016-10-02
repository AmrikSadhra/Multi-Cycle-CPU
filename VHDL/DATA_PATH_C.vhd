library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DATA_PATH_C is 
	generic(dataSize : natural);
	Port (  DATA_OUT_RA : in  STD_LOGIC_VECTOR(dataSize-1 downto 0);
           DATA_OUT_RB : in  STD_LOGIC_VECTOR(dataSize-1  downto 0);
			  ALU_IN_A : out STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  ALU_IN_B : out STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  IMM : in STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  clk : in STD_LOGIC;
			  S1 : in STD_LOGIC;
			  S2 : in STD_LOGIC;
			  S3 : in STD_LOGIC;
			  S4 : in STD_LOGIC;
			  OEN : in STD_LOGIC;
			  MDA : out STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  MA : in STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  ALU_OUT : in STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  REG_DATA_IN : out STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  
			  PC : in STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  PC_INC : out STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  OUT_DMEM : out STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  IN_DMEM : in STD_LOGIC_VECTOR(dataSize-1 downto 0)
			  );
end DATA_PATH_C;

architecture Behavioral of DATA_PATH_C is
	signal regAtoMuxS2 : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	signal regBtoMuxS1 : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	signal AOutRegToS4 : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	signal MDRRegToS4 : STD_LOGIC_VECTOR(dataSize-1 downto 0);
begin

reg_A: entity work.register_block
		generic map(dataSize => dataSize)
		port map(Q => regAtoMuxS2, D => DATA_OUT_RA, clk => clk, rst=>'0', En => '1');
reg_B: entity work.register_block
		generic map(dataSize => dataSize)
		port map(Q => regBtoMuxS1, D => DATA_OUT_RB, clk => clk, rst=>'0', En => '1');
reg_Aout: entity work.register_block
		generic map(dataSize => dataSize)
		port map(Q => AoutRegToS4, D => ALU_OUT, clk => clk, rst=>'0', En => '1');
reg_MDR: entity work.register_block
		generic map(dataSize => dataSize)
		port map(Q => MDRRegToS4, D => IN_DMEM, clk => clk, rst=>'0', En => '1');

-- OUT_DMEM is currently WRONG AS FUCK
OUT_DMEM <=
	regBtoMuxS1 when OEN = '1' else
	(others => '0');
	
PC_INC <=
	AoutRegToS4;

ALU_IN_B <=
			IMM when S1 = '1' else
			RegBtoMuxS1 when S1 = '0' else
			(others => 'U');
			
ALU_IN_A <=
			PC when S2 = '1' else
			RegAtoMuxS2 when S2 = '0' else
			(others => 'U');
			
MDA <= 	
		MA when S3 = '1' else
		AoutRegToS4 when S3 = '0' else
		(others => 'U');
			
REG_DATA_IN <=
			MDRRegToS4 when S4 = '1' else 
			AoutRegToS4 when S4 = '0' else
			(others => 'U');

end Behavioral;

