library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.fpu_common_p.all;

entity fadd_pl is
    port (
        clk : in std_logic;
        a   : in  std_logic_vector(31 downto 0);
        b   : in  std_logic_vector(31 downto 0);
        s   : out std_logic_vector(31 downto 0));
end fadd_pl;

architecture blackbox of fadd_pl is

  subtype expint is integer range 0 to 255;

  function round_even_26bit(n: unsigned(25 downto 0))
    return unsigned is
    
  function round_even_carry_26bit(num: unsigned(25 downto 0))
    return unsigned is
    
  constant nan   : std_logic_vector(31 downto 0) := x"7fffffff";
  constant zero  : std_logic_vector(31 downto 0) := x"00000000";
  constant inf   : std_logic_vector(31 downto 0) := x"7f800000";
  constant ninf  : std_logic_vector(31 downto 0) := x"ff800000";
  
  signal s0_nan          : std_logic := '0';
  signal s0_inf          : std_logic := '0';
  signal s0_ninf         : std_logic := '0';
  signal s0_zero         : std_logic := '0';
  signal s0_mant1        : unsigned(26 downto 0) := (others => '0');
  signal s0_mant2        : unsigned(26 downto 0) := (others => '0');
  signal s0_sgn          : std_logic := '0';
  signal s0_exp          : unsigned(7 downto 0) := (others => '0');
  signal s0_porm         : std_logic := '0';

  signal s1_nan          : std_logic := '0';
  signal s1_inf          : std_logic := '0';
  signal s1_ninf         : std_logic := '0';
  signal s1_zero         : std_logic := '0';
  signal s1_over         : std_logic := '0';
  signal s1_mant1        : unsigned(26 downto 0) := (others => '0');
  signal s1_mant2        : unsigned(26 downto 0) := (others => '0');
  signal s1_sgn          : std_logic := '0';
  signal s1_exp          : unsigned(7 downto 0) := (others => '0');
  signal s1_porm         : std_logic := '0';
  



