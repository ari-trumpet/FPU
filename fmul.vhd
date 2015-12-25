library IEEE;
use IEEE.std_logic_1164.all;

--package fmul_p is

--  component fmul is
--    port (
--      a, b : in std_logic_vector(31 downto 0);
--      s    : out std_logic_vector(31 downto 0));
--  end component;

--end package;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity fmul is
  Port(A,B : in  std_logic_vector(31 downto 0);
       S   : out std_logic_vector(31 downto 0));
end entity fmul;

architecture blackbox of FMUL is

  -- round_even : 26bit -> 23bit
  function round_even(num: std_logic_vector(25 downto 0))
    return std_logic_vector
  is
    variable result : std_logic_vector(22 downto 0);
  begin
    if (4 < num(3 downto 0) and num(3 downto 0) < 8) or (11 < num(3 downto 0)) then  --一考
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
    -- "11 1111 1111 1111 1111 1111 1011"より大きいかどうか
    if num(25 downto 0) > x"3fffffb" then
      carry := '1';
    else
      carry := '0';
    end if;
    return carry;
  end round_even_carry;

  function do_fmul(a: std_logic_vector(31 downto 0); b: std_logic_vector(31 downto 0))
    return std_logic_vector
  is
    constant nan   : std_logic_vector(31 downto 0) := x"7fffffff";
    constant zero  : std_logic_vector(31 downto 0) := x"00000000";
    constant nzero : std_logic_vector(31 downto 0) := x"80000000";
    constant inf   : std_logic_vector(31 downto 0) := x"7f800000";
    constant ninf  : std_logic_vector(31 downto 0) := x"ff800000";
    
    variable result : std_logic_vector(31 downto 0);
    variable a_exp  : std_logic_vector(8 downto 0);  -- 1bit余分に。
    variable b_exp  : std_logic_vector(8 downto 0);
    variable exp    : std_logic_vector(8 downto 0);
    variable a_hmant : std_logic_vector(13 downto 0);
    variable b_hmant : std_logic_vector(13 downto 0);
    variable a_lmant : std_logic_vector(13 downto 0); -- 14bit。0詰め必要。
    variable b_lmant : std_logic_vector(13 downto 0);
    variable product : std_logic_vector(27 downto 0);
    variable ah_bh   : std_logic_vector(27 downto 0);
    variable ah_bl   : std_logic_vector(27 downto 0);
    variable al_bh   : std_logic_vector(27 downto 0);
    variable s_bit   : std_logic;
    variable mant    : std_logic_vector(25 downto 0);
  begin 
    if (a(30 downto 23) = 255 and a(22 downto 0) /= 0) or
       (b(30 downto 23) = 255 and b(22 downto 0) /= 0) then
      result := nan;
    elsif (a(30 downto 23) = 255 and b(30 downto 23) = 0) or
          (a(30 downto 23) = 0 and b(30 downto 23) = 255) then
      result := nan;
    elsif a(30 downto 23) = 255 or b(30 downto 23) = 255 then
      if a(31) = b(31) then
        result := inf;
      else
        result := ninf;
      end if;
    elsif a(30 downto 23) = 0 or b(30 downto 23) = 0 then
      if a(31) = b(31) then
        result := zero;
      else
        result := nzero;
      end if;
    else
      result(31) := a(31) xor b(31);
      a_exp := '0' & a(30 downto 23);
      b_exp := '0' & b(30 downto 23);
      exp   := a_exp + b_exp; -- -127が必要だが0未満になると困るので後で。

      a_hmant := '1' & a(22 downto 10);
      b_hmant := '1' & b(22 downto 10);
      a_lmant := "0000" & a(9 downto 0);
      b_lmant := "0000" & b(9 downto 0);
      ah_bh := a_hmant * b_hmant;  -- 14bit * 14bit = 28bit
      ah_bl := a_hmant * b_lmant;
      al_bh := a_lmant * b_hmant;
      product := ah_bh
                 + std_logic_vector(shift_right(unsigned(ah_bl), 10))
                 + std_logic_vector(shift_right(unsigned(al_bh), 10));

      if product(27) = '1' then -- 繰り上がりありの場合
        s_bit := product(1) or product(0);
        mant  := product(26 downto 2) & s_bit;
        result(22 downto 0) := round_even(mant);        
        exp := exp + 1;  -- 繰り上がりの分
        if round_even_carry(mant) = '1' then
          exp := exp + 1;
        end if;
      else
        mant := product(25 downto 0);
        result(22 downto 0) := round_even(mant);
        if round_even_carry(mant) = '1' then
          exp := exp + 1;
        end if;
      end if;

      -- exp-127 が指数部に実際に使う値
      if exp > 127 then -- 指数部が正の場合
        if (conv_integer(exp) - 127) > 254 then
          if a(31) = b(31) then
            result := inf;
          else
            result := ninf;
          end if;
        else
          exp := exp - 127;
          result(30 downto 23) := exp(7 downto 0);
        end if;
      else  -- 指数部が0以下になってしまう場合
        if a(31) = b(31) then
          result := zero;
        else
          result := nzero;
        end if;
      end if;
    end if;
  return result;
  end do_fmul;

begin

  S <=  do_fmul(A, B);

end blackbox;
