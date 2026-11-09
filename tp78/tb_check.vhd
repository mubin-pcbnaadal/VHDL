-- Self-checking testbench : all architectures in parallel, same stimuli
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.myfuncs.all;

entity tb_check is
end tb_check;

architecture sim of tb_check is
  signal reset, enable, clk, clk2 : std_logic;
  signal factor : unsigned(6 downto 0);
  type uarr is array (1 to 6) of unsigned(6 downto 0);
  signal cnt  : uarr;
  signal cko  : std_logic_vector(1 to 6);
  signal errors : integer := 0;
  constant T : time := 100 ns;
begin
  gen : entity work.digital_gene(a1) port map(reset, enable, factor, clk, clk2);

  d1 : entity work.gray_counter(a1) generic map(1) port map(clk,reset,clk2,enable,factor,cnt(1),cko(1));
  d2 : entity work.gray_counter(a2) generic map(1) port map(clk,reset,clk2,enable,factor,cnt(2),cko(2));
  d3 : entity work.gray_counter(a3) generic map(1) port map(clk,reset,clk2,enable,factor,cnt(3),cko(3));
  d4 : entity work.gray_counter(a4) generic map(1) port map(clk,reset,clk2,enable,factor,cnt(4),cko(4));
  d5 : entity work.gray_counter(a5) generic map(1) port map(clk,reset,clk2,enable,factor,cnt(5),cko(5));
  d6 : entity work.gray_counter(a5) generic map(0) port map(clk,reset,clk2,enable,factor,cnt(6),cko(6));

  -- a1 : every change is a single-bit change and a +1 step (mod 128)
  Pa1 : process
    variable prev : unsigned(6 downto 0);
    variable diff : unsigned(6 downto 0);
    variable n : integer := 0; variable ones : integer;
  begin
    wait until reset = '1';
    prev := cnt(1);
    loop
      wait on cnt(1);
      diff := cnt(1) xor prev; ones := 0;
      for i in diff'range loop if diff(i) = '1' then ones := ones + 1; end if; end loop;
      assert ones = 1 report "a1: more than one bit changed" severity error;
      assert gray2bin(cnt(1)) = gray2bin(prev) + 1 report "a1: not a +1 step" severity error;
      prev := cnt(1); n := n + 1;
      if n = 300 then report "a1: 300 transitions checked (2+ full wraps)"; end if;
    end loop;
  end process;

  -- a2 / a3 : sampled binary values advance by 4 or 5 every clk2 period
  --           (474 ns / 100 ns = 4.74 clk cycles); a3 stays <= factor
  Pa23 : process
    variable p2, p3 : unsigned(6 downto 0);
    variable d : integer; variable m : integer; variable n : integer := 0;
    variable fprev : unsigned(6 downto 0);
  begin
    wait until enable = '1';
    wait until rising_edge(clk2); wait for 1 ns;
    p2 := cnt(2); p3 := cnt(3); fprev := factor;
    loop
      wait until rising_edge(clk2); wait for 1 ns;
      d := (to_integer(cnt(2)) - to_integer(p2)) mod 128;
      assert d = 4 or d = 5 report "a2: bad step " & integer'image(d) severity error;
      assert cnt(3) <= factor report "a3: count above factor" severity error;
      if factor = fprev then
        m := to_integer(factor) + 1;
        d := (to_integer(cnt(3)) - to_integer(p3)) mod m;
        assert d = 4 or d = 5 report "a3: bad step " & integer'image(d) severity error;
      end if;
      p2 := cnt(2); p3 := cnt(3); fprev := factor; n := n + 1;
    end loop;
  end process;

  -- a4, a5(div2=1), a5(div2=0) : period of clock_out = (factor+1)*T
  Gper : for k in 4 to 6 generate
    Pper : process
      variable tr, tf, tprev : time := 0 ns; variable f : unsigned(6 downto 0);
      variable ok : integer := 0; variable skip : integer := 1;
    begin
      wait until enable = '1';
      wait until rising_edge(cko(k)); tprev := now; f := factor;
      loop
        wait until falling_edge(cko(k)); tf := now;
        wait until rising_edge(cko(k)); tr := now;
        if factor = f and skip > 0 then
          skip := skip - 1;
        elsif factor = f then
          assert tr - tprev = (to_integer(factor)+1) * T
            report "dut" & integer'image(k) & ": period " & time'image(tr-tprev) &
                   " expected " & time'image((to_integer(factor)+1)*T) severity error;
          ok := ok + 1;
        else
          report "dut" & integer'image(k) & ": factor " & integer'image(to_integer(f)) &
                 " -> " & integer'image(ok) & " periods OK, last high/low = " &
                 time'image(tf - tprev) & " / " & time'image(tr - tf);
          ok := 0; skip := 1;
        end if;
        tprev := tr; f := factor;
      end loop;
    end process;
  end generate;

  Pend : process
  begin
    wait for 100 us;
    report "END OF SIMULATION" severity note;
    std.env.stop;
  end process;
end sim;
