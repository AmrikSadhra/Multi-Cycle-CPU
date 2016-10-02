library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE ieee.std_logic_unsigned.all;
use work.DigEng.ALL; 

entity decoder is
	generic(M : natural);
    Port ( Data_Out : out  STD_LOGIC_VECTOR (M-1 downto 0);
           En : in  STD_LOGIC;
           Data_In : in  std_logic_vector (log2(M)-1 downto 0));
end decoder;

architecture Behavioral of decoder is
	signal output : std_logic_vector(M-1 downto 0);
begin

DECODE_PROC:
    process (Data_In, En, output)
	 begin
		output <= (others => '0'); 
		output(to_integer(unsigned(Data_In))) <= '1';
		
		if (En = '1') then
			Data_Out <= output;
		else
			Data_Out <=	(others => '0');
		end if;
end process;
				
end Behavioral;

