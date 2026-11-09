architecture a1 of test_gray is

----------------------------------------------------
-- all components to be connected
----------------------------------------------------

component gray_counter is
generic ( div2 : integer   -- indicates if a frequency divider by 2 is inserted at the front
         ) ;
port ( clk,reset,clk2 : in std_logic;		-- input clock, reset and sampling clock
    enable     : in std_logic;                  -- enabling counting
    factor    : in unsigned(6 downto 0);	-- division factor
    count_out : out unsigned(6 downto 0);	-- division counter
    clock_out : out std_logic);		-- output clock with divided frequency
end component ;

component digital_gene IS
    PORT(
        reset      : OUT std_logic;
        enable     : OUT std_logic;
	factor     : OUT unsigned(6 downto 0); -- division factor
        clk,clk2   : OUT std_logic
    );
end component;


---------------------------------
-- all the local signals
---------------------------------

signal reset,enable : std_logic ;	 -- reset and logic control
signal clk,clk2 : std_logic ;	 -- reference and sampling clocks
signal clock_out : std_logic ;		-- output clock
signal factor : unsigned(6 downto 0) ;	-- division factor
signal count_out : unsigned(6 downto 0) ;   -- expected phase

begin

-- instanciation of all the components
----------------------------------------

c1 : digital_gene  
        port map(reset,enable,factor,clk,clk2) ;
c2 : entity work.gray_counter(a2)
        generic map(div2 => 1)
	port map(clk,reset,clk2,enable,factor,count_out,clock_out) ;


end architecture a1 ;
