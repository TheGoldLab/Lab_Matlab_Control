% Transform timestamps from one clock to another clock's equivalents.
% @param timestampsA array of timestamps for some events, taken with
% "clock A"
% @param aToB a struct with transformation parameters as returned from
% clockDriftEstimate()
% @details
% Uses "drift" and "offset" parameters in @a aToB to do a linear transform
% on @a timestampsA.  Returns timestamps for events that were "seen" from
% clock A, as they might have been "seen" from clock B.
% @details
% Also returns as a second output the "delta" error estimates (standard
% deviation) for the returned timestamps, obtained from Matlab's builtin
% polyval().
% @details
% See clockDriftEstimate() for estimating the drift and offset between
% clocks A and B.
%
% @ingroup dotsUtilities
function [timestampsB, delta] = clockDriftApply(timestampsA, aToB)
mu = aToB.polyMu;
coefficients = [aToB.drift*mu(2), aToB.offset + aToB.drift*mu(1)];
[timestampsB, delta] = polyval(coefficients, timestampsA, ...
    aToB.polyInfo, aToB.polyMu);