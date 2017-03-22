function centerTargetOnFixation(targeti, timeWindow, varargin)
%Center a dXtarget on the recent average eye position
%
%   centerTargetOnFixation(targeti, timeWindow, varargin)
%
%   I want adapt online to offsets and drifts in fixation location.  So
%   this function should look at recent eye position stored in dXasl, and
%   recenter a target on the mean eye position.
%
%   targeti is the index of an active dXtarget object.
%
%   timeWindow is the length of time, in ms, over which to compute the most
%   recent average eye position.
%
%   Any remaining varargin should be property-value pairs, which are passed
%   to rSet.  So, you can change any dXtarget properties along with
%   recentering.

% 2008 by Benjamin Heasly, University of Pennsylvania

% From the active dXasl object, get
%   eye data for the current trial
%   camera speed, in hz
aslVals = rGet('dXasl', 1, 'values');
if ~isempty(aslVals) && ~isscalar(aslVals)

    aslHz = rGet('dXasl', 1, 'freq');

    % convert miliseconds to number of camera frames
    aslFrames = round(aslHz*timeWindow/1000);

    % get recent x (column 2) and y (column 3) positions
    recentXY = aslVals(end-aslFrames+1:end, 2:3);

    % reposition the specified target
    rSet('dXtarget', targeti, ...
        'x', mean(recentXY(:,1)), 'y', mean(recentXY(:,2)), ...
        varargin{:});
end
