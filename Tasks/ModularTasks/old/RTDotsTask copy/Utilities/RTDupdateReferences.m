function RTDupdateReferences(datatub)
% function RTDupdateReferences(datatub)
%
% RTD = Response-Time Dots
%
% Update quest and meanRT between trials
%
% Inputs:
%  datatub ... A topsGroupedList object containing experimental 
%                parameters as well as data recorded during the experiment.
% 
% 5/11/18 created by jig

%% ---- Get task/trial information
%
% The task is a topsTreeNodeTask. trialData is defined in RTDConfigureTasks.
task = datatub{'Control'}{'currentTask'};

%% ---- Update quest
if strcmp(task.name, 'Quest')
   
   % check for bad trial
   previousTrial = task.trialData(task.previousTrialIndex);
   if previousTrial.choice < 0
      return
   end
   
   % the Quest object
   q = task.taskData.quest;
   
   % Update Quest (expects 1=error, 2=correct)
   q = qpUpdate(q, previousTrial.coherence, previousTrial.correct + 1);
   
   % Re-save Quest object
   task.taskData.quest = q;
   
   % Update next guess, bounded between 0 and 100, if there is a next trial
   if task.trialIndex > 0
      task.trialData(task.trialIndex).coherence = min(100, max(0, qpQuery(q)));
   end
   
   % Set reference coherence to current threshold
   psiParamsIndex = qpListMaxArg(q.posterior);
   psiParamsQuest = q.psiParamsDomain(psiParamsIndex,:);
   datatub{'Task'}{'referenceCoherence'} = psiParamsQuest(1);   
end

%% ---- Update reference RT
if strcmp(task.name, 'meanRT') || ~isfinite(datatub{'Input'}{'referenceRT'})
   
   datatub{'Task'}{'referenceRT'} = nanmedian([task.trialData.RT]);
end

% disp(sprintf('update, coh=%.2f, RT=%.2f', ...
%    datatub{'Task'}{'referenceCoherence'}, datatub{'Task'}{'referenceRT'}))
