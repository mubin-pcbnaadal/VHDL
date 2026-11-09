-------------------------------------------------
-- a5 architecture of gray counter  (question 10, subsidiary)
--   * a4 + generic div2 :
--       div2 = 1 : clk is first divided by 2 (toggle flip-flop) and the
--                  counter runs on clk_int = clk/2
--       div2 = 0 : clk_int = clk (behaviour identical to a4)
--   * to keep the SAME output frequency f(clk)/(factor+1), the internal
--     modulo must be halved :  (fi+1) = (factor+1)/2
--       -> fi = (factor+1)/2 - 1 = factor/2  (= shift_right(factor,1))
--     exact when factor+1 is even (19->9, 59->29, 111->55 in the
--     testbench). When factor+1 is odd an exact division is impossible
--     with this structure; the ratio becomes factor+2.
-------------------------------------------------

architecture a5 of gray_counter is

  signal clk_int : std_logic;             -- clock of the counter
  signal clk_div : std_logic;             -- clk / 2
  signal fi      : unsigned(6 downto 0);  -- internal (effective) factor
  signal g       : unsigned(6 downto 0);  -- Gray state (clk_int domain)
  signal gs      : std_logic;             -- virtual bit
  signal g_smp   : unsigned(6 downto 0);  -- Gray value sampled by clk2
  signal clk_o   : std_logic;             -- divided clock (register)

begin

  ------------------------------------------------------------------
  -- Optional divider by 2 in front of the counter
  ------------------------------------------------------------------
  Gdiv2 : if div2 = 1 generate
    Pdiv2 : process (clk, reset)
    begin
      if reset = '0' then
        clk_div <= '0';
      elsif rising_edge(clk) then
        clk_div <= not clk_div;
      end if;
    end process;
    clk_int <= clk_div;
    fi      <= shift_right(factor, 1);     -- (factor+1)/2 - 1
  end generate;

  Gnodiv : if div2 = 0 generate
    clk_div <= '0';                        -- unused
    clk_int <= clk;
    fi      <= factor;
  end generate;

  ------------------------------------------------------------------
  -- Gray counter with modulo fi+1 and divided clock (same as a4,
  -- but clocked by clk_int and using fi)
  ------------------------------------------------------------------
  Pcount : process (clk_int, reset)
    variable low_zero : boolean;
    variable bin      : unsigned(6 downto 0);
  begin
    if reset = '0' then
      g     <= (others => '0');
      gs    <= '1';
      clk_o <= '0';
    elsif rising_edge(clk_int) then
      if enable = '1' then

        bin := gray2bin(g);

        if bin <= shift_right(fi, 1) then
          clk_o <= '1';
        else
          clk_o <= '0';
        end if;

        if bin >= fi then
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

end a5 ;
