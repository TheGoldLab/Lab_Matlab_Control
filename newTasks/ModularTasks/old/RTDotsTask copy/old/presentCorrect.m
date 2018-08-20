function presentCorrect(state)
% presentCorrect(state)
%
% Presents feedback telling the subject that their choice was correct.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 9/20/17     xd  wrote it

duration  = state{'Timing'}{'feedback'};
correct = state{'graphics'}{'correct'};
correct.callObjectMethod(@prepareToDrawInWindow);
correct.run(duration);

end

