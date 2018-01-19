function vals_ = expFitVal(tStart, yStart, tau, yEnd, times)
%

vals_ = zeros(size(times));

% first -- linear
vals_(times<tStart) = yStart;

% second -- single exponential
Ltend = times>=tStart;
tend  = times(Ltend)-times(find(Ltend,1));
if yStart < yEnd
    vals_(Ltend) = yStart+(yEnd-yStart).*(1-exp(-tend./tau));
else
    vals_(Ltend) = yEnd+(yStart-yEnd).*exp(-tend./tau);
end
