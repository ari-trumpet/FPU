library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.fpu_common_p.all;

entity fmul_pl is
    port (
        clk : in std_logic;
        input_1 : in  std_logic_vector(31 downto 0);
        input_2 : in  std_logic_vector(31 downto 0);
        output : out std_logic_vector(31 downto 0));
end fmul_pl;

architecture dataflow_pipeline of fmul_pl is

    subtype ninebit is integer range 0 to 511;

 --   signal s0_sgn1, s0_sgn2, s0_sgnout   : std_logic;
    signal s0_sgnout          : std_logic := '0';     
 --   signal s0_exp1, s0_exp2   : unsigned(7 downto 0);
    signal s0_frac1, s0_frac2 : unsigned(22 downto 0) := (others => '0');
 --   signal s0_nan1, s0_nan2   : std_logic := '0';
    signal s0_inf             : std_logic := '0';
    signal s0_zero            : std_logic := '0';
    signal s0_hh              : unsigned(27 downto 0) := (others => '0');
    signal s0_hl, s0_lh       : unsigned(23 downto 0) := (others => '0');
    signal s0_nan             : std_logic := '0';
    
    signal s1_nan             : std_logic := '0';
    signal s1_inf             : std_logic := '0';
    signal s1_zero            : std_logic := '0';
    signal s1_sgnout          : std_logic := '0';
    signal s1_exp1, s1_exp2   : unsigned(7 downto 0) := (others => '0');
--    signal s1_addexp          : unsigned(8 downto 0) := "000000000";
    signal s1_hh              : unsigned(27 downto 0) := (others => '0');
    signal s1_hl, s1_lh       : unsigned(13 downto 0) := (others => '0');
    signal s1_product         : unsigned(27 downto 0) := (others => '0');
    
    signal s2_nan             : std_logic := '0';
    signal s2_inf             : std_logic := '0';
    signal s2_zero            : std_logic := '0';
    signal s2_sgnout          : std_logic := '0';
    signal s2_product         : unsigned(27 downto 0) := (others => '0');
--    signal s2_addexp          : unsigned(8 downto 0) := "000000000";

--    signal sgn                : std_logic;
--    signal exp                : unsigned(7 downto 0);
--    signal frac               : unsigned(22 downto 0);
    
--    signal exp_buff           : unsigned(8 downto 0);
    
    signal s0_zeroinf, s1_zeroinf, s2_zeroinf : std_logic := '0';
    
    signal s1_addexp          : ninebit := 0;
    signal s2_addexp          : ninebit := 0;
  --  signal exp_buff           : ninebit;
    
    signal s0_exp1signal : unsigned(7 downto 0) := (others => '0');
    signal s0_exp2signal : unsigned(7 downto 0) := (others => '0');
        
        
