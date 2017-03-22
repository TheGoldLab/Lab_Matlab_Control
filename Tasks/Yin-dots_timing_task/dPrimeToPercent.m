function percent = dPrimeToPercent(dPrime)
% yl: 2010/09/15
% percent = dPrimeToPercent(dPrime)
%   converts value in d prime (sensitivity) to equivalent % correct
%   assuming 2AFC task

percent = normcdf(dPrime/sqrt(2));
