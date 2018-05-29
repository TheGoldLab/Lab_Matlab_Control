function presentFeedback(state)
% function presentFeedback(state)
%
% Does some bookkeepig and gives feedback at the end of the trial.
%
% Inputs:
%   state  -  topsGroupedList object that contains all the parameters
%             described above as well as snow dots drawable objects for the
%             fixation cue and saccade targets.
%
% 4/25/18    jig  wrote it

% get the current trial
taskArray = state{'task'}{'taskArray'};
taskCounter = state{'task'}{'taskCounter'};
trialCounter = state{'task'}{'trialCounter'};
trial = taskArray{2, taskCounter}(trialCounter);

% get the feedback text object
feedback = state{'graphics'}{'feedback'};

if isnan(trial.choice)
   
   % invalid choice
   feedback.string = 'Invalid';

elseif taskArray{1, taskCounter}(1)=='S'
   
   % speed condition, compare to RT
   if (trial.RT < state{'task'}{'referenceRT'}            
      feedback.string = 'In time';
   else
      feedback.string = 'Too slow';
   end
   
else
   
   % check for correct/error
   if trial.correct
      feedback.string = 'Correct';
   else
      feedback.string = 'Error';
   end
end

% show it for a fixed time
feedback.drawFrame();





        