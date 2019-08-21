function [changePoints_, duration_] = computeChangePoints(hazardRate, ...
   minInterval, maxInterval, duration, lastEpochDuration)
%function [changePoints_, duration_] = computeChangePoints(hazardRate, ...
%   minInterval, maxInterval, duration, lastEpochDuration)
%
% Utility for pre-computing a sequence of change-points 
%
% Arguments:
%  
%  hazardRate     ... scalar [0,1]
%  minInterval    ... set minimum interval between change-points, in sec
%  maxInterval    ... set maximum interval between change-points, in sec
%  duration       ... total duration, in sec. If 3-element vector, then
%                       treated as [min, mean, max] of exponential
%  lastEpochDuration ... Possibly set the duration of the final epoch
%                       (i.e., after the final change-point). Parsed like
%                       duration.

% First compute duration
%
if nargin < 4 || isempty(duration)

   % Default
   duration_ = 1.0;
elseif length(duration) == 3
   
   % Sample from exponential, with min/max
   duration_ = min(duration(1) + exprnd(duration(2)), duration(3));
else
   
   % Use given value
   duration_ = duration(1);
end

% Compute change-points
%
% Pick a bunch at random
cps = exprnd(1/hazardRate, 1, duration*hazardRate*50);

% Apply min/max
if nargin >= 2 && ~isempty(minInterval) && minInterval > 0
   cps = cps(cps>minInterval);
end
if nargin >= 2 && ~isempty(maxInterval) && maxInterval > 0
   cps = cps(cps<maxInterval);
end

% Concat the intervals (use the cumulative sum)
cps = cumsum(cps);

% Get the number we need
changePoints_ = cps(cps<duration_);

% Check for "lastEpochDuration"
if ~isempty(changePoints_) && nargin >= 5 && ~isempty(lastEpochDuration)
   
   % A bit trickier -- we want to make sure the total duration is at least
   % "duration" but that there is also "lastEpochDuration" beyond the final
   % change point
   %
   % First parse lastEpochDuration
   if length(lastEpochDuration) == 3
      
      % Sample from exponential, with min/max
      lastEpochDuration = min(lastEpochDuration(1) + exprnd(lastEpochDuration(2)), lastEpochDuration(3));
   else
      % Use given value
      lastEpochDuration = lastEpochDuration(1);
   end
   
   % Keep to the final change point and add the rest
   duration_ = changePoints_(end) + lastEpochDuration;
end