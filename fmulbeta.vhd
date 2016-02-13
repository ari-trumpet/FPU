library ieee;
use ieee.std_logic_1164.all
use ieee.numeric_std.all

library work;
use work.fpu_common_p.all

component fmul_pl is
  port( clk : in std_logic;
        in1 : in std_logic_vector(31 downto 0);
        in2 : in std_logic_vector(31 downto 0);
        
