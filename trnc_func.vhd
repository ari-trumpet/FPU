library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fpu_common_p.all;

package ftoi_p is

  function ftoi(a: fpu_data_t) return fpu_data_t;

end package;

package body ftoi_p is

  function ftoi(a: fpu_data_t)
    return fpu_data_t is

    variable fa     : float_t;
    variable sign   : std_logic;
    variable diff   : integer range 0 to 128;
    variable result : fpu_data_t;

  begin

    if is_metavalue(a) then
      return (others => 'X');
    end if;

    fa   := float(a);
    sign := fa.sign(0);

    if fa.expt < 127 then
      result := (others => '0');
    else
      diff := to_integer(fa.expt) - 127;

      if diff > 30 then
        result := (others => '0');
      elsif diff < 23 then
        result := resize(shift_right("1" & fa.frac, 23 - diff), 32);
      else
        result := resize(shift_left("1" & fa.frac, diff - 23), 32);
      end if;

      if sign = '1' then
        result := unsigned(- signed(result));
      end if;
    end if;

    return result;
  end function;

end package body;
