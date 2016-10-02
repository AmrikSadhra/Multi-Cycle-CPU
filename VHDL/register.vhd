library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--use IEEE.NUMERIC_STD.ALL;


entity register_block is
	 generic (dataSize : natural);
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           D : in  STD_LOGIC_VECTOR (dataSize-1 downto 0);
           Q : out  STD_LOGIC_VECTOR (dataSize-1 downto 0);
           En : in  STD_LOGIC);
end register_block;

architecture Behavioral of register_block is
	
begin

m_bit_register : for i in 0 to dataSize-1 generate
	flip_flop: entity work.D_FF
		port map(Q => Q(i), D => D(i), clk => clk, rst=>rst, En => En);
end generate;

end Behavioral;

