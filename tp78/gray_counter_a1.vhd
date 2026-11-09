-------------------------------------------------
-- a1 architecture of gray counter
-- gray counter alone  (question 6)
--   * 7-bit Gray counter + virtual bit gs
--   * reset is active LOW (see digital_gene : reset='0' at start)
--   * enable='1' -> count, enable='0' -> hold
--   * count_out = raw Gray value (no conversion, no sampling yet)
--   * factor, div2, clk2 and clock_out are not used yet
-------------------------------------------------

architecture a1 of gray_counter is

  signal g  : unsigned(6 downto 0);   -- Gray code state
  signal gs : std_logic;              -- virtual bit (='1' when count is even)

begin

  Pcount : process (clk, reset)
    variable low_zero : boolean;      -- true when the bits below a given rank are all '0'
  begin
    if reset = '0' then
      g  <= (others => '0');
      gs <= '1';                      -- virtual bit = 1 when counter = 0
    elsif rising_edge(clk) then
      if enable = '1' then

        -- virtual bit : toggles every clock cycle
        gs <= not gs;

        -- bit 0 : toggles when gs = 1          (g0+ = g0 xor gs)
        if gs = '1' then
          g(0) <= not g(0);
        end if;

        -- intermediate bits i = 1 .. n-2 :
        -- toggle when g(i-1)=1, g(i-2..0)=0 and gs=0
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

        -- MSB : toggles when g(n-3..0)=0 and gs=0 (g(n-2) is "don't care")
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

  count_out <= g;          -- Gray value, directly
  clock_out <= '0';        -- not used yet

end a1 ;
