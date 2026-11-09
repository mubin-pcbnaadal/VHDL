-------------------------------------------------
-- a2 architecture of gray counter  (question 7)
--   * same Gray counter as a1 (clk domain)
--   * the Gray value is sampled on the rising edge of clk2
--     (asynchronous to clk). Only ONE Gray bit can be changing at
--     that moment, so the sample is either the old or the new value.
--   * the sampled Gray value is then converted to binary (gray2bin)
--   * IMPORTANT : convert AFTER sampling, never before. gray2bin is an
--     xor chain : when one Gray bit changes, several binary bits change,
--     so sampling the binary value would bring back the problem of Q1.
-------------------------------------------------

architecture a2 of gray_counter is

  signal g      : unsigned(6 downto 0);   -- Gray state (clk domain)
  signal gs     : std_logic;              -- virtual bit
  signal g_smp  : unsigned(6 downto 0);   -- Gray value sampled by clk2

begin

  ------------------------------------------------------------------
  -- Gray counter (identical to a1)
  ------------------------------------------------------------------
  Pcount : process (clk, reset)
    variable low_zero : boolean;
  begin
    if reset = '0' then
      g  <= (others => '0');
      gs <= '1';
    elsif rising_edge(clk) then
      if enable = '1' then
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
  end process;

  ------------------------------------------------------------------
  -- Sampling with clk2 (clk2 domain)
  -- (on real hardware, a second register stage would be added here to
  --  filter metastability; it only adds one clk2 period of latency)
  ------------------------------------------------------------------
  Psample : process (clk2, reset)
  begin
    if reset = '0' then
      g_smp <= (others => '0');
    elsif rising_edge(clk2) then
      g_smp <= g;
    end if;
  end process;

  -- binary value of the sample : only changes just after a clk2 edge
  count_out <= gray2bin(g_smp);
  clock_out <= '0';        -- not used yet

end a2 ;
