function RTDfinishTrial(datatub)
% function RTDfinishTrial(datatub)
%
% RTD = Response-Time Dots
%
% Fevalable called at the end of the stateMachine
%
% Inputs:
%   datatub    -  A topsGroupedList object containing experimental parameters
%                 as well as data recorded during the experiment.
%
% Created 5/11/18 by jig

%% ---- Get current task/trial information
% The task is a topsTreeNode. The useful data are in thisTask.nodeData.
%  See RTDConfigureTasks for details
task = datatub{'Control'}{'currentTask'};
trial = task.nodeData.trialData(task.nodeData.currentTrial);

%% ---- Always save the current trial in the DataLog
%  We do this even if no choice was made, in case later we want to re-parse
%     the UI data
topsDataLog.logDataInGroup(trial, 'trial');

%% ---- Check for good response
if ~isfinite(trial.choice) || trial.choice < 0
 
   % NO CHOICE
   % Set repeat flag
   task.nodeData.repeatTrial = true;

   % Randomize current direction and save it in the current trial
   %  inside the task array, which is where we'll look for it later
   directions = datatub{'Task'}{'directions'};
   task.nodeData.trialData(task.nodeData.currentTrial).direction = ...
      directions(randperm(length(directions),1));  
else
   
   % GOOD CHOICE
   % Unset repeat flag
   task.nodeData.repeatTrial = false;

   % Increment trial counter
   task.nodeData.currentTrial = task.nodeData.currentTrial + 1;
      
   % Check for new task
   if task.nodeData.currentTrial > size(task.nodeData.trialData, 1)
            
      % Stop running this task
      task.isRunning = false;
   end
end