begin    
    latch0 : process(input_1, input_2)
      variable s0_sgn1, s0_sgn2   : std_logic;
      variable s0_exp1, s0_exp2  : unsigned(30 downto 23);
      variable s0_frac1, s0_frac2 : unsigned(22 downto 0);
      variable s0_nan1, s0_nan2   : std_logic;
      variable s0_zerobuff        : std_logic;
    begin 

            s0_sgn1  := input_1(31);
            s0_exp1  := unsigned(input_1(30 downto 23));
            s0_frac1 := unsigned(input_1(22 downto 0));
            s0_sgn2  := input_2(31);
            s0_exp2  := unsigned(input_2(30 downto 23));
            s0_frac2 := unsigned(input_2(22 downto 0));

      if    s0_exp1 = x"ff" and s0_frac1 > 0 then   -- nan * hoge の処理
        s0_nan1 := '1';
      elsif s0_exp2 = x"ff" and s0_frac2 > 0 then
        s0_nan1 := '1';
      else 
        s0_nan1 := '0';
      end if;
      
      if (s0_exp1 = x"ff") and (s0_exp2 = x"00") then   -- zero * +-inf の処理
        s0_nan2 := '1';
      elsif (s0_exp1 = x"00") and (s0_exp2 = x"ff") then
        s0_nan2 := '1';
      else
        s0_nan2 := '0';
      end if;
      
      if s0_exp1 = x"ff" then                        -- +-inf * hoge の処理
        s0_inf <= '1';
      elsif s0_exp2 = x"ff" then  -- or を取れば良い？ひげが出ないか一考
        s0_inf <= '1';
      else
        s0_inf <= '0';
      end if;
      
      if s0_exp1 = x"00" then                        -- zero * hoge の処理
        s0_zerobuff := '1';
      elsif s0_exp2 = x"00" then
        s0_zerobuff := '1';
      else
        s0_zerobuff := '0';
      end if;
      
  --    if input_1(31 downto 0) = x"00000000" and input_2(31 downto 0) = x"ffffffff" then
  --      s0_zeroinf <= '1';
  --    elsif  input_1(31 downto 0) = x"11111111" and input_2(31 downto 0) = x"00000000" then
  --      s0_zeroinf <= '1';
  --    else
  --      s0_zeroinf <= '0';
  --    end if;
                                                      -- ※これらの例外は背反事象でないので後の処理の順番に注意
      s0_sgnout  <= s0_sgn1 xor s0_sgn2;
      s0_hh      <= unsigned('1' & s0_frac1(22 downto 10)) * unsigned('1' & s0_frac2(22 downto 10));
      s0_hl      <= unsigned('1' & s0_frac1(22 downto 10)) * unsigned(s0_frac2(9 downto 0));
      s0_lh      <= unsigned(s0_frac1(9 downto 0)) * unsigned('1' & s0_frac2(22 downto 10));
      s0_nan     <= s0_nan1 or s0_nan2;
      s0_exp1signal <= s0_exp1;
      s0_exp2signal <= s0_exp2;
      s0_zero <= s0_zerobuff;
      
    end process;


    latch1 : process(clk)
    begin
        if rising_edge(clk) then
            s1_nan   <= s0_nan;
            s1_inf    <= s0_inf;
            s1_zero   <= s0_zero;
            s1_sgnout <= s0_sgnout;
   --         s1_zeroinf <= s0_zeroinf;
            s1_exp1   <= s0_exp1signal;
            s1_exp2   <= s0_exp2signal;
            s1_hh      <= s0_hh;
            s1_hl      <= s0_hl(23 downto 10);
            s1_lh      <= s0_lh(23 downto 10);
        end if;
    end process;

    seq1 : process(s1_exp1, s1_exp2, s1_hh, s1_hl, s1_lh)
    begin
      s1_product <= ((s1_hh(27 downto 0) + (x"000" & "00" & s1_hl(13 downto 0))) + (x"000" & "00" & s1_lh(13 downto 0))) + 2;  -- 怪しい
    --  s1_addexp <= unsigned("0"s1_exp1 + unsigned("0" & s1_exp2(7 downto 0));
      s1_addexp <= TO_INTEGER(s1_exp1) + TO_INTEGER(s1_exp2);
    end process;
    
    latch2 : process(clk)
    begin
      if rising_edge(clk) then
           s2_nan     <= s1_nan;
           s2_inf     <= s1_inf;
           s2_zero    <= s1_zero;
     --      s2_zeroinf <= s1_zeroinf;
           s2_sgnout  <= s1_sgnout;
           s2_addexp  <= s1_addexp;
           s2_product <= s1_product;
      end if;
    end process;
           
    seq2 : process(s2_nan, s2_inf, s2_zero, s2_sgnout, s2_product, s2_addexp)
      variable frac_buff : unsigned(22 downto 0);
--      variable exp_buff  : unsigned(8 downto 0);
      variable sgn       : std_logic;
      variable exp       : unsigned(7 downto 0);
      variable frac      : unsigned(22 downto 0);   
      variable eb        : unsigned(7 downto 0);
      variable exp_buff  : ninebit;
    begin
     if s2_nan = '1' then
       sgn  := '0';
       exp  := x"ff";
       frac := "111" & x"fffff";
     elsif s2_inf = '1' then
       sgn  := s2_sgnout;
       exp  := x"ff";
       frac := "000" & x"00000";
     elsif s2_zero = '1' then
       sgn  := '0';--s2_sgnout;
       exp  := x"00";
       frac := "000" & x"00000";
  --   elsif s2_zeroinf = '1' then
  --     sgn  := '0';
  --     exp  := x"ff";
  --     frac := "111" & x"cafe0";
     else
       sgn := s2_sgnout;
       if s2_product(27) = '1' then      -- 繰り上がりあり
         frac_buff := round_even_26bit(s2_product(26 downto 1));
         exp_buff  := s2_addexp + 1;
       else
         frac_buff := round_even_26bit(s2_product(25 downto 0));
         exp_buff  := s2_addexp;
       end if;
             
       -- exp-127 が指数部に実際に使う値
       if exp_buff > 127 then -- 指数部が正の場合
--         if (to_integer(exp_buff) - 127) > 254 then
         if (exp_buff - 127) > 254 then
           exp  := x"ff";
           frac := "000" & x"00000";
         else
           if frac_buff = 0 then
             sgn := '0';
             exp := x"ff";
             frac := "111" & x"fffff";
           else
           eb := TO_UNSIGNED(exp_buff - 127, 8);
           exp := unsigned(eb(7 downto 0));
           frac := frac_buff;
           end if;
         end if;
       else  -- 指数部が0以下になってしまう場合
         exp := x"00";
         frac := "000" & x"00000";
       end if;
              
     end if;
      
      output <= std_logic_vector(sgn & exp & frac);
        
    end process;


end dataflow_pipeline;
