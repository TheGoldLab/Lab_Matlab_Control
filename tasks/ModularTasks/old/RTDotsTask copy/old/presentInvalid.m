function presentInvalid(state)
% presentInvalid(state)
%
% Presents feedback telling the subject that their choice was invalid.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 9/20/17     xd  wrote it

duration  = state{'Timing'}{'feedback'};
invalid = state{'graphics'}{'invalid'};
invalid.callObjectMethod(@prepareToDrawInWindow);
invalid.run(duration);

end

