library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpu_common_p.all;

entity fmul_pipeline is
  port( clk : in std_logic;
        in1 : in std_logic_vector(31 downto 0);
        in2 : in std_logic_vector(31 downto 0);
        ans : out std_logic_vector(31 downto 0));
end fmul_pipeline;

architecture fmul_blackbox of fmul_pipeline is

  type cornercase is (nan, inf ,ninf, zero, normal);
  type result     is (ok, overflow, underflow);
  
  function ifnan(input : std_logic_vector(31 downto 0))
    return boolean
  is
  begin
    if input(30 downto 23) = x"ff" and unsigned(input(22 downto 0)) /= 0 then
      return TRUE;
    else
      return FALSE;
    end if;
  end ifnan;
  
  function ifinf(input : std_logic_vector(31 downto 0))
    return boolean
  is
  begin
    if input(30 downto 23) = x"ff" and unsigned(input(22 downto 0)) = 0 then
      return TRUE;
    else
      return FALSE;
    end if;
  end ifinf;

  function ifzero(input : std_logic_vector(31 downto 0))
    return boolean
  is
  begin
    if input(30 downto 23) = x"00" then
      return TRUE;
    else
      return FALSE;
    end if;
  end ifzero;
  
  constant nan32          : std_logic_vector(31 downto 0) := x"7fffffff";
  constant inf32          : std_logic_vector(31 downto 0) := x"7f800000";
  constant ninf32         : std_logic_vector(31 downto 0) := x"ff800000";
  constant zero32         : std_logic_vector(31 downto 0) := x"00000000";
  
  constant fraction_roundup: std_logic_vector(25 downto 0) := (25 => '0', others => '1');
  
  alias    in1_sgn         : std_logic is in1(31);
  alias    in1_exp         : std_logic_vector(7 downto 0) is in1(30 downto 23);
  alias    in1_h           : std_logic_vector(12 downto 0) is in1(22 downto 10);
  alias    in1_l           : std_logic_vector(9 downto 0) is in1(9 downto 0);

  alias    in2_sgn         : std_logic is in2(31);
  alias    in2_exp         : std_logic_vector(7 downto 0) is in2(30 downto 23);
  alias    in2_h           : std_logic_vector(12 downto 0) is in2(22 downto 10);
  alias    in2_l           : std_logic_vector(9 downto 0) is in2(9 downto 0);
  
  alias    ans_sgn         : std_logic is ans(31);
  alias    ans_exp         : std_logic_vector(7 downto 0) is ans(30 downto 23);
  alias    ans_frac        : std_logic_vector(22 downto 0) is ans(22 downto 0);
  
  signal   s0_corner       : cornercase := normal;
  signal   s0_sgn          : std_logic := '0';
  signal   s0_exp          : std_logic_vector(8 downto 0) := (others => '0');
  signal   s0_hh           : std_logic_vector(27 downto 0) := (others => '0');
  signal   s0_hl           : std_logic_vector(23 downto 0) := (others => '0');    
  signal   s0_lh           : std_logic_vector(23 downto 0) := (others => '0');
  
  signal   s1_corner       : cornercase := normal;
  signal   s1_sgn          : std_logic := '0';
  signal   s1_exp          : std_logic_vector(8 downto 0) := (others => '0');
  signal   s1_hh           : std_logic_vector(27 downto 0) := (others => '0');
  signal   s1_hl           : std_logic_vector(23 downto 0) := (others => '0');    
  signal   s1_lh           : std_logic_vector(23 downto 0) := (others => '0');
  
  signal   s2_corner       : cornercase := normal;
  signal   s2_sgn          : std_logic := '0';
  signal   s2_exp          : std_logic_vector(7 downto 0) := (others => '0');
  signal   s2_frac         : std_logic_vector(27 downto 0) := (others => '0');
  signal   s2_result       : result := ok;

  signal   s3_corner       : cornercase := normal;
  signal   s3_sgn          : std_logic := '0';
  signal   s3_exp          : std_logic_vector(7 downto 0) := (others => '0');
  signal   s3_frac         : std_logic_vector(27 downto 0) := (others => '0');
  signal   s3_result       : result := ok;
  
