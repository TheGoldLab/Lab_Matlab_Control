function RTDupdateQuest(datatub)
% function RTDupdateQuest(datatub)
%
% RTD = Response-Time Dots
%
% Update quest between trials
%
% Inputs:
%  datatub            ... A topsGroupedList object containing experimental 
%                          parameters as well as data recorded during the 
%                          experiment.
% 
% 5/11/18 created by jig

%% ---- Get current task and associated data
% The task is a topsTreeNode. The useful data are in thisTask.nodeData.
%  See RTDConfigureTasks for details
task = datatub{'Control'}{'currentTask'};

% check for repeat trial (second condition should never be met, just
% showing an over-abundance of caution, which is a good band name)
if task.nodeData.repeatTrial || task.nodeData.currentTrial<=1
   return
end

% Get data from the previous trial
trial = task.nodeData.trialData(task.nodeData.currentTrial-1);

% the Quest object
q = task.nodeData.taskData;
      
% Update Quest (expects 1=error, 2=correct)
q = qpUpdate(q, trial.coherence, trial.correct + 1);

% Re-save Quest object
task.nodeData.taskData = q;

% Update the next coherence
if task.nodeData.currentTrial >= size(task.nodeData.trialData,1)
   
   % task done, use final threshold as reference
   psiParamsIndex = qpListMaxArg(q.posterior);
   psiParamsQuest = q.psiParamsDomain(psiParamsIndex,:);
   datatub{'Task'}{'referenceCoherence'} = psiParamsQuest(1);
else
   
   % task ongoing, use next guess bounded between 0 and 100
   task.nodeData.trialData(task.nodeData.currentTrial).coherence = ...
      min(100, max(0, qpQuery(q)));
end
   
% Possibly update reference RT
if ~isfinite(datatub{'Input'}{'referenceRT'})
   RTDupdateMeanRT(datatub);
end
