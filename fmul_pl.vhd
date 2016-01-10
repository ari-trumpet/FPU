library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fmul_pipeline is
  port (
    clk   : in  std_logic;
    xrst  : in  std_logic;
    stall : in  std_logic;
    a     : in  unsigned(31 downto 0);
    b     : in  unsigned(31 downto 0);
    s     : out unsigned(31 downto 0));
end entity fmul_pipeline;

architecture behavior of fmul_pipeline is

  type state_t is (CORNER, NORMAL);

  type latch_t is record
    -- stage 1
    state0 : state_t;
    data0  : fpu_data_t;
    sign0  : unsigned(31 downto 31);
    exp0   : unsigned(8 downto 0);
    afrac  : unsigned(22 downto 0);
    bfrac  : unsigned(22 downto 0);
    -- stage 2
    state1 : state_t;
    data1  : fpu_data_t;
    sign1  : unsigned(31 downto 31);
    exp1   : unsigned(8 downto 0);
    frac   : unsigned(22 downto 0);
  end record latch_t;

  constant latch_init : latch_t := (
    state0 => CORNER,
    data0  => (others => '0'),
    sign0  => (others => '0'),
    exp0   => (others => '0'),
    afrac  => (others => '0'),
    bfrac  => (others => '0'),
    state1 => CORNER,
    data1  => (others => '0'),
    sign1  => (others => '0'),
    exp1   => (others => '0'),
    frac   => (others => '0'));

  signal r, rin : latch_t := latch_init;

begin

  comb: process (r, a, b, stall) is

    variable v: latch_t;

    -- stage 1
    variable fa      : float_t;
    variable fb      : float_t;
    -- stage 2
    variable a_mant  : unsigned(23 downto 0);
    variable b_hmant : unsigned(11 downto 0);
    variable b_lmant : unsigned(11 downto 0);
    variable product : unsigned(24 downto 0);
    variable mant    : unsigned(25 downto 0);
    -- stage 3
    variable exp     : unsigned(8 downto 0);
    variable result  : float_t;


  begin
    v      := r;
    result := float(x"00000000");

    if stall /= '1' then
      -- stage 1
      if is_metavalue(a) or is_metavalue(b) then
        fa := float(x"00000000");
        fb := float(x"00000000");
      else
        fa := float(a);
        fb := float(b);
      end if;

      v.state0 := CORNER;
      v.data0  := (others => '-');

      if (fa.expt = 255 and fa.frac /= 0) or
        (fb.expt = 255 and fb.frac /= 0) then
        v.data0 := VAL_NAN;
      elsif (fa.expt = 255 and fb.expt = 0) or
        (fa.expt = 0 and fb.expt = 255) then
        v.data0 := VAL_NAN;
      elsif fa.expt = 255 or fb.expt = 255 then
        if fa.sign = fb.sign then
          v.data0 := VAL_PLUS_INF;
        else
          v.data0 := VAL_MINUS_INF;
        end if;
      elsif fa.expt = 0 or fb.expt = 0 then
        if fa.sign = fb.sign then
          v.data0 := VAL_PLUS_ZERO;
        else
          v.data0 := VAL_MINUS_ZERO;
        end if;
      else
        v.state0 := NORMAL;
      end if;

      v.afrac := fa.frac;
      v.bfrac := fb.frac;

      v.sign0 := fa.sign xor fb.sign;
      v.exp0  := resize(fa.expt, 9) + resize(fb.expt, 9);

      -- stage 2
      v.state1 := r.state0;
      v.data1  := r.data0;
      v.sign1  := r.sign0;

      a_mant  := '1' & r.afrac;
      b_hmant := '1' & r.bfrac(22 downto 12);
      b_lmant := r.bfrac(11 downto 0);

      product := resize(shift_right(a_mant * b_hmant, 11), 25) + resize(shift_right(a_mant * b_lmant, 23), 25) + 1;

      v.exp1 := r.exp0 + product(24 downto 24);

      if product(24) = '1' then
        v.frac := product(23 downto 1);
      else
        v.frac := product(22 downto 0);
      end if;

      -- stage 3
      result.sign := r.sign1;

      if r.exp1 > 127 then
        if r.exp1 > 381 then
          result.expt := to_unsigned(255, 8);
          result.frac := to_unsigned(0, 23);
        else
          exp := r.exp1 - 127;
          result.expt := exp(7 downto 0);
          result.frac := r.frac;
        end if;
      else
        result.expt := to_unsigned(0, 8);
        result.frac := to_unsigned(0, 23);
      end if;
    end if;

    case r.state1 is
      when CORNER => s <= r.data1;
      when NORMAL => s <= fpu_data(result);
    end case;

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

