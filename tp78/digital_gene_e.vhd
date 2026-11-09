LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

ENTITY digital_gene IS
    PORT(
        reset      : OUT std_logic;
        enable     : OUT std_logic;
	factor     : OUT unsigned(6 downto 0); -- division factor
        clk,clk2   : OUT std_logic
    );
END digital_gene;
