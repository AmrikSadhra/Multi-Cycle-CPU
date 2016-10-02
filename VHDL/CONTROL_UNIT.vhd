library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

------------------------------------ CONTROL UNIT -----------------------------------

-- The control unit contains the sequencer, decode logic, FSM and instruction register.
-- All of the control signals for the processor are generated here based upon the instruction
-- read into the instruction register.

--------------------------------------------------------------------------------------

entity CONTROL_UNIT is
	generic (dataSize : natural := 16; -- Size of data in processor
				numRegisters : natural := 32; -- Number of Registers
				numRegistersBase : natural := 5; -- Log2 number of registers
				busSize : natural := 4); -- Log2 size of data to give size of bus address
    Port ( clk : in STD_LOGIC;
			  rst : in STD_LOGIC;
			  
			  INSTRUCTION : in  STD_LOGIC_VECTOR (31 downto 0);
           MIA : out  STD_LOGIC_VECTOR (7 downto 0);
			  -------- CONTROL SIGNALS ------------
           RA    : out STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
           RB    : out STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
           WA    : out STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);

           IMM  : out STD_LOGIC_VECTOR(dataSize -1 downto 0);
           OEN  : out STD_LOGIC;
           WEN  : out STD_LOGIC;
           S    : out STD_LOGIC_VECTOR (3 downto 0);
           AL : out STD_LOGIC_VECTOR (3 downto 0);
           SH : out STD_LOGIC_VECTOR (busSize-1 downto 0);
           FLAGS : in  STD_LOGIC_VECTOR (6 downto 0);
			  ------- PC ----------------
           PC : out  STD_LOGIC_VECTOR (15 downto 0);
           PC_INC : in  STD_LOGIC_VECTOR (15 downto 0));
end CONTROL_UNIT;

architecture Behavioral of CONTROL_UNIT is
	-- Signals from decoder to FSM, piped into FSM in case FSM needs to generate values
	-- dependent upon them
	signal decodeToFSM_OPCODE : STD_LOGIC_VECTOR (5 downto 0);
	signal decodeToFSM_RA : STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
	signal decodeToFSM_RB : STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
	signal decodeToFSM_WA : STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
	signal decodeToFSM_N : STD_LOGIC_VECTOR (busSize-1 downto 0);
	signal decodeToFSM_IMM : STD_LOGIC_VECTOR(dataSize -1 downto 0);
	
	-- Connection of FSM enable signals to sequencer for PC related busses
	signal FSMToInstReg_MIAEN : STD_LOGIC;
	signal FSMToSequencer_PCEN : STD_LOGIC;
	
	-- Connection of instruction register output to decoder CLB
	signal instRegToDecoder_INSTR : STD_LOGIC_VECTOR(31 downto 0);
begin

-- Register to hold current instruction. Input loaded to output when MIA enable
-- comes through from FSM in fetch state of instruction.
INSTR_REGISTER: entity work.register_block
		generic map(dataSize => 32)
		port map(D => INSTRUCTION,
					Q => instRegToDecoder_INSTR,  
					clk => clk, 
					rst=> rst, 
					En => FSMToInstReg_MIAEN);

-- Instantiation of instruction decoder, required to get opcode parameters from
-- 32 bit instruction
DECODER: entity work.INST_DECODER
	generic map(dataSize => dataSize,
					numRegistersBase => numRegistersBase)
	port map(INSTRUCTION => instRegToDecoder_INSTR,
				RT => decodeToFSM_WA,
				RA => decodeToFSM_RA,
				RB => decodeToFSM_RB, 
				IMM => decodeToFSM_IMM, 
				N => decodeToFSM_N,
				OPCODE => decodeToFSM_OPCODE);

-- Instantiation of sequencer, to handle branching and MIA generation	
SEQUENCER: entity work.SEQUENCER
	generic map(dataSize => dataSize)
	port map(PC_INC => PC_INC,
           PC => PC,
			  PC_EN => FSMToSequencer_PCEN, 
			  clk => clk,
			  rst => rst,
			  MIA => MIA);
			  
-- Instantiation of FSM to set processor control signals through each stage of instruction
-- execution
FSM: entity work.PROCESSOR_FSM
	generic map(busSize => busSize,
					dataSize => dataSize,
					numRegisters => numRegisters,
					numRegistersBase => numRegistersBase)
	port map(clk => clk,
				rst => rst,
			   OPCODE => decodeToFSM_OPCODE,
				RA_in => decodeToFSM_RA,
				RB_in => decodeToFSM_RB,
				WA_in => decodeToFSM_WA,
				IMM_in => decodeToFSM_IMM,
				N_in => decodeToFSM_N,
				RA =>  RA,
				RB => RB,
				WA => WA,
				IMM=> IMM,
				OEN=> OEN,
				S  => S,
				AL => AL,
				SH => SH,
				WEN => WEN,
				PC_EN => FSMToSequencer_PCEN,
				FLAGS => FLAGS,
				MIA_EN => FSMToInstReg_MIAEN);

end Behavioral;
