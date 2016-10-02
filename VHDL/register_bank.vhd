library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_unsigned.all;
use work.DigEng.ALL; 

----------------------------------- REGISTER BANK- ----------------------------------

-- Parameterizable (data Size, num registers) dual port read reigster bank, single write.
-- Able to store M-1 different numbers (register 0 tied to ground), each of datasize 

--------------------------------------------------------------------------------------
entity register_bank is
	 generic (M : natural;
				 baseM : natural;
				 dataSize : natural
				);
    Port ( DATA_IN : in  std_logic_vector(dataSize-1 downto 0); -- Data to write to register selected by WA
           DATA_OUT_RA : out  std_logic_vector(dataSize-1 downto 0); -- Output of port A
			  DATA_OUT_RB : out  std_logic_vector(dataSize-1 downto 0); -- Output of port B
			  RA : in std_logic_vector (baseM-1 downto 0); -- Address of register to read onto DATA_OUT_RA
			  RB : in std_logic_vector (baseM-1 downto 0); -- Address of register to read onto DATA_OUT_RB
			  WA : in std_logic_vector (baseM-1 downto 0); -- Address to write DATA_IN to
           rst : in  STD_LOGIC; -- Reset values of all registers (exluding 0)
           clk : in  STD_LOGIC;
           WEn : in  STD_LOGIC); -- Write enable for DATA_IN onto register selected by WA
end register_bank;

architecture Behavioral of register_bank is
	-- Decoder for RA port. Selects register to read from using Tri state buffers
	signal decoder1ToTriArray1En : std_logic_vector(M-1 downto 0);
	-- Decoder for RB port. Selects register to read from using Tri state buffers
	signal decoder2ToTriArray2En : std_logic_vector(M-1 downto 0);
	-- Decoder for WA. Selects register to write to using Tri state buffers
	signal decoderInToRegArrayEn : std_logic_vector(M-1 downto 0);
	-- Large bus containing every bit of every register
	signal registerToTriArrays   : std_logic_vector((M*dataSize)-1 downto 0);
begin

-- Tie register 0 to ground
registerToTriArrays(dataSize-1 downto 0) <= (others => '0');

-- Generate registers up to M, with tri state buffers for both ports
m_bit_register : for i in 0 to M-1 generate
	reg_array : if i > 0 generate
		registers: entity work.register_block
			generic map(dataSize => dataSize)
			port map(Q => registerToTriArrays((dataSize*(i+1))-1 downto (i * dataSize)), D => DATA_IN, clk => clk, rst=>rst, En => decoderInToRegArrayEn(i));
	end generate;
	
	tri_state_array1 : entity work.tri_state_buffer
		generic map(dataSize => dataSize)
		port map(En => decoder1ToTriArray1En(i), DATA_IN => registerToTriArrays((dataSize*(i+1))-1 downto (i * dataSize)), DATA_OUT => DATA_OUT_RA);
	
	tri_state_array2 : entity work.tri_state_buffer
		generic map(dataSize => dataSize)
		port map(En => decoder2ToTriArray2En(i), DATA_IN => registerToTriArrays((dataSize*(i+1))-1 downto (i * dataSize)) , DATA_OUT => DATA_OUT_RB);
end generate;

-- Instantiate decoders required for reading and writing
decoder1 : entity work.decoder
	generic map(M => M)
	port map(data_in => RA, DATA_OUT => decoder1ToTriArray1En, En => '1');
	
decoder2 : entity work.decoder
	generic map(M => M)
	port map(data_in => RB, DATA_OUT => decoder2ToTriArray2En, En => '1');
		
decoderIn : entity work.decoder
	generic map(M => M)
	port map(data_in => WA, DATA_OUT => decoderInToRegArrayEn, En => WEn);
	
end Behavioral;

