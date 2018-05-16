function RTDsetChoice(datatub, value)
% function RTDsetChoice(datatub, value)
%
% Save choice/RT information and set up feedback
%
% Created 5/11/18 by jig

%% ---- Get current task and save the choice
% The task is a topsTreeNode. The useful data are in thisTask.nodeData.
%  See RTDConfigureTasks for details
task = datatub{'Control'}{'currentTask'};
task.nodeData.trialData(task.nodeData.currentTrial).choice = value;

%% ---- Get the feedback drawable
feedbackEnsemble = datatub{'Graphics'}{'feedbackEnsemble'};
ind = datatub{'Graphics'}{'feedback ind'};

%% ---- Give appropriate feedback
if value<0
   
   % No choice
   feedbackEnsemble.setObjectProperty('string', 'No Choice', ind);
else
      
   % get the current trial
   trial = task.nodeData.trialData(task.nodeData.currentTrial);
   
   % Mark as correct/error
   if (trial.choice==0 && trial.direction==180) || ...
         (trial.choice==1 && trial.direction==0)
      trial.correct=1;
   else
      trial.correct=0;
   end
   
   % Compute/save RT
   trial.RT = 0.5; % jig TODO

   % re-save the current trial
   task.nodeData.trialData(task.nodeData.currentTrial) = trial;

   % Check if in speed task
   if task.name(1) == 'S'
      
      % Give feedback about speed only
      if trial.RT <= datatub{'Task'}{'referenceRT'}
         feedbackEnsemble.setObjectProperty('string', 'In time', ind);
      else
         feedbackEnsemble.setObjectProperty('string', 'Too slow', ind);
      end
      
   else
      
      % Give feedback about correct/error
      if (value==0 && trial.direction==180) || (value==1 && trial.direction==0)
         feedbackEnsemble.setObjectProperty('string', 'Correct', ind);
      else
         feedbackEnsemble.setObjectProperty('string', 'Error', ind);
      end
   end
end

