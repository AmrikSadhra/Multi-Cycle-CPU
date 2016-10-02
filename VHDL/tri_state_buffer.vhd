library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tri_state_buffer is
	generic (dataSize : natural);
	port (	
				Data_in : in std_logic_vector(dataSize-1 downto 0);
				En : in std_logic;
				Data_out : out std_logic_vector(dataSize-1 downto 0)
			);
end tri_state_buffer;

architecture Behavioral of tri_state_buffer is

begin

Data_out <= 
				Data_in when (En = '1') else 
				(others => 'Z'); -- Z = high-impedance 

end Behavioral;

