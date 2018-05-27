function RTDsetDotsChoice(datatub, value)
% function RTDsetDotsChoice(datatub, value)
%
% RTD = Response-Time Dots
%
% Save choice/RT information and set up feedback for the dots task
%
% Created 5/11/18 by jig

%% ---- Get current task/trial and save the choice
% The task is a topsTreeNode. The useful data are in thisTask.nodeData.
%  See RTDConfigureTasks for details
task = datatub{'Control'}{'currentTask'};
trial = task.trialData(task.trialIndex);
trial.choice = value;

%% ---- Parse choice info
if value<0
   
   % NO CHOICE
   %
   % Set feedback for no choice
   feedbackString = 'No choice';

else
   
   % GOOD CHOICE
   %
   % Mark as correct/error
   trial.correct = double( ...
      (trial.choice==0 && trial.direction==180) || ...
      (trial.choice==1 && trial.direction==0));
   
   % Compute/save RT
   %  Remember that dotsOn time might be from the remote computer, whereas
   %  sacOn is from the local computer, so we need to account for clock
   %  differences
   trial.RT = (trial.time_choice - trial.time_local_trialStart) - ...
       (trial.time_dotsOn - trial.time_screen_trialStart);
   
   % Set up feedback string
   %  First Correct/error
   if trial.correct == 1
      feedbackString = 'Correct';
   else
      feedbackString = 'Error';
   end
   
   %  Second possibly feedback about speed
   if task.name(1) == 'S'
      if trial.RT <= datatub{'Task'}{'referenceRT'}
         feedbackString = cat(2, feedbackString, ', in time');
      else
         feedbackString = cat(2, feedbackString, ', too slow');
      end
   end
end

%% ---- Re-save the current trial
task.trialData(task.trialIndex) = trial;
   
%% ---- Set the feedback string
textEnsemble = datatub{'Graphics'}{'textEnsemble'};
inds = datatub{'Graphics'}{'text inds'};
textEnsemble.setObjectProperty('string', feedbackString, inds(1));

%% --- Print feedback in the command window
disp(sprintf('  %s, RT=%.2f (%d correct, %d error, mean RT=%.2f)', ...
   feedbackString, trial.RT, ...
   sum([task.trialData.correct]==1), ...
   sum([task.trialData.correct]==0), ...
   nanmean([task.trialData.RT])))
