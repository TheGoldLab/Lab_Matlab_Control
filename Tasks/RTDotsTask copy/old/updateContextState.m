function updateContextState(state)
% updateContextState(state)
%  
% This function updates each context's interal trial counter. Afterwards,
% it checks whether the trial counter has exceeded the number of
% trials/context. If this is the case, it resets the trial counter,
% increments the context counter, and sets the trial generation flag to
% true so that the next trial will begin with a pause and instruction
% screen.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 9/21/17    xd  wrote it

%% Load params
contextCounter = state{'SAT/BIAS'}{'contextCounter'};
trialsPerContext = state{'SAT/BIAS'}{'trialsPerContext'};

%% Update accordingly
state{'SAT/BIAS'}{'counter'} = state{'SAT/BIAS'}{'counter'} + 1;
contextTrialCounter = state{'SAT/BIAS'}{'counter'};
if contextTrialCounter > trialsPerContext * contextCounter
%     state{'SAT/BIAS'}{'counter'} = 1;
    state{'SAT/BIAS'}{'contextCounter'} = state{'SAT/BIAS'}{'contextCounter'} + 1;
    state{'SAT/BIAS'}{'contextSwitch'} = true;
    
    save('tempSaveFile','state');

end

end