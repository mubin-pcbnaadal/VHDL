-------------------------------------------------
-- a4 architecture of gray counter  (question 9)
--   * a3 + generation of clock_out, frequency = f(clk) / (factor+1)
--   * clock_out = '1' while the count is in 0 .. factor/2
--                 '0' while the count is in factor/2+1 .. factor
--     -> one period per counter cycle, 50 % duty cycle when factor+1
--        is even ((factor/2+1) high cycles, the rest low otherwise)
--   * clock_out is REGISTERED (flip-flop on clk) so it is glitch-free,
--     which is mandatory for a signal used as a clock.
-------------------------------------------------

architecture a4 of gray_counter is

  signal g      : unsigned(6 downto 0);   -- Gray state (clk domain)
  signal gs     : std_logic;              -- virtual bit
  signal g_smp  : unsigned(6 downto 0);   -- Gray value sampled by clk2
  signal clk_o  : std_logic;              -- divided clock (register)

begin

  ------------------------------------------------------------------
  -- Gray counter with modulo factor+1 and divided clock
  ------------------------------------------------------------------
  Pcount : process (clk, reset)
    variable low_zero : boolean;
    variable bin      : unsigned(6 downto 0);
  begin
    if reset = '0' then
      g     <= (others => '0');
      gs    <= '1';
      clk_o <= '0';
    elsif rising_edge(clk) then
      if enable = '1' then

        bin := gray2bin(g);

        -- divided clock : high during the first half of the cycle
        if bin <= shift_right(factor, 1) then
          clk_o <= '1';
        else
          clk_o <= '0';
        end if;

        if bin >= factor then
          g  <= (others => '0');
          gs <= '1';
        else
          gs <= not gs;

          if gs = '1' then
            g(0) <= not g(0);
          end if;

          for i in 1 to g'left-1 loop
            low_zero := true;
            for k in 0 to i-2 loop
              if g(k) = '1' then
                low_zero := false;
              end if;
            end loop;
            if gs = '0' and g(i-1) = '1' and low_zero then
              g(i) <= not g(i);
            end if;
          end loop;

          low_zero := true;
          for k in 0 to g'left-2 loop
            if g(k) = '1' then
              low_zero := false;
            end if;
          end loop;
          if gs = '0' and low_zero then
            g(g'left) <= not g(g'left);
          end if;
        end if;

      end if;
    end if;
  end process;

  ------------------------------------------------------------------
  -- Sampling with clk2, then conversion to binary
  ------------------------------------------------------------------
  Psample : process (clk2, reset)
  begin
    if reset = '0' then
      g_smp <= (others => '0');
    elsif rising_edge(clk2) then
      g_smp <= g;
    end if;
  end process;

  count_out <= gray2bin(g_smp);
  clock_out <= clk_o;

end a4 ;
