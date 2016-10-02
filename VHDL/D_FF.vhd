library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

-- D Type flip flop. Sets output to input when clocked. 
-- Sets output to 0 when reset signal high.
entity D_FF is
Port ( 	clk : in STD_LOGIC;
			rst : in STD_LOGIC;
			D : in STD_LOGIC; -- Flip flop input bit
			Q : out STD_LOGIC;
			En : in STD_LOGIC
			); -- Flip flop output bit
end D_FF;

architecture Behavioral of D_FF is
begin 

process (clk)
begin
	if rising_edge(clk) then -- If clocked, set output to input
		if rst = '1' then -- If reset signal when clocked, reset output to 0
			Q <= '0'; 
		else
			if (En = '1') then
				Q <= D;
			end if;
		end if;
	end if;
end process;

end Behavioral;