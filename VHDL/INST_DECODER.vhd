library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

------------------------------ INSTRUCTION DECODER -----------------------------------

-- Pulls opcode parameters out from 32 bit instruction based upon OPCODE.
-- Passes these values out to FSM/directly to processing unit.

--------------------------------------------------------------------------------------

entity INST_DECODER is
	 generic (dataSize : natural := 16;
				 numRegistersBase : natural := 4);
    Port ( INSTRUCTION : in  STD_LOGIC_VECTOR (31 downto 0); -- 32 bit input instruction from Instruction register
           RT : out  STD_LOGIC_VECTOR (numRegistersBase-1 downto 0); -- Target register to write to, equivalent to WA
           RA : out  STD_LOGIC_VECTOR (numRegistersBase-1 downto 0); -- Register to read from pulled from instruction
           RB : out  STD_LOGIC_VECTOR (numRegistersBase-1 downto 0); -- Register to read from pulled from instruction
           IMM : out  STD_LOGIC_VECTOR (dataSize-1 downto 0); -- Immediate value pulled from instruction
           N : out  STD_LOGIC_VECTOR (3 downto 0); -- Number of bits to shift/rotate by pulled from instruction
			  OPCODE : out STD_LOGIC_VECTOR (5 downto 0)); -- OPCODE pulled from instruction
end INST_DECODER;

architecture Behavioral of INST_DECODER is
	signal OPCODE_internal : STD_LOGIC_VECTOR(5 downto 0); -- Internal signal to hold OPCODE, as output port cant be read from
begin

OPCODE_internal <= INSTRUCTION(31 downto 26);

-- Values decoded from instruction are derived from OPCODE coding in excel spreadsheet

-- RA is always present in bits 5 to 9
RA <=
	INSTRUCTION(9 downto 5);

-- RT is always present on bits 0 to 4, except for storr and storo
-- Otherwise RT is not used, and so we can set Rt to 0000
RT <=
	INSTRUCTION(4 downto 0) when OPCODE_internal(5 downto 3) /= "101" else
	"00000";

-- RB allocation based upon opcode coding
RB <=
	INSTRUCTION(4 downto 0) when OPCODE_internal(5 downto 3) = "101" else
	INSTRUCTION(20 downto 16) when OPCODE_internal = "000001" or 
		OPCODE_internal = "000010" or 
		OPCODE_internal = "010001" or 
		OPCODE_internal = "010010" or 
		OPCODE_internal = "010011" else
	"00000";
	
-- IMM decoded for andi, ori, xor, addi, subi, loadi, stori
IMM <= 
	INSTRUCTION(25 downto 10) when OPCODE_internal (5 downto 2) = "0001" or 
	   OPCODE_internal(5 downto 2) = "0101" or
		OPCODE_internal = "100000" or 
		OPCODE_internal = "101000" else
	-- IMM is a resized and signed value written as OFFSET(9:0) in opcode coding for storo and loado
	-- So is resized and kept as signed (offsets can be negative)
   std_logic_vector(resize(signed(INSTRUCTION(19 downto 10)), dataSize)) when OPCODE_internal = "100110" or OPCODE_internal = "101110" else-- Resize OFFSET to size of IMM for offset addressing
	std_logic_vector(resize(signed(INSTRUCTION(18 downto 10)), dataSize)) when OPCODE_internal(5 downto 4) = "11" else -- Resize OFFSET to size of IMM for branch 
	"0000000000000000";

-- Decode of N for shl, shr, rol, ror
N <=
	INSTRUCTION(25 downto 22) when OPCODE_internal(5 downto 3) = "011" else
	"0000";

-- Output decoded OPCODE
OPCODE <= OPCODE_internal;
	
end Behavioral;

