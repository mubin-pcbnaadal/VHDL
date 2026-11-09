architecture a1 of digital_gene is

signal per : time := 50 ns ;
signal clkl : std_logic := '0'  ;

begin

Pinit : process
begin
  reset <= '0' ;
  enable <= '0' ;
  factor <= to_unsigned(19,factor'length) ;	-- division factor of 20
  wait for 250 ns ;
  reset <= '1' ;
  wait for 250 ns ;
  enable <= '1' ;
  wait for 500 ns ;
  wait for 19 us ;
  factor <= to_unsigned(59,factor'length) ;
  wait for 20 us ;
  factor <= to_unsigned(111,factor'length) ;
  wait ;
end process ;

Pclk : process
begin
  wait for per ;
  clkl <= not(clkl) ;
end process ;

Pcl2 : process
begin
  clk2 <= '0' ;	
  wait for 237 ns ;
  clk2 <= '1' ;	
  wait for 237 ns ;
end process ;

clk <= clkl ;
  
end architecture a1 ;

