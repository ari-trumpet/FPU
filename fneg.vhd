library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.ALL;
use ieee.std_logic_unsigned.ALL;

entity fneg is
  port (
    a : in std_logic_vector(31 downto 0);
    s : out std_logic_vector(31 downto 0)
  );
end fneg;

architecture behavior of fneg is
begin  -- behavior
  s(30 downto 0) <= a(30 downto 0);
  s(31) <= not a(31);
end behavior;
