----------------------------------------------------------------------
-- power_compute : architecture a1
--
--   P = (1/N) * sum_{k=0}^{N-1} x_k^2      with N = 2**m
--
-- Structure : one control unit (Moore FSM) + one data path
--
--  Control signals (FSM -> data path)
--    clr_cnt : synchronous clear of the sample counter
--    inc_cnt : increment of the sample counter
--    init    : adder mux select  (1 : 0 + x^2  /  0 : ACC + x^2)
--    ld_acc  : load of the accumulator register ACC
--    ld_p    : load of the output register P   (P <= SUM / N)
--
--  Status signal (data path -> FSM)
--    end_cnt : '1' when CNT = N-2  (the next sample is the last one)
--
--  Operand sizes (computed from m)
--    X        : signed 16 bits      |x| <= 2**15
--    SQ = x^2 : unsigned 31 bits    x^2 <= 2**30
--    ACC, SUM : unsigned 31+m bits  sum <= 2**(30+m)
--    CNT      : unsigned m bits     0 .. N-1
--    P        : unsigned 30 bits    = SUM(29+m downto m)   (division by 2**m)
----------------------------------------------------------------------

architecture a1 of power_compute is

  constant N : natural := 2**m ;

  ------------------------------------------------------------------
  -- state machine
  ------------------------------------------------------------------
  type state_type is (IDLE, FIRST, ACCU, LAST) ;
  signal state, next_state : state_type ;

  ------------------------------------------------------------------
  -- control / status signals
  ------------------------------------------------------------------
  signal clr_cnt, inc_cnt, init, ld_acc, ld_p : std_logic ;
  signal end_cnt : std_logic ;

  ------------------------------------------------------------------
  -- data path signals
  ------------------------------------------------------------------
  signal sq    : unsigned(30 downto 0) ;        -- x^2
  signal acc   : unsigned(30+m downto 0) ;      -- accumulator register
  signal opa   : unsigned(30+m downto 0) ;      -- adder operand (mux output)
  signal sum   : unsigned(30+m downto 0) ;      -- adder output
  signal cnt   : unsigned(m-1 downto 0) ;       -- sample counter
  signal p_reg : unsigned(29 downto 0) ;        -- output register

begin

  assert m >= 1 report "power_compute : m must be >= 1" severity failure ;

  ------------------------------------------------------------------
  -- CONTROL UNIT
  ------------------------------------------------------------------

  -- state register
  state_reg : process(clock, reset)
  begin
    if reset = '1' then
      state <= IDLE ;
    elsif rising_edge(clock) then
      state <= next_state ;
    end if ;
  end process ;

  -- next state computation
  next_state_logic : process(state, C, end_cnt)
  begin
    next_state <= state ;
    case state is
      when IDLE  =>                      -- standby, waiting for C
        if C = '1' then
          next_state <= FIRST ;
        end if ;
      when FIRST =>                      -- 1st sample : ACC <= x^2
        if end_cnt = '1' then
          next_state <= LAST ;
        else
          next_state <= ACCU ;
        end if ;
      when ACCU  =>                      -- ACC <= ACC + x^2
        if end_cnt = '1' then
          next_state <= LAST ;
        end if ;
      when LAST  =>                      -- last sample : P <= (ACC + x^2)/N
        if C = '1' then
          next_state <= FIRST ;          -- back-to-back computations
        else
          next_state <= IDLE ;           -- finish, then standby
        end if ;
    end case ;
  end process ;

  -- outputs (Moore : depend on the state only)
  clr_cnt <= '1' when state = IDLE or state = LAST   else '0' ;
  inc_cnt <= '1' when state = FIRST or state = ACCU  else '0' ;
  init    <= '1' when state = FIRST                  else '0' ;
  ld_acc  <= '1' when state = FIRST or state = ACCU  else '0' ;
  ld_p    <= '1' when state = LAST                   else '0' ;

  ------------------------------------------------------------------
  -- DATA PATH
  ------------------------------------------------------------------

  -- squarer : 16x16 signed product, always >= 0 and <= 2**30
  squarer : process(X)
    variable prod : signed(31 downto 0) ;
  begin
    prod := X * X ;
    sq   <= unsigned(prod(30 downto 0)) ;
  end process ;

  -- adder with its operand multiplexer
  opa <= (others => '0') when init = '1' else acc ;
  sum <= opa + resize(sq, sum'length) ;

  -- accumulator register
  acc_reg : process(clock, reset)
  begin
    if reset = '1' then
      acc <= (others => '0') ;
    elsif rising_edge(clock) then
      if ld_acc = '1' then
        acc <= sum ;
      end if ;
    end if ;
  end process ;

  -- sample counter (m bits)
  counter : process(clock, reset)
  begin
    if reset = '1' then
      cnt <= (others => '0') ;
    elsif rising_edge(clock) then
      if clr_cnt = '1' then
        cnt <= (others => '0') ;
      elsif inc_cnt = '1' then
        cnt <= cnt + 1 ;
      end if ;
    end if ;
  end process ;

  end_cnt <= '1' when cnt = to_unsigned(N-2, cnt'length) else '0' ;

  -- output register : division by N = 2**m is a right shift by m bits.
  -- SUM(30+m) can only be '1' if every sample equals -32768 :
  -- the result is then saturated to the largest 30-bit value.
  out_reg : process(clock, reset)
  begin
    if reset = '1' then
      p_reg <= (others => '0') ;
    elsif rising_edge(clock) then
      if ld_p = '1' then
        if sum(30+m) = '1' then
          p_reg <= (others => '1') ;
        else
          p_reg <= sum(29+m downto m) ;
        end if ;
      end if ;
    end if ;
  end process ;

  P <= p_reg ;

end architecture a1 ;
