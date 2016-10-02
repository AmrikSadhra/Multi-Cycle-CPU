LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY CPU_TEST IS
END CPU_TEST;
 
ARCHITECTURE behavior OF CPU_TEST IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top_level
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         LED_BUS : OUT  std_logic_vector(15 downto 0);
         PB : IN  std_logic
			);
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal PB : std_logic := '0';

 	--Outputs
   signal LED_BUS : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top_level PORT MAP (
          clk => clk,
          rst => rst,
          LED_BUS => LED_BUS,
          PB => PB
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		rst <='1';
		wait for clk_period*2;
		rst <= '0';
		wait for clk_period*2;
   

		PB <= '1';
		
		
		wait for 300 ns;
		
		PB <= '0';
	
      wait;
   end process;

END;
