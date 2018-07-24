function DBSconfigureTasks(topNode)
% function DBSconfigureTasks(topNode)
%
% This function sets up tasks for a DBS experiment. Uses the 'taskSpecs'
%  cell array stored in the datatub, of the form:
%     {<TaskType1> <trialsPerCondition1> <TaskType2> <trialsPerCondition2>
%     <etc>}
%
% Arguments:
%  topNode ... the topsTreeNode at the top of the hierarchy

%% ---- Set defaults properties common to both tasks
commonProperties = { ...
   {'drawables', 'settings', 'targetDistance'}, topNode.nodeData{'Settings'}{'targetDistance'}, ...
   {'timing',    'showInstructions'},           topNode.nodeData{'Settings'}{'instructionDuration'},       ...
   {'settings',  'sendTTLs'},                   topNode.nodeData{'Settings'}{'sendTTLs'},       ...
   {'readables', 'userInput'},                  topNode.nodeData{'Control'}{'userInputDevice'}, ...
   {'drawables', 'screenEnsemble'},             topNode.nodeData{'Graphics'}{'screenEnsemble'}, ...
   {'drawables', 'textEnsemble'},               topNode.nodeData{'Graphics'}{'textEnsemble'},   ...
   'trialData',                                 DBSconfigureTrialData(), ...
   };

% gazeWindows for dotsReadableEyePupilLabs inputs
gw = @(i,n) cat(2, {'readables', 'gazeWindows'}, {i, n});
gazeWindows = { ...
   gw(1, 'windowSize'),                         topNode.nodeData{'Settings'}{'fixWindowSize'},  ...
   gw(1, 'windowDur'),                          topNode.nodeData{'Settings'}{'fixWindowDur'},  ...
   gw(2, 'windowSize'),                         topNode.nodeData{'Settings'}{'trgWindowSize'},  ...
   gw(2, 'windowDur'),                          topNode.nodeData{'Settings'}{'trgWindowDur'},  ...
   gw(3, 'windowSize'),                         topNode.nodeData{'Settings'}{'trgWindowSize'},  ...
   gw(3, 'windowDur'),                          topNode.nodeData{'Settings'}{'trgWindowDur'}};

%% ---- Make call lists to show text between tasks
%
% Welcome call list
welcome = topsCallList();
welcome.alwaysRunning = false;
welcome.addCall({@drawTextEnsemble, topNode.nodeData{'Graphics'}{'textEnsemble'}, { ...
   'Work at your own pace.', ...
   'Each trial starts by fixating the central cross'}, ...
   topNode.nodeData{'Settings'}{'instructionDuration'}, 1}, 'text');

% Countdown call list
countdown = topsCallList();
countdown.alwaysRunning = false;
for ii = 1:10
   countdown.addCall({@drawTextEnsemble, topNode.nodeData{'Graphics'}{'textEnsemble'}, ...
      {'Well done!', sprintf('Next task starts in: %d', 10-ii+1)}, 1, 0}, ...
      sprintf('c_%d', ii));
end
countdown.addCall({@pause, 1}, 'pause');

%% ---- Loop through the task specs array, making tasks with appropriate arg lists
%
taskSpecs = topNode.nodeData{'Settings'}{'taskSpecs'};
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
            {'settings' 'directions'}, topNode.nodeData{'Settings'}{'saccadeDirections'});
         
      otherwise
         
         % Make RTDots task with name, numTrials, and args
         task = topsTreeNodeTaskRTDots.getStandardConfiguration( ...
            taskSpecs{ii}, taskSpecs{ii+1}, commonProperties{:}, ...
            gazeWindows{:}, 'taskID', taskID, 'taskTypeID', taskTypeID, ...
            {'settings' 'coherences'}, topNode.nodeData{'Settings'}{'coherences'}, ...
            {'settings' 'referenceRT'}, topNode.nodeData{'Settings'}{'referenceRT'});
         
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
            topNode.nodeData{'Settings'}{'coherences'} = task;
            topNode.nodeData{'Settings'}{'referenceRT'} = task;
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
   topNode.addChild(task);
end