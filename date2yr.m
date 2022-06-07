function year = date2yr(date)
% yr2date converrt [yr month day .. to n] to fractional year

% Written by YUAN Linguo
% Email:linguo.yuan@polyu.edu.hk
%   $Revision: 1.0 $  $Date: 2007/02/13 $

ser = datenum(date);
serbeg = datenum(date(1),1,1);
% See if year and therefore how many days in year
if mod(date(1),4) == 0 && mod(date(1),100) ~= 0 ||  mod(date(1),400 )== 0
    loy = 366;
else
    loy = 365;
end
year = date(1)+(ser-serbeg)./loy;

