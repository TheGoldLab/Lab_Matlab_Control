function g_ = endTrial(g_, goodTrialFlag, statelistOutcome)
%endTrial method for class dXscreen: do computations between trials
%   g_ = endTrial(g_, goodTrialFlag, statelistOutcome)
%
%   EndTrial methods allow DotsX classes to make computations with data
%   from the entire previous trial, or get ready for the next trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-% In remote mode, dXscreen will check for GetSecs timing drift relative
%-% to the remote machine.
%-%
%-% Arguments:
%-%   g_                ... the one dXscreen instance
%-%   goodTrialFlag     ... determined by dXtask/trial(), whether
%-%                         trial was meaningful (ignored)
%-%   statelistOutcome  ... cell array created by dXstate/loop() (ignored)
%-%
%-% Returns:
%-%   g_                ... updated dXscreen instance
%----------Special comments-----------------------------------------------
%
%   See also endTrial dXscreen

% Copyright 2007 Benjamin Heasly, University of Pennsylvania

if strcmp(g_.screenMode, 'remote')

    % clear the current time stamp and trigger a new one
    sendMsgH('%%%');
    
    % get the next timestamp and compare to current GetSecs
    %   growing the array is kinda lame
    lrcl = size(g_.remoteClockLog, 1)+1;
    g_.remoteClockLog(lrcl, :) = [nan, nan];
    g_.remoteClockLog(lrcl, 1) = getMsgH(200);
    g_.remoteClockLog(lrcl, 2) = GetSecs;
    
    % drift = diff(g_.remoteClockLog(lrcl, :));
    % if abs(drift) > 0.005;
    %     warning(sprintf('remote clock has drifted by %.4f seconds', drift))
    % end
end