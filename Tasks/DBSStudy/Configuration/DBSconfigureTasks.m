function DBSconfigureTasks(mainTreeNode, datatub)
% function DBSconfigureTasks(mainTreeNode, datatub)
%
% This function sets up tasks for a DBS experiment. Uses the 'taskSpecs'
%  cell array stored in the datatub, of the form:
%     {<TaskType1> <trialsPerCondition1> <TaskType2> <trialsPerCondition2>
%     <etc>}
%
% Arguments:
%  mainTreeNode ... the topsTreeNode at the top of the hierarchy
%  datatub      ... the topsGroupedList that holds task variables

%% ---- Set defaults properties common to both tasks
commonProperties = { ...
   {'drawables', 'settings', 'targetDistance'}, datatub{'Settings'}{'targetDistance'}, ...
   {'settings',  'sendTTLs'},                   datatub{'Settings'}{'sendTTLs'},       ...
   {'readables', 'userInput'},                  datatub{'Control'}{'userInputDevice'}, ...
   {'drawables', 'screenEnsemble'},             datatub{'Graphics'}{'screenEnsemble'}, ...
   {'drawables', 'textEnsemble'},               datatub{'Graphics'}{'textEnsemble'},   ...
   'trialData',                                 DBSconfigureTrialData(), ...
   };

% gazeWindows for dotsReadableEyePupilLabs inputs
gw = @(i,n) cat(2, {'readables', 'gazeWindows'}, {i, n});
gazeWindows = { ...
   gw(1, 'windowSize'),                         datatub{'Settings'}{'fixWindowSize'},  ...
   gw(1, 'windowDur'),                          datatub{'Settings'}{'fixWindowDur'},  ...
   gw(2, 'windowSize'),                         datatub{'Settings'}{'trgWindowSize'},  ...
   gw(2, 'windowDur'),                          datatub{'Settings'}{'trgWindowDur'},  ...
   gw(3, 'windowSize'),                         datatub{'Settings'}{'trgWindowSize'},  ...
   gw(3, 'windowDur'),                          datatub{'Settings'}{'trgWindowDur'}};

%% ---- Make call list to show text between tasks
%
% Welcome call list
welcome = topsCallList();
welcome.alwaysRunning = false;
welcome.addCall({@drawTextEnsemble, datatub{'Graphics'}{'textEnsemble'}, { ...
   'Work at your own pace', ...
   'Each trial starts by fixating the central cross'}, 2, 1}, 'text');

% Countdown call list
countdown = topsCallList();
countdown.alwaysRunning = false;
for ii = 1:10
   countdown.addCall({@drawTextEnsemble, datatub{'Graphics'}{'textEnsemble'}, ...
      {'Well done!', sprintf('Next task starts in: %d', 10-ii+1)}, 1, 0}, ...
      sprintf('c_%d', ii));
end
countdown.addCall({@pause, 1}, 'pause');

%% ---- Loop through the task specs array, making tasks with appropriate arg lists
%
taskSpecs = datatub{'Settings'}{'taskSpecs'};
noDots = true;
taskID = 1;
for ii = 1:2:length(taskSpecs)
   
   % Get ID from index in list of task names
   taskTypeID = find(strcmp(taskSpecs{ii}, {'VGS' 'MGS' 'Quest' 'NN' 'NL' 'NR' ...
      'SN' 'SL' 'SR' 'AN' 'AL' 'AR'}),1);
   
   switch taskSpecs{ii}
      
      case {'VGS' 'MGS'}
         
         % Make Saccade task with name, numTrials, and args
         task = topsTreeNodeTaskSaccade.getStandardConfiguration( ...
            taskSpecs{ii}, taskSpecs{ii+1}, commonProperties{:}, ...
            gazeWindows{1:8}, 'taskID', taskID, 'taskTypeID', taskTypeID, ...
            {'settings' 'directions'}, datatub{'Settings'}{'saccadeDirections'});
            
      otherwise
         
         % Make RTDots task with name, numTrials, and args
         task = topsTreeNodeTaskRTDots.getStandardConfiguration( ...
            taskSpecs{ii}, taskSpecs{ii+1}, commonProperties{:}, ...
            gazeWindows{:}, 'taskID', taskID, 'taskTypeID', taskTypeID, ...
            {'settings' 'coherences'}, datatub{'Settings'}{'coherences'}, ...
            {'settings' 'referenceRT'}, datatub{'Settings'}{'referenceRT'});                     

         % Add special instructions for first dots task
         if noDots
            task.drawables.settings.textStrings = cat(1, ...
               {'When flickering dots appear, decide their overall direction', ...
               'of motion, then look at the target in that direction'}, ...
               task.drawables.settings.textStrings);
            noDots = false;
         end
         
         % Special case of quest ... use output as coh/RT refs
         if strcmp(taskSpecs{ii}, 'Quest')
            datatub{'Settings'}{'coherences'} = task;
            datatub{'Settings'}{'referenceRT'} = task;
         end         
   end
   
   % Add some fevalables to show instructions/feedback before/after tasks
   if ii == 1 
      task.startFevalable = {@run, welcome};
   else
      task.startFevalable = {@run, countdown};
   end
   
   % update the unique ID
   taskID = taskID + 1;
   
   % Add as child to the maintask. Have it loop forever until explicitly
   % aborted by the task logic
   task.iterations = inf;
   mainTreeNode.addChild(task);   
   
end