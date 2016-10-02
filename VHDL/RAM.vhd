library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.ALL;

-- SYNCHRONOUS WRITE / ASYNCHROUNOUS READ PARAMATERISABLE SINGLE-PORT RAM --
entity RAM is
    Port ( clk : in  STD_LOGIC;
           WEn : in  STD_LOGIC; -- Write Enable, allows Data_In to be stored at Address when high
			  INST_OUT 
           DATA_IN : in  STD_LOGIC_VECTOR (31 downto 0); -- Data to be written to RAM at address
           Address : in  STD_LOGIC_VECTOR (11 downto 0); -- Address for Data_In to be written to
           DATA_OUT : out  STD_LOGIC_VECTOR (31 downto 0)); -- Data present at Address
end RAM;

architecture Behavioral of RAM is


-- Size of RAM is equal to number of elements in output Matrix C
type ram_type is array (0 to 127) of STD_LOGIC_VECTOR(31 downto 0);
	signal ram_inst: ram_type;
begin

-- Asynchronous read
  Data_Out <= ram_inst(to_integer(unsigned(Address()));
  
-- Synchronous write (write enable signal)
  process (clk)
  begin
    if (rising_edge(clk)) then 
		if (WEn = '1') then
          ram_inst(to_integer(unsigned(Address))) <= Data_In;
	   end if;
    end if;
  end process;
  
end Behavioral;

