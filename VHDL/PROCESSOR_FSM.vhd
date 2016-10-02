library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.ALL;

------------ FINITE STATE MACHINE ------------------

-- This is the combinational logic block for the multi cycle architecture .
-- It uses a finite state machine to generate the control signals for the rest
-- of the processor.

-----------------------------------------------------
entity PROCESSOR_FSM is
	generic (dataSize : natural := 16;
				 numRegisters : natural := 16;
				 numRegistersBase : natural := 4;
				 busSize : natural := 4);
    Port (		clk : in  STD_LOGIC;
				rst : in  STD_LOGIC;
				-------- INSTRUCTION CODING ---------
			  
				-- OPCODE is the the six MSBs from the instruction bus.
				OPCODE : in STD_LOGIC_VECTOR(5 downto 0);
				
				-- Register Address inputs (RA and RB), and register to write to(WA).
				RA_in : in STD_LOGIC_VECTOR(numRegistersBase-1 downto 0);
				RB_in : in STD_LOGIC_VECTOR(numRegistersBase-1 downto 0);
				WA_in : in STD_LOGIC_VECTOR(numRegistersBase-1 downto 0);
				
				-- Immediate value(IMM), and number of shift bits (N).
				IMM_in : in STD_LOGIC_VECTOR (dataSize-1 downto 0);
				N_in : in STD_LOGIC_VECTOR (busSize-1 downto 0);
				
				-- FLAGS generated by ALU for branch condition detection
				FLAGS : in STD_LOGIC_VECTOR(6 downto 0);
				
				-------- CONTROL SIGNALS -----------
				-- Register Addresses.
				RA : out STD_LOGIC_VECTOR(numRegistersBase-1 downto 0);
				RB : out STD_LOGIC_VECTOR(numRegistersBase-1 downto 0);
				WA : out STD_LOGIC_VECTOR(numRegistersBase-1 downto 0);
			 
				-- Multiplexor selection bits.
				S  : out STD_LOGIC_VECTOR (3 downto 0);
				
				-- ALU inputs.
				AL : out  STD_LOGIC_VECTOR (3 downto 0);
				SH : out  STD_LOGIC_VECTOR (busSize-1 downto 0);
				IMM: out STD_LOGIC_VECTOR  (dataSize-1 downto 0);
				
				-- Enables.
				WEN : out STD_LOGIC;
				MIA_EN : out STD_LOGIC;
				PC_EN : out STD_LOGIC;
				OEN : out STD_LOGIC
				);	
end PROCESSOR_FSM;

architecture Behavioral of PROCESSOR_FSM is
  
    --------- STATES ----------
	type state_type is (S0, S1, S2, S3, S4, S5, S6, S7, S8);
	--------- INTERNAL SIGNALS -----------
	signal state, next_state : state_type;
	
	-- S bus for Multiplexors .
	signal S_internal : STD_LOGIC_VECTOR (3 downto 0);
	-- Flags from ALU .
	signal FLAG_SET : STD_LOGIC;
	
begin

state_assignment: process (clk) is
	begin
		if rising_edge(clk) then
			if (rst = '1') then
				state <= S0;
			else
				state <= next_state; 
			end if;
		end if;
end process state_assignment;

-- Definitions for the state transitions .
fsm_process: process (state, OPCODE) is
begin
    case state is
		-- Fetch State.
			when S0 =>
				next_state <= S1;
		-- Reg Read State.
			when S1 =>
				if (OPCODE(5) = '0' and OPCODE /= "000000") or (OPCODE = "100111") then
				-- Arithmetic and Logic. Special case for Move instruction, as skips MemRW.
					next_state <= S2; 
				elsif OPCODE(5 downto 4) = "10" and OPCODE /= "100111" then
				-- Transfer. Exclude MemRW.
					next_state <= S4;
				elsif OPCODE = "000000"  then
				-- If NOP instruction the return to S0 and load fetch instruction.
					next_state <= S0;
				else
				-- Branch. 
					next_state <= S8; 
				end if;
			  
		-- ALU State (REG).
			when S2 =>
			  next_state <= S3;
			  
		-- Reg Write State (REG).
			when S3 =>
			  next_state <= S0;
			  
		-- ALU state (MEM).
			when S4 =>
				if (OPCODE(3) = '1') then 
				-- If OPCODE is specific to store then go to State 5.
					next_state <= S5; 
				else
					next_state <= S6;
				end if;
			  
		-- MEM Read/Write State (MEM - STORE).
			when S5 => 
			  next_state <= S0;
			  
		-- MEM Read/Write State (MEM - LOAD).
			when S6 =>
			  next_state <= S7;
			  
		-- Reg Write State (MEM - LOAD).
			when S7 =>
			  next_state <= S0;
			  
		-- ALU State (BRANCH).
			when S8 =>
					next_state <= S0;
    end case;
end process fsm_process;

