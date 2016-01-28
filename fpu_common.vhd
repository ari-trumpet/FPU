library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fpu_common_p is

  subtype fpu_data_t is unsigned(31 downto 0);

  type float_t is record
    sign: unsigned(0 downto 0);
    expt: unsigned(7 downto 0);
    frac: unsigned(22 downto 0);
  end record;

  function float(v: fpu_data_t) return float_t;
  function fpu_data(v: float_t) return fpu_data_t;


  type float_type_t is (
    PLUS_ZERO,
    MINUS_ZERO,
    FORMAL,
    INFORMAL,
    PLUS_INF,
    MINUS_INF,
    NAN);

  constant VAL_NAN: fpu_data_t := x"7fffffff";
  constant VAL_MINUS_NAN: fpu_data_t := x"ffc00000";
  constant VAL_PLUS_ZERO: fpu_data_t := x"00000000";
  constant VAL_MINUS_ZERO: fpu_data_t := x"80000000";
  constant VAL_PLUS_INF: fpu_data_t := x"7f800000";
  constant VAL_MINUS_INF: fpu_data_t := x"ff800000";

  function float_type(f: float_t) return float_type_t;

  function is_metavalue(v: std_logic_vector) return boolean;
  function is_metavalue(v: unsigned) return boolean;

  function leading_zero_negative (a : unsigned(30 downto 0)) return integer;
  function leading_zero (a : unsigned(25 downto 0)) return integer;
  function under_nbit (a : unsigned(30 downto 0); n : integer range 0 to 31) return unsigned;
  function or_nbit (a : unsigned(24 downto 0); n : integer range 0 to 25) return integer;
  function round_even_26bit(n: unsigned(25 downto 0)) return unsigned;
  function round_even_carry_26bit(num : unsigned(25 downto 0)) return unsigned;


end package;

