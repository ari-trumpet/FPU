library IEEE;
use IEEE.std_logic_1164.all;

package fadd_p is

  component fadd is
    port (
      a, b : in std_logic_vector(31 downto 0);
      s    : out std_logic_vector(31 downto 0));
  end component;

end package;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity fadd is
  Port ( A,B : in std_logic_vector(31 downto 0);
         S   : out std_logic_vector(31 downto 0));
end entity fadd;

architecture blackbox of FADD is

  -- round_even : 26bit -> 23bit
  function round_even(num: std_logic_vector(25 downto 0))
    return std_logic_vector
  is
    variable result : std_logic_vector(22 downto 0);
  begin
    if (4 < num(3 downto 0) and num(3 downto 0) < 8) or 11 < num(3 downto 0) then  --一考
      result := num(25 downto 3) + 1;
    else
      result := num(25 downto 3);
    end if;
    return result;
  end round_even;

  -- round_even_carry : 26bit -> 1bit
  function round_even_carry(num: std_logic_vector(25 downto 0))
    return std_logic
  is
    variable carry : std_logic;
  begin
    -- bigger than "11 1111 1111 1111 1111 1111 1011" or not?
    if num(25 downto 0) > x"3fffffb" then
      carry := '1';
    else
      carry := '0';
    end if;
    return carry;
  end round_even_carry;

  function do_fadd(a: std_logic_vector(31 downto 0); b: std_logic_vector(31 downto 0))
    return std_logic_vector
  is

  constant nan : std_logic_vector(31 downto 0) :=
    "01111111111111111111111111111111";
  constant zero : std_logic_vector(31 downto 0) :=
    "00000000000000000000000000000000";
  constant nzero : std_logic_vector(31 downto 0) :=
    "10000000000000000000000000000000";
  constant inf : std_logic_vector(31 downto 0) :=
    "01111111100000000000000000000000";
  constant ninf : std_logic_vector(31 downto 0) :=
    "11111111100000000000000000000000";

  variable exp_a, exp_b : std_logic_vector(7 downto 0);
  variable num1, num2 : std_logic_vector(31 downto 0);
  variable sign1, sign2 : std_logic;
  variable exp1, exp2 : std_logic_vector(7 downto 0);
  variable frac1, frac2 : std_logic_vector(22 downto 0);
  variable sum : std_logic_vector(31 downto 0);
  variable diff : std_logic_vector(7 downto 0) := (others => '0');
  variable mant1, mant2 : std_logic_vector(26 downto 0);
  variable sum_exp : std_logic_vector(7 downto 0);
  variable sum_frac25 : std_logic_vector(24 downto 0);
  variable sum_mant : std_logic_vector(27 downto 0);
  variable i : std_logic_vector(7 downto 0) := (others => '0');    --
  variable nflag : std_logic := '0';  --（減算時）expが負になったら'1'
  variable s_bit : std_logic; -- sticky bit
  variable carry : std_logic; -- round even carry
  variable temp  : std_logic_vector(25 downto 0); -- round_evenに渡すときに使用

  begin

  if a(30 downto 0) > b(30 downto 0) then
    num1 := a;
    num2 := b;
  else
    num1 := b;
    num2 := a;
  end if;

  sign1 := num1(31);
  sign2 := num2(31);
  exp1  := num1(30 downto 23);
  exp2  := num2(30 downto 23);
  frac1 := num1(22 downto 0);
  frac2 := num2(22 downto 0);

  if (a(30 downto 23) = "11111111") and (a(22 downto 0) > 0) then
    sum := nan;
  elsif (b(30 downto 23) = "11111111") and (b(22 downto 0) > 0) then
    sum := nan;
  elsif (a = inf and b = ninf) or (a = ninf and b = inf) then
    sum := nan;
  elsif a = inf or b = inf then
    sum := inf;
  elsif a = ninf or b = ninf then
    sum := ninf;
  elsif a(30 downto 23) = 0 then
    if b(30 downto 23) = 0 then
      if a(31) = '1' and b(31) = '1' then
        sum := nzero;
      else
        sum := zero;
      end if;
    else
      sum := b;
    end if;
  elsif b(30 downto 23) = 0 then
    sum := a;
  --elsif a = zero or a = nzero then
  --  if a = nzero and b = nzero then
  --    sum := nzero;
  --  elsif b = zero or b = nzero then
  --    sum := zero;
  --  else
  --    sum := b;
  --  end if;
  --elsif a(30 downto 23) = "00000000" then
  --  sum := b;
  --elsif b(30 downto 23) = "00000000" then
  --  sum := a;
  else
    diff := exp1 - exp2;
    if diff > 25 then             -- 整数と比較可能？
      sum := num1;

    else
      mant1 := '1' & frac1 & "000";
      mant2 := "0001" & frac2;
      if (diff < 4) then
        mant2 := std_logic_vector(shift_left(unsigned(mant2), (3 - conv_integer(diff))));
      else

        if mant2((conv_integer(diff) - 3) downto 0) > 0 then
          s_bit := '1';  -- sticky bit
        else
          s_bit := '0';
        end if;
        mant2 := std_logic_vector(shift_right(unsigned(mant2), (conv_integer(diff) - 2)));
        mant2 := mant2(25 downto 0) & s_bit;
      end if;

      if sign1 = sign2 then       -- 同符号の場合（加算）
        sum_mant := ('0' & mant1) + ('0' & mant2);
        if (exp1 = 254) and (sum_mant(27) = '1') then
          if sign1 = '0' then
            sum := inf;
          else
            sum := ninf;
          end if;
        else
          if sum_mant(27) = '1' then -- 繰り上がりあり
            sum(31)           := sign1;
            sum(30 downto 23) := exp1 + 1;
            s_bit             := sum_mant(1) or sum_mant(0);
            sum(22 downto 0)  := round_even(sum_mant(26 downto 2) & s_bit);
            carry := round_even_carry(sum_mant(26 downto 2) & s_bit);
          else                          -- 繰り上がりなし
            sum(31)           := sign1;
            sum(30 downto 23) := exp1;
            sum(22 downto 0)  := round_even(sum_mant(25 downto 0));
            carry := round_even_carry(sum_mant(25 downto 0));
          end if;
          if carry = '1' then
            if sum(30 downto 23) = 255 then
              if sign1 = '0' then
                sum := inf;
              else
                sum := ninf;
              end if;
            else
              sum(30 downto 23) := sum(30 downto 23) + 1;
            end if;
          end if;
        end if;
      else                          -- 異符号の場合（減算）
        if num1(30 downto 0) = num2(30 downto 0) then
          sum := zero;
        else
          sum(31) := sign1;
          sum_mant := ('0' & mant1) - ('0' & mant2);

          while i < 28 and sum_mant(27 - conv_integer(i)) = '0' loop    -- i > 0
            i := i + 1;
          end loop;
          -- i = 28 ならばここまで辿りつかないはず（i=28のとき完全に一致）
          -- i > 0 であるはず。

          -- nflag 不要？

          if i < 28 then
            if exp1 > i - 1 then
              sum(30 downto 23) := exp1 + 1 - i;
              if i < 4 then
                if i = 0 then
                  s_bit := sum_mant(1) or sum_mant(0);
                  temp(25 downto 0) := sum_mant(26 downto 2) & s_bit;
                elsif i = 1 then
                  temp(25 downto 0) := sum_mant(25 downto 0);
                elsif i = 2 then
                  temp(25 downto 0) := sum_mant(24 downto 0) & '0';
                else -- i = 3
                  temp(25 downto 0) := sum_mant(23 downto 0) & "00";
                end if;
                sum(22 downto 0) := round_even(temp);
              else
                sum(22 downto 0) := sum_mant(22 downto 0);
                sum(22 downto 0) := std_logic_vector(shift_left(unsigned(sum(22 downto 0)), (conv_integer(i) - 4)));
              end if;
            else
              if sign1 = '0' then
                sum := zero;
              else
                sum := nzero;
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end if;

  return sum;
  end do_fadd;

begin

  S <= do_fadd(A, B);
end blackbox;