-- Select bits for Multiplexors.
S_internal <= 
		-- s2 select set to 1 at State 0 to allow the PC to enter ALU
		"0100" when state = S0 else
		
		-- Jump and Branch instruction - s1 and s2 set to 1 to allow addition of pc and offset
		"1100" when state = S1 else
		
		-- If there is nothing on the immediate bus (therefore no immediate containing instruction)
		-- S1 and S2 mux set to 0 to allow RA and RB pass through.
		-- If Immediate is present then set S1 mux to 1 to allow IMM and RA pass through to ALU.
		"0000" when state = S2 and IMM_in = "0000000000000000" else
		"1000" when state = S2 else
		-- No instance where we manipulate Ra and RB inside ALU, so never 
		-- need S1 at 0. Add Offset to Ra, but this is handled by IMM.
		-- IMM will be set to 0 by decoder for instructions that don't require it
		-- Having no effect when added by ALU.
		
		-- S4 set to 0 to allow write to WA from Aout reg.
		"0000" when state = S3 else
	
		-- No Rb input for ALU in any transfer instructions, only ever use Immediate and Ra.
		"1000" when state = S4 else
		
		-- S3 set to 0 in all Store and Load instructions at State 5/6 as to Directly address Memory (MDA).
		"0000" when state = S5 else
		"0000" when state = S6 else
		
		-- S4 set to 1 to allow the writing of data from Memory into the Register Bank.
		"0001" when state = S7 else
		
		"0000";

-- ALU OPCODE being set dependant on the OPCODE in the 32 bit instruction 
AL <= 
		-- Fetch will always require an increment on the PC 
		"1000" when state = S0 else
		
		-- Branch Instruction verification stage (FLAG Generation) else no ALU activity
		"1010" when state = S1 and OPCODE(5 downto 4) = "11" else
		"0000" when state = S1 else
		
		-- ALU stage for all Logic and Arithmetic instructions (including move)
		"0000" when state = S2 and OPCODE = "000000" else  -- nop
		"1010" when state = S2 and OPCODE = "000001" else  -- add rt, ra, rb
		"1011" when state = S2 and OPCODE = "000010" else  -- sub rt, ra, rb
		"1010" when state = S2 and OPCODE = "000101" else  -- addi rt, ra, imm
		"1011" when state = S2 and OPCODE = "000110" else  -- subi rt, ra, imm
		"1000" when state = S2 and OPCODE = "001001" else  -- inc rt, ra
		"1001" when state = S2 and OPCODE = "001010" else  -- dec rt, ra
		"0111" when state = S2 and OPCODE = "010000" else  -- not rt, ra 
		"0101" when state = S2 and OPCODE = "010001" else  -- or rt, ra, rb
		"0100" when state = S2 and OPCODE = "010010" else  -- and rt, ra,rb
		"0110" when state = S2 and OPCODE = "010011" else  -- xor rt, ra, rb
		"0100" when state = S2 and OPCODE = "010101" else  -- andi rt, ra, imm
		"0101" when state = S2 and OPCODE = "010110" else  -- ori rt, ra, imm
		"0110" when state = S2 and OPCODE = "010111" else  -- xori rt, ra, imm
		"1100" when state = S2 and OPCODE = "011001" else  -- shl rt, ra, n
		"1101" when state = S2 and OPCODE = "011010" else  -- shr rt, ra, n
		"1110" when state = S2 and OPCODE = "011101" else  -- rol rt, ra, n
		"1111" when state = S2 and OPCODE = "011110" else  -- ror rt, ra, n
		"1010" when state = S2 and OPCODE = "100111" else  -- move rt, ra

		-- No ALU activity as State 3 is a REG WRITE
		"0000" when state = S3 else

		-- ALU Stage for all Transfer Instructions (excluding Move)
		"1010" when state = S4 else
		
		-- No ALU activity as State 5 and 6 are MEM READ/WRITE
		"0000" when state = S5 else
		"0000" when state = S6 else
		
		-- No ALU activity as State 7 is a REG WRITE
		"0000" when state = S7 else
		
		-- addition of PC and Offset 
		"1010" when state = S8 else
	
		"0000";

-- Write to memory if in state S4 and OPCODE is a store
OEN <=
		'1' when state = S5 else
		'0';
		
-- Write enable should only be high at write states (State 3 and 7)
WEN <=
		'1' when state = S3 else
		'1' when state = S7 else
		'0';
		
-- Pass through of OPCODE parameters from Decoder.
RA <= RA_in;
RB <= RB_in;
WA <= WA_in;
SH <= N_in;
S <= S_internal;
IMM <= IMM_in;

-- MIA_EN only High in State 0 as this is when instruction are fetched. Gets enabled when Jumping, to jump to new MIA immediately.
MIA_EN <= 
			'1' when state = S0 or (state = S1 and OPCODE(5 downto 3) = "111") else
			'0';

-- PC_EN is set high in state 1 as this is when PC+ enters the sequencer.
-- PC_EN is set high in state 9 as this is when PC+ (from Branch/Jump instruction) enters the sequencer.
PC_EN <=
		'1' when state = S1 else
		'1' when state = S8 and ((FLAG_SET = '1') or opcode (5 downto 3) = "111") else
		'0';

-- based upon the branch OPCODE Flag set will be used as a reference to see if the condition to branch has been met.
FLAG_SET <= FLAGS(0) when OPCODE(2 downto 0) = "001" else
			FLAGS(1) when OPCODE(2 downto 0) = "010" else
			FLAGS(2) when OPCODE(2 downto 0) = "011" else
			FLAGS(3) when OPCODE(2 downto 0) = "100" else
			FLAGS(4) when OPCODE(2 downto 0) = "101" else
			FLAGS(5) when OPCODE(2 downto 0) = "110" else
			FLAGS(6) when OPCODE(2 downto 0) = "111" else
			'0';

end Behavioral;