begin


    seq00 : process(a,b)
      variable input_1, input_2 : unsigned(31 downto 0);
      variable expdiff : expint;
      variable s0_mant2buff  : unsigned(26 downto 0);
      variable mant2         : unsigned(26 downto 0);
      variable s_bit         : std_logic;
    begin          
      if a(30 downto 0) > b(30 downto 0) then
        input_1 := unsigned(a);
        input_2 := unsigned(b);
      else
        input_1 := unsigned(b);
        input_2 := unsigned(a);
      end if;
    

      if     input_1(30 downto 23) = x"ff" and input_1(22 downto 0) /= 0 then
        s0_nan <= '1';
      elsif  input_2(30 downto 23) = x"ff" and input_2(22 downto 0) /= 0 then
        s0_nan <= '1';
      elsif   input_1(31 downto 23) = '0' & x"ff" and input_2(31 downto 23) = '1' & x"ff" then
        s0_nan <= '1';
      elsif  input_1(31 downto 23) = '1' & x"ff" and input_2(31 downto 23) = '0' & x"ff" then
        s0_nan <= '1';
      else
        s0_nan <= '0';
      end if; 
    
      if     input_1(31 downto 23) = '0' & x"ff" or input_2(31 downto 23) = '0' & x"ff" then
        s0_inf <= '1';
      else
        s0_inf <= '0';
      end if;
      
      if     input_1(31 downto 23) = '1' & x"ff" or input_2(31 downto 23) = '1' & x"ff" then
        s0_ninf <= '1';
      else
        s0_ninf <= '0';
      end if;
      
      if     input_1(30 downto 23) = x"00" and input_2(30 downto 23) = x"00" then
        s0_zero  <= '1';
      else
        s0_zero  <= '0';
      end if;
            
      expdiff := TO_INTEGER(input_1(30 downto 23)) - TO_INTEGER(input_2(30 downto 23));
      
      if expdiff > 26 then
        s0_mant2buff := "000" & x"000000";
      else
        mant2 := "0001" & input_2(22 downto 0);
        if (diff < 4) then
          s0_mant2buff := shift_left(mant2, (3 - expdiff));
        else
          if mant2((expdiff - 3) downto 0) > 0 then
            s_bit := '1';  -- sticky bit
          else
            s_bit := '0';
          end if;
          mant2 := shift_right(mant2, expdiff - 2);
          s0_mant2buff := mant2(25 downto 0) & s_bit;
        end if;
      end if;

      s0_sgn <= input_1(31);
      s0_exp <= input_1(30 downto 23);
      s0_porm <= input_1(31) xor input_2(31);  -- 演算種判定ビット          
      s0_mant1 <= '1' & input_1(22 downto 0) & "000";
      s0_mant2 <= s0_mant2buff;
    end process;
    
  latch1 : process(clk)
    begin
      if rising_edge(clk) then 
        s1_nan   <= s0_nan;
        s1_inf   <= s0_inf;
        s1_ninf  <= s0_ninf;
        s1_zero  <= s0_zero;
        s1_mant1 <= s0_mant1;
        s1_mant2 <= s0_mant2;
        s1_sgn   <= s0_sgn;
        s1_exp   <= s0_exp;
        s1_porm  <= s0_porm;
      end if;
  end process;
    
  seq1 : process(s1_nan, s1_inf, s1_ninf, s1_zero, s1_mant1, s1_mant2, s1_sgn, s1_exp, s1_porm)
      variable sum_mant : unsigned(27 downto 0);
      variable carry    : std_logic;
      variable sumexp   : unsigned(7 downto 0);
      variable sumfrac  : unsigned(22 downto 0);
      variable i        : integer range 0 to 30;
      variable temp     : unsigned(25 downto 0);
    begin
    
    if s1_porm = '0' then -------------------------------------------------------- 加算
      sum_mant := ('0' & s1_mant1) + ('0' & s1_mant2);
      if s1_exp = 254 and sum_mant(27) = '1' then  ------------- inf
        if s1_sgn = '0' then
          sum := zero;
        else
          sum := nzero;
        end if;        
      else
        if sum_mant(27) = '1' then                     ------------- 桁上がり
          sumexp := s1_exp + 1;
          s_bit  := sum_mant(1) or sum_mant(0);
          sumfrac(22 downto 0)  := round_even_26bit(sum_mant(26 downto 2) & s_bit);
          carry := round_even_carry_26bit(sum_mant(26 downto 2) & s_bit);
        else                                            ------------ 繰り上がりなし
          sumexp := s1_exp;
          sumfrac(22 downto 0)  := round_even_26bit(sum_mant(25 downto 0));
          carry := round_even_carry_26bit(sum_mant(25 downto 0));
        end if;
         
        if carry = '1' then                            ------------- キャリー処理
          if sumexp >= 254 then
            sumexp  := x"ff";    
            sumfrac := "000" & x"00000";
          else
            sumexp  := sumexp + 1;
            sumfrac := '0' & sumfrac(22 downto 1);    ----------------------------------- ??
          end if;
        end if;
        sum := s1_sgn & sumeexp(7 downto 0) & sumfrac(22 downto 0);
      end if;
    else ------------------------------------------------------------------------- 減算
      if s1_mant1 = s1_mant2 then
        sum := zero;
      else
        sum_mant := ('0' & s1_mant1) - ('0' & s1_mant2);              ----- 必ず s1_mant >= s1_mant2
        
        i := 26 - leading_zero_negative("000" & sum_mant);

        if i < 27 then
          if s1_exp > i then
            sumexp := s1_exp1 - i;
            if i = 0 then
              s_bit := sum_mant(1) or sum_mant(0);
              temp(25 downto 0) := sum_mant(26 downto 2) & s_bit;
            else
              shifttemp(27 downto 0) := shift_left(sum_mant, i);    
              temp(25 downto 0) := shifttemp(26 downto 1);
            end if;
            sumfrac(22 downto 0) := round_even_26bit(temp);
            carry := round_even_26bit(temp);
            if carry = '1' then                            ------------- キャリー処理
              if sumexp >= 254 then
                sumexp  := x"ff";    
                sumfrac := "000" & x"00000";
              else
                sumexp  := sumexp + 1;
                sumfrac := '0' & sumfrac(22 downto 1);    ----------------------------------- ??
              end if;
            end if;
            sum := s1_sgn & sumeexp(7 downto 0) & sumfrac(22 downto 0);            
          else
            sum <= zero;
          end if;
        end if;
      end if;
    end if;

    if s1_nan = '1' then
      s <= nan;
    elsif s1_inf = '1' then
      s <= inf;
    elsif s1_ninf = '1' then
      s <= ninf;
    elsif s1_zero = '1' then
      s <= zero;
    else
      s <= sum;
    end if;
  end process;
