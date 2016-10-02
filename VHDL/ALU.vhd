library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_signed.all;
use work.DigEng.ALL;

-- Parameterizable (by Number Size) Arithmetic and Logic Unit 
-- Supported operations: Addition, Subtraction, Bitwise logic, Shift/Rotate
entity ALU is
	generic (dataSize : natural);
    Port ( A : in  STD_LOGIC_VECTOR (dataSize-1 downto 0); -- Input number A to be manipulated
           B : in  STD_LOGIC_VECTOR (dataSize-1 downto 0); -- Input number B for use in addition/subtraction
           X : in  STD_LOGIC_VECTOR (log2(dataSize)-1 downto 0); -- Number of bits to shift/rotate A by
			  OPCODE : in  STD_LOGIC_VECTOR (3 downto 0); -- Specifies operation for ALU to perform
           ALU_OUT : out  STD_LOGIC_VECTOR (dataSize-1 downto 0); -- Result of ALU operation
           FLAGS : out  STD_LOGIC_VECTOR (6 downto 0) -- Flag bus to provide metadata for ALU result
           );
end ALU;

architecture Behavioral of ALU is
-- Internal signal for later use in flag generation 
-- as output bus ALU_OUT cannot be read from
	signal INT_OUT : SIGNED (dataSize-1 downto 0);
begin

INT_OUT <=
				signed(A) when OPCODE = "0000" else
				-- Bitwise operations (cast A and B to signed for
				-- direct allocation to signed bus)
				signed(A AND B) when OPCODE  = "0100" else 
				signed(A OR B) when OPCODE = "0101" else 
				signed(A XOR B) when OPCODE = "0110" else
				signed(NOT (A)) when OPCODE = "0111" else
				-- Arithmetic operations
				signed(A) + 1 when OPCODE = "1000" else 
				signed(A) - 1 when OPCODE = "1001" else 
				signed(A + B) when OPCODE = "1010" else
				signed(A - B) when OPCODE = "1011" else
				-- Shift/Rotate operations
				shift_left(signed(A), to_integer(unsigned(X))) when OPCODE = "1100" else
				shift_right(signed(A), to_integer(unsigned(X))) when OPCODE = "1101" else
				rotate_left(signed(A), to_integer(unsigned(X))) when OPCODE = "1110" else
				rotate_right(signed(A), to_integer(unsigned(X))) when OPCODE = "1111" else
				signed(A);
						
-- Flag generation dependent upon value of ALU result					
FLAGS(0) <= 
				'1' when INT_OUT = 0 else
				'0';
FLAGS(1) <= 
				'1' when INT_OUT /= 0 else
				'0';
FLAGS(2) <= 
				'1' when INT_OUT = 1 else
				'0';
FLAGS(3) <= 
				'1' when INT_OUT < 0 else
				'0';
FLAGS(4) <= 
				'1' when INT_OUT > 0 else
				'0';
FLAGS(5) <= 
				'1' when INT_OUT <= 0 else
				'0';
FLAGS(6) <= 
				'1' when INT_OUT >= 0 else
				'0';
				
		
---- Overflow bit generation, not required for CPU
--FLAGS(7) <= 
--				'1' when OPCODE = "1000" AND (A(dataSize-1) /= INT_OUT(dataSize-1)) else -- Addition by 1: Overflow if MSB has changed from A to output
--				'1' when OPCODE = "1001" AND (A(dataSize-1) /= INT_OUT(dataSize-1)) else -- Subtraction by 1: Overflow if MSB has changed from A to output
--				'1' when OPCODE = "1010" AND ((A(dataSize-1) AND (B(dataSize-1))) /= INT_OUT(dataSize-1)) else -- Addition of B to A: overflow if A and B MSB's are
--																												  -- 1 and MSB in output has changed
--				'1' when OPCODE = "1011" AND ((A(dataSize-1) AND (B(dataSize-1))) /= INT_OUT(dataSize-1)) else -- Subtraction of B from A: overflow if A and B MSB's are
--																												  -- 1 and MSB in output has changed
--				'0';
				
-- Assign internal bus to module external output
ALU_OUT <= std_logic_vector(INT_OUT);

end Behavioral;