begin
  seq0 : process(in1, in2)
    variable corner   : cornercase;
  begin
    corner := nan;
    if ifnan(in1) or ifnan(in2) then
      corner := nan;
    elsif ifinf(in1) and ifzero(in2) then  
      corner := nan;
    elsif ifzero(in1) and ifinf(in2) then
      corner := nan;
    elsif ifinf(in1) or ifinf(in2) then
      if in1_sgn = in2_sgn then
        corner := inf;
      else
        corner := ninf;
      end if;
    elsif ifzero(in1) or ifzero(in2) then
      corner := zero;
    else
      corner := normal;
    end if;
    
    s0_corner           <= corner;
    s0_sgn              <= in1_sgn xor in2_sgn;
    s0_exp(8 downto 0) <= std_logic_vector(unsigned('0' & in1_exp) + unsigned('0' & in2_exp));
    s0_hh      <= std_logic_vector(unsigned('1' & in1_h) * unsigned('1' & in2_h));
    s0_hl      <= std_logic_vector(unsigned('1' & in1_h) * unsigned(in2_l));
    s0_lh      <= std_logic_vector(unsigned(in1_l) * unsigned('1' & in2_h));
  end process;
  
  latch1 : process(clk)
  begin
   if rising_edge(clk) then
    s1_corner             <= s0_corner;
    s1_sgn                <= s0_sgn;
    s1_exp(8 downto 0)   <= s0_exp(8 downto 0);
    s1_hh(27 downto 0)   <= s0_hh(27 downto 0);
    s1_hl(23 downto 0)   <= s0_hl(23 downto 0);
    s1_lh(23 downto 0)   <= s0_lh(23 downto 0);
   end if;
  end process;
  
  seq1 : process(s1_corner, s1_sgn, s1_exp, s1_hh, s1_hl, s1_lh)
    variable hh2  : std_logic_vector(27 downto 0);
    variable hllh : std_logic_vector(14 downto 0);
    variable frac : std_logic_vector(27 downto 0);
    variable exp  : std_logic_vector(8 downto 0);
    variable exp8 : std_logic_vector(8 downto 0);
  begin
    hh2  := (others => '0');
    hllh := (others => '0');
    frac := (others => '0');
    exp  := (others => '0');
    exp8 := (others => '0');
    
    hh2  := std_logic_vector(unsigned(s1_hh) + 2);
    hllh := std_logic_vector(unsigned('0' & s1_hl(23 downto 10)) + unsigned('0' & s1_lh(23 downto 10)));
    frac := std_logic_vector(unsigned(hh2) + unsigned("0000000000000" & hllh));    
    s2_frac <= frac;

    if frac(27) = '1' then
      exp := std_logic_vector(unsigned(s1_exp) + 1);
    else
      exp := std_logic_vector(unsigned(s1_exp));
    end if;
    if unsigned(exp) < 128 then
      s2_result <= underflow;
      s2_exp    <= (others => '0');
    elsif unsigned(exp) > 381 then
      s2_result <= overflow;
      s2_exp    <= (others => '0');
    else
      s2_result <= ok;
      exp8 := std_logic_vector(unsigned(exp) - 127);
      s2_exp    <= exp8(7 downto 0);
    end if;
     
    s2_corner <= s1_corner;
    s2_sgn    <= s1_sgn; 
      
   end process;
   
   latch2 : process(clk)
   begin 
    if rising_edge(clk) then
     s3_corner            <= s2_corner;
     s3_result            <= s2_result;
     s3_sgn               <= s2_sgn;
     s3_exp(7 downto 0)  <= s2_exp(7 downto 0);
     s3_frac(27 downto 0) <= s2_frac(27 downto 0);
    end if;
   end process;
   
   seq2 : process(s3_corner, s3_result, s3_sgn, s3_exp, s3_frac)
   begin
   
   case s3_corner is
    when nan    =>
      ans  <= nan32;
    --  cor  <= "111";
    when inf    =>
      ans  <= inf32;
    --  cor  <= "110";
    when ninf   =>
      ans  <= ninf32;
    --  cor  <= "101";
    when zero   =>
      ans  <= zero32;
    --  cor  <= "100";
    when normal => 
    --  cor  <= "000";  
      case s3_result is
        when underflow =>
          ans_sgn  <= '0';
          ans_exp  <= (others => '0');
          ans_frac <= (others => '0');
        when overflow =>
          ans_sgn  <= s3_sgn;
          ans_exp  <= (others => '1');
          ans_frac <= (others => '0');
        when ok =>
          ans_sgn <= s3_sgn;
          ans_exp <= s3_exp;

          if s3_frac(27) = '1' then      -- 繰り上がりあり
           ans_frac <= std_logic_vector(round_even_26bit(unsigned(s3_frac(26 downto 1))));
          else
           ans_frac <= std_logic_vector(round_even_26bit(unsigned(s3_frac(25 downto 0))));
          end if;
      end case;
   end case;
   
   end process;
   
end fmul_blackbox;
