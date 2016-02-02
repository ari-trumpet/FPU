library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsqrt_pl is
    port (
        clk : in std_logic;
        input  : in  std_logic_vector(31 downto 0);
        output : out std_logic_vector(31 downto 0));
end fsqrt_pl;

architecture twoproc_pipeline of fsqrt_pl is
    component fsqrttable is
      port (
        clk : in  std_logic;
        key : in  std_logic_vector(9 downto 0);
        tout : out std_logic_vector(35 downto 0) := (others => '0'));
    end component;

    signal key : std_logic_vector(9 downto 0) := (others => '0');
    signal tout : std_logic_vector(35 downto 0);
    signal rest : unsigned(13 downto 0) := (others => '0');
    signal sgn_in, sgn_in_p : std_logic := '0';
    signal exp_in, exp_in_p : unsigned(7 downto 0) := (others => '0');
    signal a0, a0_p : unsigned(22 downto 0) := (others => '0');
    signal t1, t1_p : unsigned(22 downto 0) := (others => '0');
    signal mant_in, mant_p : unsigned(22 downto 0) := (others => '0');

begin
    seq_0 : process(input)
    begin
        key <= input(23 downto 14);
    end process;
    table_map : fsqrttable port map (clk => clk, key => key, tout => tout);

    clock_0 : process(clk)
    begin
        if rising_edge(clk) then
            sgn_in <= input(31);
            exp_in <= unsigned(input(30 downto 23));
            rest <= unsigned(input(13 downto 0));
            mant_in <= unsigned(input(22 downto 0));
        end if;
    end process;

    seq_1 : process(tout, rest)
        variable a1 : unsigned(12 downto 0);
        variable tmp : unsigned(26 downto 0);
    begin
        a0 <= unsigned(tout(35 downto 13));
        a1 := unsigned(tout(12 downto  0));
        tmp := a1 * rest;
        t1 <= "000000000" & tmp(26 downto 13);
    end process;

    latch_1 : process(clk)
    begin
        if rising_edge(clk) then
            sgn_in_p <= sgn_in;
            exp_in_p <= exp_in;
            mant_p    <= mant_in;
            a0_p <= a0;
            t1_p <= t1;
        end if;
    end process;

    seq_2 : process(sgn_in_p, exp_in_p, mant_p, a0_p, t1_p)
        variable exp_out : unsigned(7 downto 0);
        variable frc_out : unsigned(22 downto 0);
    begin
        if exp_in_p = x"00" then
            exp_out := x"00";
            frc_out := (others => '0');
        elsif sgn_in_p = '1' then
            exp_out := x"FF";
            frc_out := x"00000" & "00" & '1';
        elsif exp_in_p = x"FF" then
            exp_out := x"FF";
            if mant_p = 0 then
              frc_out := (others => '0');
            else 
              frc_out := "111" & x"FFFFF";
            end if;
        else 
            exp_out := x"3F" + ("0" & exp_in_p(7 downto 1)) + unsigned'(0 => exp_in_p(0));
            frc_out := a0_p + t1_p;
        end if;
        output <= std_logic_vector(sgn_in_p & exp_out & frc_out);
    end process;

end twoproc_pipeline;
