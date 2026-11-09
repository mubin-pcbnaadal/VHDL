architecture a1 of test_power_compute is

----------------------------------------------------
-- all components to be connected
----------------------------------------------------

component power_compute IS
    GENERIC(
	m : integer :=10
    );
    PORT(
        reset      : IN std_logic;		-- asynchronous reset
        clock      : IN std_logic;		-- system clock
        C      	   : IN std_logic;		-- command = 1 when computing
	X     	   : IN signed(15 downto 0); 	-- input sample
        P	   : OUT unsigned(29 downto 0)
    );
END component power_compute;

-- explicit binding (portable : strict VHDL-93 does not bind by default
-- unless the entity is directly visible)
for c1 : power_compute use entity work.power_compute(a1) ;


---------------------------------
-- test parameters
---------------------------------

constant m_tb : integer := 10 ;               -- generic parameter used for the DUT
constant N    : integer := 2**m_tb ;          -- samples per computation
-- one computation (N samples) lasts 1000 ms = exactly 50 periods of the 50 Hz sine,
-- so the mean of x^2 over a window is exactly A^2/2
constant Tclk : time := 1000 ms / N ;
constant Tcalc: time := N*Tclk ;              -- duration of one computation
constant NB_CALC : integer := 9 ;             -- number of windows simulated

---------------------------------
-- all the local signals
---------------------------------

signal reset,C : std_logic ;	 			-- reset and logic control
signal clock : std_logic :='0' ;	 		-- reference clock
signal X : signed(15 downto 0) := (others => '0') ;	-- input samples
signal P : unsigned(29 downto 0) ;   -- computed power
signal sim_end : boolean := false ;

signal amp : real := 32767.0 ;			-- generated signal amplitude
constant freq : real := 50.0 ;			-- generated signal frequency

begin

-- instanciation of power compute component
----------------------------------------

c1 : power_compute generic map (m => m_tb)
                   port map (reset => reset, clock => clock, C => C, X => X, P => P) ;

-- test signals generation

reset <= '1', '0' after Tclk/4 ;
clock <= not clock after Tclk/2 when not sim_end else '0' ;
-- C = 1 for windows 0..3, dropped in the middle of window 3 (the operator must
-- finish it, then go to standby), back to 1 just before window 5 starts.
C <= '1', '0' after 3*Tcalc + Tcalc/2, '1' after 5*Tcalc + Tclk/4 ;

-- amplitude divided by 2 every N samples.
-- The FSM samples C on the first rising edge (IDLE -> FIRST) and takes its first
-- sample on the second one, so window w uses samples w*N+1 .. w*N+N.
-- The amplitude is therefore changed between sample w*N+N and sample w*N+N+1.
p1 : process
begin
  wait for Tclk/2 + Tcalc ;
  while not sim_end loop
    amp <= amp/2.0 ;
    wait for Tcalc ;
  end loop ;
  wait ;
end process ;

-- sine generation : a new sample on each falling edge.
-- (phase computed from a sample counter : now/(1 ns) would overflow
--  the 32-bit integer range after 2.147 s of simulated time)
p2 : process(clock)
variable phase : real ;
variable k : integer := 0 ;
constant Ts : real := real(Tclk / 1 ns) * 1.0e-9 ;
begin
  if falling_edge(clock) then
	k := k + 1 ;
	phase := 2.0*MATH_PI*freq*real(k)*Ts ;
	X <= to_signed(integer(amp*sin(phase)),X'length);
  end if ;
end process ;

-- end of simulation
p3 : process
begin
  wait for NB_CALC*Tcalc + Tcalc/2 ;
  sim_end <= true ;
  report "END OF SIMULATION" severity note ;
  wait ;
end process ;

-- automatic check : each new P is compared with A^2/2 and with the previous result
check : process(P)
variable w        : integer ;
variable a, pexp  : real ;
variable prev     : real := 0.0 ;
variable err      : real ;
begin
  if now > Tclk and not sim_end then
    w    := (now - Tclk/2) / Tcalc - 1 ;          -- index of the window just finished
    a    := 32767.0 / (2.0**w) ;
    pexp := a*a/2.0 ;
    err  := abs(real(to_integer(P)) - pexp) ;
    report "window " & integer'image(w) &
           " : P = " & integer'image(to_integer(P)) &
           "  expected ~ " & integer'image(integer(pexp)) &
           "  ratio prev/P = " & real'image(prev / real(to_integer(P))) ;
    assert err <= 0.01*pexp + 2.0
      report "P differs from A^2/2 by more than 1 %" severity error ;
    prev := real(to_integer(P)) ;
  end if ;
end process ;

end architecture a1 ;
