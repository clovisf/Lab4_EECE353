-- Antonio Ramon Vasconcelos de Freitas 66546128
-- Clovis Fritzen 64333131

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab4 is
  port(CLOCK_50            : in  std_logic;
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic);
end lab4;

architecture rtl of lab4 is

 --Component from the Verilog file: vga_adapter.v

  component vga_adapter
    generic(RESOLUTION : string);
    port (resetn                                       : in  std_logic;
          clock                                        : in  std_logic;
          colour                                       : in  std_logic_vector(2 downto 0);
          x                                            : in  std_logic_vector(7 downto 0);
          y                                            : in  std_logic_vector(6 downto 0);
          plot                                         : in  std_logic;
          VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
          VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
			 
  end component;

  signal x      : std_logic_vector(7 downto 0);
  signal y      : std_logic_vector(6 downto 0);
  signal colour : std_logic_vector(2 downto 0);
  signal plot   : std_logic;
  signal int_value : std_logic; 
  signal Xposition : std_logic_vector (7 downto 0);
  signal Yposition : std_logic_vector (6 downto 0); 
  signal slow_clock: std_logic_vector (22 downto 0);
begin

  -- includes the vga adapter, which should be in your project 
  	
  vga_u0 : vga_adapter
    generic map(RESOLUTION => "160x120") 
    port map(resetn    => KEY(3),
             clock     => CLOCK_50,
             colour    => colour,
             x         => x,
             y         => y,
             plot      => plot,
             VGA_R     => VGA_R,
             VGA_G     => VGA_G,
             VGA_B     => VGA_B,
             VGA_HS    => VGA_HS,
             VGA_VS    => VGA_VS,
             VGA_BLANK => VGA_BLANK,
             VGA_SYNC  => VGA_SYNC,
             VGA_CLK   => VGA_CLK);

				 
 process(CLOCK_50)
        variable slow_clock_var: unsigned (22 downto 0);
		  begin
          if (CLOCK_50'event and CLOCK_50 = '1') then
			 slow_clock_var:= unsigned (slow_clock);
            slow_clock_var:=  slow_clock_var + 1;
          end if;
			slow_clock <= std_logic_vector (slow_clock_var); 
 end process; 
              				 
-- begin of process for X
 
 process (slow_clock, KEY(3)) 
 variable int_signal : std_logic_vector (7 downto 0); 
 begin 
 if (KEY(0) ='0') then 
 int_signal := "00000000"; 
 elsif (slow_clock(slow_clock'left)'event and slow_clock(slow_clock'left) = '1') then 
 int_signal := (int_signal(1) XNOR int_signal(0)) & 
 int_signal(7 downto 1); 
 end if; 
 Xposition <= int_signal; 
 end process; 

-- end of process for X

-- begin of process for Y
process (slow_clock, KEY(3)) 
 variable int_signal : std_logic_vector (6 downto 0); 
 begin 
 if (KEY(0) ='0') then 
 int_signal := "0000000"; 
 elsif (slow_clock(slow_clock'left)'event and slow_clock(slow_clock'left) = '1') then 
 int_signal := (int_signal(1) XNOR int_signal(0)) & 
 int_signal(6 downto 1); 
 end if; 
 Yposition <= int_signal; 
 end process;
 
-- end of process for y
 
  process(KEY(3), CLOCK_50)
  variable countX : integer range 0 to 159;
  variable countY : integer range 0 to 119;
  variable colourVar : std_logic_vector(2 downto 0) := "001"; 
  variable int_value : std_logic_vector(1 downto 0);
  variable Xinitial : std_logic_vector (7 downto 0) := "01010000";
  variable Yinitial : std_logic_vector (6 downto 0) := "0111100";  
  variable absX0 : signed (8 downto 0);
  variable absX1 : signed (8 downto 0);
  variable Xlength : signed (8 downto 0);
  variable absY0 : signed (7 downto 0);
  variable absY1 : signed (7 downto 0);
  variable Ylength : signed (7 downto 0);
  variable Xsignal : signed (3 downto 0);
  variable Ysignal : signed (3 downto 0);
  variable Init_error : signed (8 downto 0);
  variable Actual_error : signed (17 downto 0);
  
  begin
	if(KEY(3) = '0') then -- Reset
		int_value := "00";
   elsif(CLOCK_50'event and CLOCK_50 = '1') then -- each time a counter overflows, 1 bit is plotted on screen
	--if(KEY(0) = '0') then -- Each time Key(0) is pressed, a line is plotted
		int_value := "01";
	--end if;
	case int_value is
	 when "00" => 
		Xinitial := "01010000";
		Yinitial := "0111100";
		if(countX > 159) then
			countY := countY + 1;
			countX := 0;
		else
			countX := countX + 1;
		end if;
		if(countY > 119) then
			countY := 0;
		end if;
		colourVar := "000";
		plot <= '1';
		x <= std_logic_vector(to_unsigned(countX,8));
		y <= std_logic_vector(to_unsigned(countY,7));		
	 when "01" => 
		absX0 := signed('0' & Xinitial);
		absX1 := signed('0' & Xposition);
		Xlength := abs(absX1 - absX0);
		absY0 := signed('0' & Yinitial);
		absY1 := signed('0' & Yposition);
		Ylength := abs(absY1 - absY0);

		if(Xinitial < Xposition) then
		Xsignal := to_signed(1,4);
		else
		Xsignal := to_signed(-1,4);
		end if;

		if(Yinitial < Yposition) then
		Ysignal := to_signed(1,4);
		else
		Ysignal := to_signed(-1,4);
		end if;

		Init_error := Xlength - Ylength;

		if ((Xposition /= Xinitial) and (Yposition /= Yinitial)) then
		Actual_error := 2*Init_error;
		else
		colourVar := std_logic_vector(unsigned(colourVar) + 1);
		int_value := "10";
		end if;

		if(Actual_error > -Ylength) then
		Init_error := Init_error - Ylength;
		Xinitial := std_logic_vector(signed(Xinitial) + Xsignal);
		end if;

		if(Actual_error < Xlength) then
		Init_error := Init_error + Xlength;
		Yinitial := std_logic_vector(signed(Yinitial) + Ysignal);
		end if;
		plot <= '1';
		x <= Xinitial;
		y <= Yinitial;
		when others =>
		plot<= '0';
		end case;
		colour <= colourVar;
	 end if;
	 end process;

end RTL;
