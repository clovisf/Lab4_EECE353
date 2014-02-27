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
  signal resetn : std_logic;
  signal Xposition : std_logic_vector (7 downto 0);
  signal Yposition : std_logic_vector (6 downto 0);
  signal Xinitial : std_logic_vector (6 downto 0);
  signal Yinitial : std_logic_vector (6 downto 0);
  
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


  -- rest of your code goes here, as well as possibly additional files
  
  process(resetn) -- clean the screen (black screen)
  variable countX : integer range 0 to 159;
  variable countY : integer range 0 to 119;
  begin
  if(CLOCK_50'event and CLOCK_50 = '1') then
	if(countX = 159) then
		countY := countY + 1;
		countX := 0;
	else
		countX := countX + 1;
	end if;
	if(countY = 119) then
		countY := 0;
   end if;
	colour <= "111";
	plot <= '1';
	x <= std_logic_vector(to_unsigned(countX,8));
	y <= std_logic_vector(to_unsigned(countY,7));
	end if;
	end process;
	
	process (CLOCK_50)
		
		variable Xlength: signed;
		Variable Ylength: signed;
	
	begin
	
	Xposition <= SW (17 downto 10);
	Yposition <= SW (9 downto 3);
   Xlength := (to_signed (Xposition)) - (to_signed(Xinitial));  -- it should be a unsigned value (dx := abs(x1-x0))
	Ylength := (to_signed (Yposition)) - (to_signed(Yinitial));  -- it should be a unsigned value (dy := abs(y1-y0))
	
	if (Xinitial < Xposition) then -- if x0 < x1 then sx := 1 
	Xsignal <= 1; 
	else -- else sx := -1
	Xsignal <= -1;
	end if;

	if (Yinitial < Yposition) then -- if y0 < y1 then sy := 1 
	Ysignal <= 1; 
	else --else sy := -1
	Ysignal <= -1;
	end if;

	Init_error <= (Xlength- Ylength); -- err := dx-dy
	
	if (Xposition /= Xinitial) OR (Yposition /= Yinitial) then -- The opposite of ()if x0 = x1 and y0 = y1 exit loop)
		ActualError <= 2*Init_error;
		
		if (ActualError > -YLength) then -- if e2 > -dy then
		Init_error <= Init_error - Ylength; -- err := err – dy 
		Xinitial <= Xinitial + Xsignal; -- x0 := x0 + sx
		end if;
		
		if (ActualError < Xlength) then -- if e2 < dx then
		Init_error <= Init_error + Xlength; --err := err + dx
		Yinitial <= Yinitial + Ysignal; -- y0 := y0 + sy
		end if;
		
	end if;	

end process;
	
end RTL;


