library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------- PROCESSING UNIT ----------------------------------

-- The processing unit connects the ALU to the internal processor register bank.
-- The ALU is connected to multiplexers to pipe data appropriately based upon the 
-- instruction that is decoded. Similarly, the ALU output is multiplexed to Data 
-- Memory to allow for memory address calculation using the ALU. Stages of the 
-- processing unit are separated by registers to enable stages to be bypassed,
-- storing intermediate results. Output from ALU is multiplexed with output from
-- DATA memory, allowing selection between alu and dmem value for store to processor 
-- registers based upon opcode.

--------------------------------------------------------------------------------------
entity PROCESSING_UNIT is
	 generic (dataSize : natural := 16; -- Size of data in processor
				 numRegisters : natural := 32; -- Number of Registers
				 numRegistersBase : natural := 5; -- Log2 number of registers
				 shiftSize : natural := 4); -- Log2 size of data to give size of bus required to shift that data size max amount
    Port ( clk : in STD_LOGIC;
			  rst : in STD_LOGIC;
			  -------- DECODED CONTROL SIGNALS --------
			  -- These signals are decoded from the instruction/
			  -- generated by the FSM.
			  RA    : in STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
           RB    : in STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
           WA    : in STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
           IMM  : in STD_LOGIC_VECTOR(dataSize -1 downto 0);
           WEN  : in STD_LOGIC;
           S    : in STD_LOGIC_VECTOR (3 downto 0);
           AL : in STD_LOGIC_VECTOR (3 downto 0);
           SH : in STD_LOGIC_VECTOR (shiftSize-1 downto 0);
           FLAGS : out  STD_LOGIC_VECTOR (6 downto 0);
			  
			  ------ PROGRAM COUNTER SIGNALS -------
			  -- PC signal from sequencer gets modified by ALU
			  -- on fetch/branch by generating a PC_inc signal of
			  -- correct value.
           PC : in  STD_LOGIC_VECTOR (15 downto 0);
           PC_INC : out  STD_LOGIC_VECTOR (15 downto 0);
			  
			  ------- DATA Memory -----------
			  -- Connection of stages of processing unit
			  -- to data memory
			  IN_DMEM : in STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  OUT_DMEM : out STD_LOGIC_VECTOR(dataSize-1 downto 0);
			  MDA : out STD_LOGIC_VECTOR(dataSize-1 downto 0));
				
end PROCESSING_UNIT;

architecture Behavioral of PROCESSING_UNIT is
	--- Connection of registers A and B to ALU stage registers
	signal regbankAToRegA : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	signal regbankBToRegB : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	-- Connection of ALU stage registers to ALU input Multiplexers S1, S2
	signal regAtoMuxS2 : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	signal regBtoMuxS1 : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	-- Connection of S1 S2 multiplexer outputs to ALU inputs
	signal alu_in_A : STD_LOGIC_VECTOR (dataSize-1 downto 0);
	signal alu_in_B : STD_LOGIC_VECTOR (dataSize-1 downto 0);
	-- Connection of ALU output (after shifter) to AOut register
	signal alu_out : STD_LOGIC_VECTOR (dataSize-1 downto 0);
	
	-- Connection of S4 mux to data input of Register bank
	signal data_in : STD_LOGIC_VECTOR (dataSize-1 downto 0);

	-- Connection of registers to S4 for register write multiplexer
	signal AOutRegToS4 : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	signal MDRRegToS4 : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	
	-- Internal signals used to control multiplexers
	-- set to values from S bus input
	signal S1 : STD_LOGIC;
   signal S2 : STD_LOGIC;
   signal S3 : STD_LOGIC;
   signal S4 : STD_LOGIC;
	
begin

---------------------------- DATAPATH ---------------------------
	
-- S Bus values present in reverse order as bus is used to carry S values
-- We therefore set STD_LOGIC signals (with more appropriate names to control
-- the multiplexers) to the correct values from S Bus input to proc unit
	S1 <= S(3);
	S2 <= S(2);
	S3 <= S(1);
	S4 <= S(0);

-- Register A to store values read in from Regbank A input for input
-- to ALU after S2 mux.
reg_A: entity work.register_block
		generic map(dataSize => dataSize)
		port map(D => RegbankAToRegA,
					Q => regAtoMuxS2,  
					clk => clk, 
					rst=> rst, 
					En => '1');

-- Register B to store values read in from Regbank B input for input
-- to ALU after S1 mux.		
reg_B: entity work.register_block
		generic map(dataSize => dataSize)
		port map(D => RegbankBToRegB, 
					Q => regBtoMuxS1,  
					clk => clk, 
					rst=> rst, 
					En => '1');
					
-- Register AOut to store values read in from ALU output for input
-- to Registerbank after S4 mux.
reg_Aout: entity work.register_block
		generic map(dataSize => dataSize)
		port map(Q => AoutRegToS4, 
					D => ALU_OUT, 
					clk => clk, 
					rst=> rst, 
					En => '1');

-- Register MDR to store values read in from DMEM output for input
-- to Registerbank after S4 mux.			
reg_MDR: entity work.register_block
		generic map(dataSize => dataSize)
		port map(Q => MDRRegToS4, 
					D => IN_DMEM, 
					clk => clk, 
					rst=> rst, 
					En => '1');

-- Connection of data memory data input to value from datapath register B.
-- (After register, before S1 mux)
OUT_DMEM <= regBtoMuxS1;

-- Connection of PC_INC line to AOut register output (After AOut register, before S4 mux)
PC_INC <= AoutRegToS4;

-- Connection of ALU input B to either IMM line or value stored on register B dependent upon
-- S1 control signal (generated by FSM)		
ALU_IN_B <=
			IMM when S1 = '1' else
			RegBtoMuxS1 when S1 = '0' else
			(others => '0');
			
-- Connection of ALU input A to either PC line or value stored on register A dependent upon
-- S2 control signal (generated by FSM)		
ALU_IN_A <=
			PC when S2 = '1' else
			RegAtoMuxS2 when S2 = '0' else
			(others => '0');

-- Connection of DMEM memory data address to either IMM or calculated value from ALU output
-- register. IMM line never used as FSM loads IMM using S1 mux through ALU, costing an extra clock 
-- cycle.
MDA <= 	
			IMM when S3 = '1' else
			AoutRegToS4 when S3 = '0' else
			(others => '0');

-- Connection of Register bank data input to either data from memory or calculated using ALU
-- dependent upon S4 control signal (generated by FSM)
DATA_IN <=
			MDRRegToS4 when S4 = '1' else 
			AoutRegToS4 when S4 = '0' else
			(others => '0');
			
---------------------------------------------------------------------

-- Instantiation of ALU and Register bank, with connections to MUX inputs/outputs

ALU: entity work.ALU
	generic map(dataSize => dataSize)
	port map(A => alu_in_A,
				B => alu_in_B,
				X => SH,
				OPCODE => AL,
 				ALU_OUT => alu_out,
				FLAGS => FLAGS);
	
REG_BANK: entity work.register_bank
	generic map(M => numRegisters, baseM => numRegistersBase, dataSize => dataSize)
	port map(DATA_IN => DATA_IN,
				DATA_OUT_RA => RegbankAToRegA, 
				DATA_OUT_RB => RegbankBToRegB,
				RA => RA, 
				RB => RB, 
				WA => WA, 
				rst => rst,
				clk => clk,
				WEn => WEN);

end Behavioral;

