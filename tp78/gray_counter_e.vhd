library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.myfuncs.all;

entity gray_counter is
generic ( div2 : integer range 0 to 1 := 1	 		--  indicates if a freq divider by 2 is inserted at the front
         ) ;
port ( clk,reset,clk2 : in std_logic;		-- input clock, reset and sampling clock
    enable     : in std_logic;			-- enabling the counting
    factor    : in unsigned(6 downto 0);	-- division factor
    count_out : out unsigned(6 downto 0);	-- division counter
    clock_out : out std_logic);			-- output clock with divided frequency
end gray_counter ;