package body fpu_common_p is

  function float(v: fpu_data_t)
    return float_t is
    variable f: float_t;
  begin

    f.sign := v(31 downto 31);
    f.expt := v(30 downto 23);
    f.frac := v(22 downto 0);

    return f;

  end function;

  function fpu_data(v: float_t)
    return fpu_data_t is
  begin

    return v.sign & v.expt & v.frac;

  end function;

  function float_type(f: float_t)
    return float_type_t is
  begin

    if f.expt = 0 and f.frac = 0 then
      if f.sign = 0 then
        return PLUS_ZERO;
      else
        return MINUS_ZERO;
      end if;
    elsif f.expt = 0 then
      return INFORMAL;
    elsif f.expt = 255 and f.frac = 0 then
      if f.sign = 0 then
        return PLUS_INF;
      else
        return MINUS_INF;
      end if;
    elsif f.expt = 255 then
      return NAN;
    else
      return FORMAL;
    end if;

  end function;

  function is_metavalue(v: std_logic_vector)
    return boolean is
  begin

    for i in v'range loop
      if v(i) /= '0' and v(i) /= '1' then
        return true;
      end if;
    end loop;

    return false;

  end function;

  function is_metavalue(v: unsigned)
    return boolean is
  begin
    return is_metavalue(std_logic_vector(v));
  end function;

  function leading_zero_negative (
    a : unsigned(30 downto 0))
    return integer is
  begin

    if a(30) = '1' then return 30;
    elsif a(29) = '1' then return 29;
    elsif a(28) = '1' then return 28;
    elsif a(27) = '1' then return 27;
    elsif a(26) = '1' then return 26;
    elsif a(25) = '1' then return 25;
    elsif a(24) = '1' then return 24;
    elsif a(23) = '1' then return 23;
    elsif a(22) = '1' then return 22;
    elsif a(21) = '1' then return 21;
    elsif a(20) = '1' then return 20;
    elsif a(19) = '1' then return 19;
    elsif a(18) = '1' then return 18;
    elsif a(17) = '1' then return 17;
    elsif a(16) = '1' then return 16;
    elsif a(15) = '1' then return 15;
    elsif a(14) = '1' then return 14;
    elsif a(13) = '1' then return 13;
    elsif a(12) = '1' then return 12;
    elsif a(11) = '1' then return 11;
    elsif a(10) = '1' then return 10;
    elsif a(9) = '1' then return 9;
    elsif a(8) = '1' then return 8;
    elsif a(7) = '1' then return 7;
    elsif a(6) = '1' then return 6;
    elsif a(5) = '1' then return 5;
    elsif a(4) = '1' then return 4;
    elsif a(3) = '1' then return 3;
    elsif a(2) = '1' then return 2;
    elsif a(1) = '1' then return 1;
    elsif a(0) = '1' then return 0;
    else return 0; end if;

  end function;

  function leading_zero (
    a : unsigned(25 downto 0))
    return integer is
  begin

    if    a(25) = '1' then return 0;
    elsif a(24) = '1' then return 1;
    elsif a(23) = '1' then return 2;
    elsif a(22) = '1' then return 3;
    elsif a(21) = '1' then return 4;
    elsif a(20) = '1' then return 5;
    elsif a(19) = '1' then return 6;
    elsif a(18) = '1' then return 7;
    elsif a(17) = '1' then return 8;
    elsif a(16) = '1' then return 9;
    elsif a(15) = '1' then return 10;
    elsif a(14) = '1' then return 11;
    elsif a(13) = '1' then return 12;
    elsif a(12) = '1' then return 13;
    elsif a(11) = '1' then return 14;
    elsif a(10) = '1' then return 15;
    elsif a(9)  = '1' then return 16;
    elsif a(8)  = '1' then return 17;
    elsif a(7)  = '1' then return 18;
    elsif a(6)  = '1' then return 19;
    elsif a(5)  = '1' then return 20;
    elsif a(4)  = '1' then return 21;
    elsif a(3)  = '1' then return 22;
    elsif a(2)  = '1' then return 23;
    elsif a(1)  = '1' then return 24;
    elsif a(0)  = '1' then return 25;
    else  return 26;  end if;

  end function;

  function under_nbit (
    a : unsigned(30 downto 0);
    n : integer range 0 to 31)
    return unsigned is
  begin

    case n is
      when 0  => return to_unsigned(0, 30);
      when 1  => return resize(a(0 downto 0), 30);
      when 2  => return resize(a(1 downto 0), 30);
      when 3  => return resize(a(2 downto 0), 30);
      when 4  => return resize(a(3 downto 0), 30);
      when 5  => return resize(a(4 downto 0), 30);
      when 6  => return resize(a(5 downto 0), 30);
      when 7  => return resize(a(6 downto 0), 30);
      when 8  => return resize(a(7 downto 0), 30);
      when 9  => return resize(a(8 downto 0), 30);
      when 10 => return resize(a(9 downto 0), 30);
      when 11 => return resize(a(10 downto 0), 30);
      when 12 => return resize(a(11 downto 0), 30);
      when 13 => return resize(a(12 downto 0), 30);
      when 14 => return resize(a(13 downto 0), 30);
      when 15 => return resize(a(14 downto 0), 30);
      when 16 => return resize(a(15 downto 0), 30);
      when 17 => return resize(a(16 downto 0), 30);
      when 18 => return resize(a(17 downto 0), 30);
      when 19 => return resize(a(18 downto 0), 30);
      when 20 => return resize(a(19 downto 0), 30);
      when 21 => return resize(a(20 downto 0), 30);
      when 22 => return resize(a(21 downto 0), 30);
      when 23 => return resize(a(22 downto 0), 30);
      when 24 => return resize(a(23 downto 0), 30);
      when 25 => return resize(a(24 downto 0), 30);
      when 26 => return resize(a(25 downto 0), 30);
      when 27 => return resize(a(26 downto 0), 30);
      when 28 => return resize(a(27 downto 0), 30);
      when 29 => return resize(a(28 downto 0), 30);
      when 30 => return resize(a(29 downto 0), 30);
      when 31 => return a;
    end case;

  end function under_nbit;


  function or_nbit (
    a : unsigned(24 downto 0);
    n : integer range 0 to 25)
    return integer is
    variable cond : boolean;
  begin

    case n is
      when 0  => cond := true;
      when 1  => cond := a(0 downto 0) = 0;
      when 2  => cond := a(1 downto 0) = 0;
      when 3  => cond := a(2 downto 0) = 0;
      when 4  => cond := a(3 downto 0) = 0;
      when 5  => cond := a(4 downto 0) = 0;
      when 6  => cond := a(5 downto 0) = 0;
      when 7  => cond := a(6 downto 0) = 0;
      when 8  => cond := a(7 downto 0) = 0;
      when 9  => cond := a(8 downto 0) = 0;
      when 10 => cond := a(9 downto 0) = 0;
      when 11 => cond := a(10 downto 0) = 0;
      when 12 => cond := a(11 downto 0) = 0;
      when 13 => cond := a(12 downto 0) = 0;
      when 14 => cond := a(13 downto 0) = 0;
      when 15 => cond := a(14 downto 0) = 0;
      when 16 => cond := a(15 downto 0) = 0;
      when 17 => cond := a(16 downto 0) = 0;
      when 18 => cond := a(17 downto 0) = 0;
      when 19 => cond := a(18 downto 0) = 0;
      when 20 => cond := a(19 downto 0) = 0;
      when 21 => cond := a(20 downto 0) = 0;
      when 22 => cond := a(21 downto 0) = 0;
      when 23 => cond := a(22 downto 0) = 0;
      when 24 => cond := a(23 downto 0) = 0;
      when 25 => cond := a(24 downto 0) = 0;
    end case;

    if cond then return 0; else return 1; end if;

  end function or_nbit;

  function round_even_26bit(n: unsigned(25 downto 0))
    return unsigned is
    variable right4: unsigned(3 downto 0);
  begin

    right4 := n(3 downto 0);

    if (4 < right4 and right4 < 8) or 11 < right4 then
      return n(25 downto 3) + 1;
    else
      return n(25 downto 3);
    end if;

  end function;

  function round_even_carry_26bit(num: unsigned(25 downto 0))
    return unsigned is
  begin
    if x"3fffffc" <= num and num <= x"3ffffff" then
      return "1";
    else
      return "0";
    end if;
  end function;

end package body;
