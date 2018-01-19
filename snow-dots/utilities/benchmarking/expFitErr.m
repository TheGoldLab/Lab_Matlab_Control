function err_ = expFitErr(fits, data)
%
% fits are:
%   1 .. tStart
%   2 .. yStart
%   3 .. tau
%   4 .. yEnd
%
% data columns are:
%   time
%   voltage

vals = expFitVal(fits(1), fits(2), fits(3), fits(4), data(:,1));
err_ = sum((data(:,2)-vals).^2);
