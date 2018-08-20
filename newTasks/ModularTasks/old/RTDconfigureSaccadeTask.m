function RTDconfigureSaccadeTask(task, datatub, trialsPerDirection)
% RTDconfigureSaccadeTask(task, datatub, trialsPerDirection)
%
% RTD = Response-Time Dots
%
% Fills in information in a topsTreeNode representing a task 
%  "child" of the maintask. Uses the name of the task to determine
%  behavior:
%     'VGS' ... Visually guided saccade
%     'MGS' ... Memory guided saccade
%
% Inputs:
%  task        ... the topsTreeNode
%  datatub     ... tub o' data
%  trialsPerDirection ... number of trials
%
% 5/11/18 written by jig

%% ---- Check arg
if isempty(trialsPerDirection)
   trialsPerDirection = datatub{'Input'}{'trialsPerDirection'};
end

%% ---- Update the trialData structure array
% 
% Add structure array to the task's trialData
directions = repmat(datatub{'Input'}{'saccadeDirections'}, ...
   trialsPerDirection, 1);
task.trialData = dealMat2Struct(task.trialData, ...
   'trialIndex', 1:numel(directions), ...
   'direction', directions);

%% ---- Add the start task fevalable with task-specific instructions
switch task.name

   case 'VGS'
      instructions = { 'When the fixation spot disappears', ...
         'Look at the visual target'};
      
   case 'MGS'
      instructions = { 'When the fixation spot disappears', ...
         'Look at the remebered location of the visual target'};
end
task.startFevalable = {@RTDstartTask, datatub, task, instructions};
