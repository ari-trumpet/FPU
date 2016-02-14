library ieee;
use ieee.std_logic_1164.all
use ieee.numeric_std.all

library work;
use work.fpu_common_p.all

component fmul_pipeline is
  port( clk : in std_logic;
        in1 : in std_logic_vector(31 downto 0);
        in2 : in std_logic_vector(31 downto 0);
        ans : out std_logic_vector(31 downto 0));
end fmul_pipeline;

architecture fmul_blackbox of fmul_pipeline is

  type cornercase is (nan, inf , zero, normal);

  constant nan                : std_logic_vector(31 downto 0) := x"7fffffff";
  constant inf                : std_logic_vector(31 downto 0) := x"7f800000";
  constant zero               : std_logic_vector(31 downto 0) := x"00000000";
