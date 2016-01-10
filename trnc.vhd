library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpu_common_p.all;

entity ftoi_pipeline is
    port (
      clk   : in std_logic;
      xrst  : in std_logic;
      stall : in std_logic;
      a     : in unsigned(31 downto 0);
      s     : out unsigned(31 downto 0));
end entity ftoi_pipeline;

architecture behavior of ftoi_pipeline is

  type latch_t is record
    a : unsigned(31 downto 0);
    s : unsigned(31 downto 0);
  end record latch_t;

  constant latch_init : latch_t := (
    a => (others => '-'),
    s => (others => '-'));

  signal r, rin : latch_t := latch_init;

  function ftoi(a: fpu_data_t)
    return fpu_data_t is

    variable fa     : float_t;
    variable sign   : std_logic;
    variable diff   : integer range 0 to 128;
    variable result : fpu_data_t;

  begin

    if is_metavalue(a) then
      return (others => 'X');
    end if;

    fa   := float(a);
    sign := fa.sign(0);

    if fa.expt < 127 then
      result := (others => '0');
    else
      diff := to_integer(fa.expt) - 127;

      if diff > 30 then
        result := (others => '0');
      elsif diff < 23 then
        result := resize(shift_right("1" & fa.frac, 23 - diff), 32);
      else
        result := resize(shift_left("1" & fa.frac, diff - 23), 32);
      end if;

      if sign = '1' then
        result := unsigned(- signed(result));
      end if;
    end if;

    return result;
  end function;


begin

  comb: process (r, a, stall) is
    variable v: latch_t;
  begin
    v := r;

    if stall /= '1' then
      v.a    := a;
      v.s    := ftoi(r.a);
    end if;

    s   <= r.s;
    rin <= v;
  end process comb;

  seq: process (clk, xrst) is
  begin
    if xrst = '0' then
      r <= latch_init;
    elsif rising_edge(clk) then
      r <= rin;
    end if;
  end process seq;

end architecture behavior;


