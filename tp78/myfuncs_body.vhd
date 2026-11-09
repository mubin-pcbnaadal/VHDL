-- Created by @(#)$CDS: vhdlin version 6.1.8-64b 07/16/2019 20:11 (cpgbld02.cadence.com) $
-- on Wed Apr  1 13:51:39 2020


package body myfuncs is
  function bin2gray (bin : unsigned)
                   return unsigned is  
  variable gray : unsigned(bin'range) ;
  begin
	gray(bin'left) := bin(bin'left) ;
	for J in 0 to bin'length-2  loop
	  gray(J):=bin(J+1) xor bin(J) ;
	end loop ;
	return gray ;
  end bin2gray;

  function gray2bin (gray : unsigned)
                   return unsigned is  
  variable bin : unsigned(gray'range) ;
  begin
	bin(gray'left) := gray(gray'left) ;
	for J in 0 to gray'left-1 loop
	    bin(J) := gray(gray'left) ;
	    for k in gray'left-1 downto J loop
	      bin(J):=bin(J) xor gray(K) ;
	    end loop ;
	end loop ;
	return bin ;
  end gray2bin;


end myfuncs;
