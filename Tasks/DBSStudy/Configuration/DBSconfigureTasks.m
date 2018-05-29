function DBSconfigureTasks(maintask, datatub)
% function DBSconfigureTasks(maintask, datatub)
%
% configuration routine for topsTreeNodeTask classes
%
% Separated from DBSconfigure for readability
%
% 5/28/18 created by jig

%% ---- Configure Tasks + State Machines
%
% list of all possible task names, to get IDs
taskNames = {'VGS' 'MGS' 'Quest' 'NN' 'NL' 'NR' 'SN' 'SL' 'SR' ...
   'AN' 'AL' 'AR'};

% Feedback strings
SATstrings = { ...
   'S' 'Be as fast as possible'; ...
   'A' 'Be as accurate as possible'; ...
   'N' 'Be as fast and accurate as possible'};

BIASstrings = { ...
   'L' 'LEFT is more likely'; ...
   'R' 'RIGHT is more likely'; ...
   'N' 'BOTH directions equally likely'};

% Objects used below
screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};
textEnsemble   = datatub{'Graphics'}{'textEnsemble'};
ui             = datatub{'Control'}{'userInputDevice'};
kb             = datatub{'Control'}{'keyboard'};

% Make a call list to show countdown timer between tasks
countdown = topsCallList();
countdown.alwaysRunning = false;
for ii = 1:10
   countdown.addCall({@drawTextEnsemble, textEnsemble, ...
      {'Well done!', sprintf('Next task starts in: %d', 10-ii+1)}, 1}, ...
      sprintf('c_%d', ii));
end
countdown.addCall({@pause, 1}, 'pause');

% Loop through the taskSpecs array, making and adding tasks
taskSpecs = datatub{'Input'}{'taskSpecs'};
taskNumber = 1; % for feedback (see RTDstartTrial)
for tt = 1:2:length(taskSpecs)
   
   % Parse the name and trial numbers from sequential arguments
   name = taskSpecs{tt};
   trialsPerCondition = taskSpecs{tt+1};
   
   % Add task-specific information, depending on the named type
   switch (name)
      
      case {'VGS', 'MGS'}
         
         % Saccade task!
         %
         task = topsTreeNodeTaskSaccade(name);

         % Set instruction strings
         if strcmp(name, 'VGS')
            task.instructionStrings = { 'When the fixation spot disappears', ...
               'Look at the visual target'};      
         else
            task.instructionStrings = { 'When the fixation spot disappears', ...
               'Look at the remebered location of the visual target'};
         end
         
         % check to update task/trial properties
         task.setIfNotEmpty({'trialProperties', 'targetDistance'}, datatub{'Input'}{'targetDistance'});
         task.setIfNotEmpty({'trialProperties', 'directions'}, datatub{'Input'}{'saccadeDirections'});
         task.setIfNotEmpty({'trialProperties', 'trialsPerDirection'}, trialsPerCondition);

      otherwise
                  
         % Dots task!
         %
         task = topsTreeNodeTaskRTDots(name);
         
         % Check for Quest
         if strcmp(name, 'Quest')
            
            % Send flag to use Quest for coherence
            task.trialProperties.coherences = 'Quest';

            % Signals all other tasks to use the Quest coherence
            datatub{'Input'}{'coherences'} = nan;
            
            % Use Neutral specs
            name = 'NN';
         else
            
            % check to update coherences
            task.setIfNotEmpty({'trialProperties', 'coherences'}, datatub{'Input'}{'coherences'});
         end
         
         % check to update dot directions, trials per coherence
         task.setIfNotEmpty({'trialProperties', 'directions'}, datatub{'Input'}{'dotDirections'});
         task.setIfNotEmpty({'trialProperties', 'trialsPerCoherence'}, trialsPerCondition);

         % Parse name for task specifications (see comments at the top)
         task.instructionStrings = { ...
            SATstrings{strcmp(name(1), SATstrings(:,1)), 2}, ...
            BIASstrings{strcmp(name(2), BIASstrings(:,1)), 2} };
         
         % Parse name for biases
         priors = datatub{'Input'}{'biasedPriors'};
         if name(2) == 'L'
            task.trialProperties.directionPriors = [max(priors) min(priors)];
         elseif name(2) == 'R'
            task.trialProperties.directionPriors = [min(priors) max(priors)];
         end
         
         % Set referents for coherence, RT
         task.groupList = datatub;
         task.coherenceRef = {'Control', 'referenceCoherence'};
         task.RTRef = {'Control', 'referenceRT'};
   end
   
   % check to update other properties
   props = {'fixWindowSize', 'fixWindowDur', 'trgWindowSize', ...
      'trgWindowDur', 'sendTTLs'};
   for jj = 1:length(props)
      task.setIfNotEmpty(props{jj}, datatub{'Input'}{props{jj}});
   end
   
   % Add the standard trial data
   task.trialData = struct( ...
      'taskID', find(strcmp(name, taskNames)), ...
      'trialIndex', nan, ...
      'direction', nan, ...
      'coherence', nan, ...
      'choice', nan, ...
      'RT', nan, ...
      'correct', nan, ...
      'time_screen_roundTrip', 0, ...
      'time_local_trialStart', nan, ...
      'time_ui_trialStart', nan, ...
      'time_screen_trialStart', nan, ...
      'time_TTLStart', nan, ...
      'time_TTLFinish', nan, ...
      'time_fixOn', nan, ...
      'time_targsOn', nan, ...
      'time_dotsOn', nan, ...
      'time_targsOff', nan, ...
      'time_fixOff', nan, ...
      'time_choice', nan, ...
      'time_dotsOff', nan, ...
      'time_fdbkOn', nan, ...
      'time_local_trialFinish', nan, ...
      'time_ui_trialFinish', nan, ...
      'time_screen_trialFinish', nan);
   
   % Set remaining task properties
   task.screenEnsemble = screenEnsemble;
   task.textEnsemble   = textEnsemble;
   task.keyboard       = kb;
   task.userInput      = ui;
   task.iterations     = inf;
   task.taskID         = taskNumber;
   
   % call the configure command
   task.configure();
   
   % Add some fevalables to show instructions/feedback before/after tasks
   if taskNumber == 1
      
      % Initial instructions
      if isa(ui, 'dotsReadableEye')
         str2 = 'Each trial starts by fixating the central cross';
      else
         str2 = 'Each trial starts by pressing the space bar';
      end
      welcome = topsCallList();
      welcome.alwaysRunning = false;
      welcome.addCall({@drawTextEnsemble, textEnsemble, ...
         {'Work at your own pace', str2}, 2}, 'text');
      welcome.addCall({@pause, 1}, 'pause');
      task.startFevalable = {@run, welcome};      
   else
      
      % show a countdown
      task.startFevalable = {@run, countdown};
   end
   
   % increment the counter
   taskNumber = taskNumber + 1;
   
   % add the task
   maintask.addChild(task);
end

% Set up references that may or may not be overriden by Quest/MeanRT tasks
datatub{'Control'}{'referenceRT'} = datatub{'Input'}{'referenceRT'};
datatub{'Control'}{'referenceCoherence'} = datatub{'Input'}{'coherences'};