library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-------------------------------------- SEQUENCER ------------------------------------

-- Sequencer stores current value of program counter using a register
-- The value of the program counter is changed to that computed by the ALU on the PC_INC
-- line when PC_EN = 1 (generated by FSM). Memory instruction address (address of the next 
-- instruction to execute.) is set to the value of PC.

--------------------------------------------------------------------------------------

entity SEQUENCER is
	 generic (dataSize : natural);
    Port ( PC_INC : in  STD_LOGIC_VECTOR (dataSize-1 downto 0);
           PC : out  STD_LOGIC_VECTOR (dataSize-1 downto 0);
			  PC_EN : in STD_LOGIC;
			  clk : in STD_LOGIC;
			  rst : in STD_LOGIC;
			  MIA : out STD_LOGIC_VECTOR(7 downto 0));
end SEQUENCER;

architecture Behavioral of SEQUENCER is
	-- Internal program counter bus to allow MIA to read from it. Needed as cant read from output port.
	signal PC_internal : STD_LOGIC_VECTOR(dataSize-1 downto 0); 
begin

-- Register to store current value of program counter.
-- Value of PC set to PC_INC when PC enable (generated by FSM) signal goes to 1 
PC_reg: entity work.register_block
		generic map(dataSize => dataSize)
		port map(D => PC_INC, 
		         Q => PC_internal,  
					clk => clk, 
					rst=> rst, 
					En => PC_EN);
		
-- MIA set to value of PC internal. 
MIA<=
		std_logic_vector(resize(unsigned(PC_internal), 8));
		
-- Connect ports to internal signals
PC <=
		PC_internal;
			
end Behavioral;

