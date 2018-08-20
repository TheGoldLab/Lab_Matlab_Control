function presentInTime(state)
% presentInTime(state)
%
% Presents feedback telling the subject that their choice was in time for
% the fast context in SAT.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 10/2/17     xd  wrote it

duration  = state{'Timing'}{'feedback'};
incorrect = state{'graphics'}{'intimeFeedback'};
incorrect.callObjectMethod(@prepareToDrawInWindow);
incorrect.run(duration);

end

