-------------------------------------------------
-- a3 architecture of gray counter  (question 8)
--   * Gray counter with programmable modulo : counts 0 .. factor
--     (modulo = factor + 1)
--   * when the counter has reached factor, the next state is 0
--     (g = 0 and virtual bit gs = 1)
--   * the test uses ">=" instead of "=" : if factor is decreased while
--     the counter is already above the new value, the counter goes back
--     to 0 at once instead of running up to 127 and wrapping.
--   * sampling by clk2 + gray2bin as in a2
-------------------------------------------------

architecture a3 of gray_counter is

  signal g      : unsigned(6 downto 0);   -- Gray state (clk domain)
  signal gs     : std_logic;              -- virtual bit
  signal g_smp  : unsigned(6 downto 0);   -- Gray value sampled by clk2

begin

  ------------------------------------------------------------------
  -- Gray counter with modulo factor+1
  ------------------------------------------------------------------
  Pcount : process (clk, reset)
    variable low_zero : boolean;
  begin
    if reset = '0' then
      g  <= (others => '0');
      gs <= '1';
    elsif rising_edge(clk) then
      if enable = '1' then

        if gray2bin(g) >= factor then
          -- end of cycle : back to 0
          g  <= (others => '0');
          gs <= '1';
        else
          -- normal Gray increment (same as a1)
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
  clock_out <= '0';        -- not used yet

end a3 ;
