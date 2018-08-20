function newTimes = syncAnalogTimes(oldTimes, syncTimes)
% function newTimes = syncAnalogTimes(oldTimes, syncTimes)
%
% Synchronizes analog times to matrix of sync values
%
% Inputs:
%  rawTimes    ... array of times
%  syncVals    ... nx2 matrix, values are times, columns are:
%                    1. new timeframe (i.e., of "oldTimes")
%                    2. old timeframe (i.e., of "newTimes")
%                  rows are different synchronization events
%
% Returns:
%  newTimes    ... same size as rawTimes, converted to new timeframe
%
% Created 6/24/2018 by jig

% Make the new time matrix
newTimes = nans(size(oldTimes));

% Make a temporary array to keep track of difference between each value of 
%  "oldTimes" and the current referent
diffTimes = inf.*ones(size(oldTimes));

% Loop through each synch pair
for tt = 1:size(syncTimes,1)
   
   % Find all gaze timestamps that are closer to the current sync time
   % than anyting checked previously, and save them
   diffs = abs(oldTimes-syncTimes(tt,2));
   Lsync = diffs < diffTimes;
   diffTimes(Lsync) = diffs(Lsync);
   
   % Use this sync pair for nearby timestamps
   newTimes(Lsync) = oldTimes(Lsync) - syncTimes(tt,2) + syncTimes(tt,1);
end

