library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-------------------------------- DUAL PORT MEMORY ------------------------------------

-- This source file functions as a wrapper for the generated distributed IP core created
-- by Xilinx.

--------------------------------------------------------------------------------------
entity DP_MEM is
	Port(clk : in STD_LOGIC;
		  INST_ADDRESS : in  STD_LOGIC_VECTOR (6 downto 0); -- Address for instruction, connected to MIA
		  DATA_ADDRESS : in  STD_LOGIC_VECTOR (6 downto 0); -- Address for DATA
		  DATA_In : in STD_LOGIC_VECTOR(31 downto 0); -- Data to write to memory core
		  WEn : in STD_LOGIC; -- Write enable for DATA_IN to DATA_ADDRESS
		  Data_Out : out STD_LOGIC_VECTOR(31 downto 0); -- Output data presebt at DATA address
		  INSTR_DATA : out STD_LOGIC_VECTOR(31 downto 0) -- 32 bit instruction output present at INST_ADDRESS
		  );
end DP_MEM;

architecture Behavioral of DP_MEM is
  COMPONENT RAM_int
  PORT (
    a : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    d : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dpra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    clk : IN STD_LOGIC;
    we : IN STD_LOGIC;
    spo : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dpo : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;
begin

-- INST_DATA_ADDRESS <= 
Internal_RAM : RAM_int
  PORT MAP (
    a => DATA_ADDRESS,
    d => DATA_In,
    dpra => INST_ADDRESS,
    clk => clk,
    we => WEn,
    spo => Data_Out,
    dpo => INSTR_DATA
  );

end Behavioral;

