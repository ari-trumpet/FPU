library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpu_common_p.all;

entity itof_pl is
    port (
      clk   : in std_logic;
      a     : in std_logic_vector(31 downto 0);
      s     : out std_logic_vector(31 downto 0));
end entity itof_pl;

architecture behavior of itof_pl is

  constant zero    : std_logic_vector(31 downto 0) := x"00000000";
  constant nintmax : std_logic_vector(31 downto 0) := x"80000000";
  
  signal intbody_0      : std_logic_vector(30 downto 0);
  signal ifzero_1, ifzero_0 : std_logic;
  signal ifnmax_1, ifnmax_0 : std_logic;
  signal sign_1, sign_0 : std_logic;
  signal exp_1, exp_0   : std_logic_vector(7 downto 0);
  signal frac_1, frac_0 : unsigned(30 downto 0);
  signal msb_1, msb_0   : integer range 0 to 30;

begin

  latch0: process (clk)
  begin
     if rising_edge(clk) then
      sign_0 <= a(31);
      intbody_0 <= a(30 downto 0);  
     end if;
  end process;
  
  seq0 : process(a, sign_0, intbody_0, frac_0,msb_0)
  begin
  
  if a = zero then  -- 0 の場合の処理
    ifzero_0 <= '1';
  else 
    ifzero_0 <= '0';
  end if;
  
  if a = nintmax then  -- nintmaxの場合の処理
    ifnmax_0 <= '1';
  else
    ifnmax_0 <= '0';
  end if;
  
  if sign_0 = '0' then  -- 負数を正数に変換
    frac_0 <= unsigned(intbody_0);
  else
    frac_0 <= unsigned(- signed(intbody_0));
  end if;
  
  msb_0 <= leading_zero_negative(frac_0);
  exp_0 <= std_logic_vector(TO_UNSIGNED(127 + msb_0, 8));
  
  end process;  
  
  latch1 : process(clk)
  begin
    if rising_edge(clk) then
      ifzero_1 <= ifzero_0;
      ifnmax_1 <= ifnmax_0;
      sign_1   <= sign_0;
      exp_1    <= exp_0;
      frac_1   <= frac_0;
      msb_1    <= msb_0;   -- 0 <= msb <= 30 
    end if;
  end process;
  
  seq1 : process(ifzero_1, ifnmax_1, sign_1, exp_1, frac_1, msb_1)
    variable frac   : unsigned(22 downto 0);
    variable frac25 : unsigned(24 downto 0);
    variable exp    : unsigned(7 downto 0); 
  begin
  if msb_1 < 24 then  -- 誤差が出ない場合の処理
    frac := shift_left(frac23_1(22 downto 0), 23 - msb_1);
    exp  := unsigned(exp_1);
  else
    frac25 := shit_right(frac_1(24 downto 0), msb_1 - 24);
    if frac25(0) = '1' then                        -- 0.1ulp = '1'で切り上げる場合
      if frac25 = 25bitall1 then                     -- 切り上げで桁上がりが生じる場合
        frac := "000" & x"00000";
        exp  := unsigned(exp_1) + 1;
      else                                           -- 切り上げで桁上がりが生じない場合
        frac := unsigned(frac25(23 downto 1)) + 1;
        exp  := unsigned(exp_1);
      end if;
    else                                           -- 0.1ulp = '0'で切り捨てる場合
        frac := unsigned(frac25(23 downto 1));
        exp  := unsigned(exp_1);
    end if;
      
  
  end if;
  s <= sign_1 & exp & frac;  -- 異なる型同士を連接可能？
  end process; 

end architecture behavior;


