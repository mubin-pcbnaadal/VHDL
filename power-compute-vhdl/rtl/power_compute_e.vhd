LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

ENTITY power_compute IS
    GENERIC(
	m : integer :=10 
    );
    PORT(
        reset      : IN std_logic;		-- asynchronous reset
        clock      : IN std_logic;		-- system clock
        C      	   : IN std_logic;		-- command = 1 when computing
	X     	   : IN signed(15 downto 0); 	-- division factor
        P	   : OUT unsigned(29 downto 0)
    );
END power_compute;
