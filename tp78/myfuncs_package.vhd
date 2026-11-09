-- Created by @(#)$CDS: vhdlin version 6.1.8-64b 07/16/2019 20:11 (cpgbld02.cadence.com) $
-- on Wed Apr  1 13:51:39 2020


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

package myfuncs is
  function bin2gray (bin : unsigned)
                   return unsigned;
  function gray2bin (gray : unsigned)
                   return unsigned;
end myfuncs;
