function updateCurrentTrial(state,trial,set,trialCounter)
% updateCurrentTrial(state,trial,set,trialCounter)
% 
% Updates the list of trials in the state for the particular set using the
% input trial. Effectively, this inserts a trial into the trial list and
% saves the new list in the state object.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%   trial  -  struct containing information about the current trial
%   set    -  string representing the current part of the experiment
%   trialCounter  -  integer for the index of the current trial
%
% 10/9/17    xd  wrote it


trials = state{set}{'trials'};
trials{trialCounter} = trial;
state{set}{'trials'} = trials;

end

