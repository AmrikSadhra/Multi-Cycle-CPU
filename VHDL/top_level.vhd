library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE ieee.std_logic_unsigned.all;
use work.DigEng.ALL; 

entity top_level is
	 generic (dataSize : natural := 16;
				 numRegisters : natural := 32;
				 numRegistersBase : natural := 5;
				 busSize : natural := 4);
    Port ( clk: in  STD_LOGIC;
			  rst: in  STD_LOGIC;
			  LED_BUS : out STD_LOGIC_VECTOR(15 downto 0);
			  PB : in STD_LOGIC);
end top_level;

architecture Behavioral of top_level is
	------- CONTROL UNIT TO PROCESSING UNIT -----------
	signal FSMToRegbank_RA : STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
	signal FSMToRegbank_RB : STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
	signal FSMToRegbank_WA : STD_LOGIC_VECTOR (numRegistersBase-1 downto 0);
	signal FSMToRegBank_WEN : STD_LOGIC;
	
	signal FSMToDatapath_IMM : STD_LOGIC_VECTOR(dataSize -1 downto 0);
	signal FSMToDatapath_WEN : STD_LOGIC;
	signal FSMToDatapath_S : STD_LOGIC_VECTOR (3 downto 0);

	signal FSMToALU_AL : STD_LOGIC_VECTOR (3 downto 0);
	signal FSMToALU_SH : STD_LOGIC_VECTOR (busSize-1 downto 0);
	
	signal PC : STD_LOGIC_VECTOR (dataSize-1 downto 0);
	
	---------- PROCESSING UNIT TO CONTROL UNIT -----------------
	signal PC_INC : STD_LOGIC_VECTOR (dataSize-1 downto 0);
	signal FLAGS : STD_LOGIC_VECTOR (6 downto 0);
	
	---------- CONTROL UNIT TO MMU -------------------
	signal SeqToMMU_MIA : STD_LOGIC_VECTOR(7 downto 0);
	signal FSMToMMU_OEN : STD_LOGIC;

	------------ PROCESSING UNIT TO MMU -----------------
	signal IN_DMEM : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	signal OUT_DMEM : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	signal MDA : STD_LOGIC_VECTOR(dataSize-1 downto 0);
	
	-------------- MMU TO DPMEM ------------
	signal MMUToDPMem_INST_ADDR : STD_LOGIC_VECTOR(6 downto 0);
	signal MMUToDPMem_DATA_TOWRITE : STD_LOGIC_VECTOR(31 downto 0);
	signal MMUToDPMem_DATA_READOUT : STD_LOGIC_VECTOR(31 downto 0);
	signal MMUToDPMem_DATA_ADDR : STD_LOGIC_VECTOR(6 downto 0);
	signal MMUToDPMem_WEn : STD_LOGIC;
	
	---- MMU TO MMIO -----
	signal MMUToOutputReg_DATA : STD_LOGIC_VECTOR(15 downto 0);
	signal MMUToOutputReg_WEn : STD_LOGIC;
	
	---- DPMEM TO CONTROL -----
	signal DPMEMToControl_INSTR : STD_LOGIC_VECTOR(31 downto 0);
	
begin

-------- INSTANTIATION OF ENTITIES REQUIRED FOR PROCESSOR --------

-- Instantiation of processing unit containing ALU and register bank
-- along with S muxes.
PROCESSING_UNIT: entity work.PROCESSING_UNIT
	generic map(numRegisters => numRegisters, 
					numRegistersBase => numRegistersBase, 
					dataSize => dataSize, 
					shiftSize => busSize)
	port map(clk=> clk,
				rst=> rst,
				RA => FSMToRegbank_RA,
				RB => FSMToRegbank_RB,
				WA => FSMToRegbank_WA,
				IMM => FSMToDatapath_IMM,
				WEN => FSMToDatapath_WEN,
				S => FSMToDatapath_S,
				AL => FSMToALU_AL,
				SH => FSMToALU_SH,
				FLAGS => FLAGS,
				PC => PC,
				PC_INC=> PC_INC,
				IN_DMEM => IN_DMEM,
				OUT_DMEM => OUT_DMEM,
				MDA => MDA);

-- Instantiation of control logic (including FSM, instruction register, instruction decoder and sequencer)
CONTROL_UNIT: entity work.CONTROL_UNIT
	generic map(numRegisters => numRegisters, 
					numRegistersBase => numRegistersBase, 
					dataSize => dataSize, 
					busSize => busSize)
	port map(clk  => clk,
				rst  => rst,
				INSTRUCTION => DPMEMToControl_INSTR, 
				MIA  => SeqToMMU_MIA,
				RA => FSMToRegbank_RA,
				RB => FSMToRegbank_RB,
				WA => FSMToRegbank_WA,
				IMM => FSMToDatapath_IMM,
				OEN => FSMToMMU_OEN,
				WEN => FSMToDatapath_WEN,
				S => FSMToDatapath_S,
				AL => FSMToALU_AL,
				SH => FSMToALU_SH,
				FLAGS => FLAGS,
				PC => PC,
				PC_INC  => PC_INC);

-- Instantiation of IP core memory wrapper for DUAL PORT MEMORY		
DUAL_PORT_MEM: entity work.DP_MEM
	port map(clk => clk,
				INST_ADDRESS => MMUToDPMem_INST_ADDR,
				DATA_ADDRESS => MMUToDPMem_DATA_ADDR,
				DATA_In => MMUToDPMem_DATA_TOWRITE,
				WEn => MMUToDPMem_WEn,
				Data_Out  => MMUToDPMem_DATA_READOUT,
				INSTR_DATA => DPMEMToControl_INSTR);

-- Instantiation of MMU to write correctly into 128x32 distributed ip core
MMU: entity work.MMU
	port map(MIA  => SeqToMMU_MIA,
				DMEM_RW_ADDRESS => MDA,
				DMEM_OUT_TOPROC => IN_DMEM,
				DMEM_IN_FROMPROC => OUT_DMEM,
				OEn => FSMToMMU_OEN,

				INST_ADDRESS => MMUToDPMem_INST_ADDR ,
				
				DMEM_DATA_TOWRITE => MMUToDPMem_DATA_TOWRITE,
				DMEM_DATA_READOUT => MMUToDPMem_DATA_READOUT,
				
				DATA_ADDRESS => MMUToDPMem_DATA_ADDR,
				DMEM_WEn => MMUToDPMem_WEn ,
 
 				MMIO_DATA  => MMUToOutputReg_DATA,
				MMIO_WEn => MMUToOutputReg_WEn,
				PB_IN => PB);

-- Instantiation of output register connected at memory address h01F8
output_Reg: entity work.register_block
		generic map(dataSize => 16)
		port map(D => MMUToOutputReg_DATA, 
					Q => LED_BUS, 
					clk => clk, rst=> rst, 
					En => MMUToOutputReg_WEn);

end Behavioral;

