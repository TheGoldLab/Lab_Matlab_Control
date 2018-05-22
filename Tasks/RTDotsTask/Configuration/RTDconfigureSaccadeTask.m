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
%     'MeanRT'
%     A two-character key indicating
%        1. SAT type: 'S'peed, 'A'ccuracy, 'X' for neither
%        2. BIAS type: 'L'eft, 'R'ight, 'X' for neither
%
% Inputs:
%  task        ... the topsTreeNode
%  datatub     ... tub o' data
%  trialsPerDirection ... number of trials
%
% 5/11/18 written by jig

%% ---- Instruction strings. 
%
% Define them here so they can be consistent across task types
topStrings = { ...
   'When the fixation spot disappears'};
bottomStrings = { ...
   'Look at the visual target'; ...
   'Look at the remebered location of the visual target'};

%% ---- Initialize some variables
directions = datatub{'Input'}{'saccadeDirections'};

%% ---- Make the task/trial info
%


% Add structure array to the task's nodeData
task.nodeData.trialData = struct( ...
   'trialIndex', (1:numTrials)', ...
   'direction', num2cell(directionGrid), ...
   'RT', nan, ...
   'correct', nan, ...
   'time_screen_roundTrip', 0, ...
   'time_local_trialStart', nan, ...
   'time_ui_trialStart', nan, ...
   'time_screen_trialStart', nan, ...
   'time_TTLFinish', nan, ...
   'time_fixOn', nan, ...
   'time_targsOn', nan, ...
   'time_dotsOn', nan, ...
   'time_choice', nan, ...
   'time_dotsOff', nan, ...
   'time_fdbkOn', nan, ...
   'time_local_trialFinish', nan, ...
   'time_ui_trialFinish', nan, ...
   'time_screen_trialFinish', nan);

%% ---- Add the start task fevalable with task-specific instructions
task.startFevalable = {@RTDstartTask, datatub, task, instructions};

switch task.name
   
   case 'Quest'
      
      % Quest block!
      % Will use Quest to determine coherences for the other blocks
      datatub{'Task'}{'referenceCoherence'} = nan;
      
      % Quest params
      stimRange = 0:1:100;
      thresholdRange = 0:50;
      slopeRange = 2:5;
      guessRate = 0.5;
      lapseRange = 0.00:0.01:0.05;
      
      % Initialize and save Quest object
      task.nodeData.taskData = qpInitialize(qpParams( ...
         'stimParamsDomainList', {stimRange}, ...
         'psiParamsDomainList',  {thresholdRange, slopeRange, guessRate, lapseRange}));
      
      % Collect information to make trials
      coherences = min(100, max(0, qpQuery(task.nodeData.taskData)));
      
      % Choose the set of instructions
      instructions = {SATstrings{3}, BIASstrings{3}};
      
      % Make a quest callList to update quest status between trials
      questCallList = topsCallList('questCallList');
      questCallList.alwaysRunning = false;
      questCallList.addCall({@RTDupdateQuest, datatub}, 'update');
      task.addChild(questCallList);

   case 'meanRT'
      
      % meanRT block!
      % Will use meanRT to determine referenceRT for the other blocks
      datatub{'Task'}{'referenceRT'} = nan;
      
      % Choose the set of instructions
      instructions = {SATstrings{3}, BIASstrings{3}};
      
      % Make a quest callList to update quest status between trials
      meanRTCallList = topsCallList('meanRTCallList');
      meanRTCallList.alwaysRunning = false;
      meanRTCallList.addCall({@RTDupdateMeanRT, datatub}, 'update');
      task.addChild(meanRTCallList);
      
   otherwise
      
      % Standard test block, with SAT/BIAS conditions!
      % Parse instructions
      instructions = {[], []};
      
      % SAT
      switch task.name(1)
         case {'S'}
            instructions{1} = SATstrings{1};
         case {'A'}
            instructions{1} = SATstrings{2};
         otherwise
            instructions{1} = SATstrings{3};
      end
      
      % Bias
      switch task.name(2)
         case {'L'}
            directionPriors = fliplr(datatub{'Input'}{'biasedPriors'});
            instructions{2} = BIASstrings{1};
         case {'R'}
            directionPriors = datatub{'Input'}{'biasedPriors'};
            instructions{2} = BIASstrings{2};
         otherwise
            instructions{3} = BIASstrings{3};
      end      
end

%% ---- Make the trials

% Make array of directions
directionPriors = directionPriors./(sum(directionPriors));
directionArray = cat(1, ...
   repmat(directions(1), round(directionPriors(1).*trialsPerCoherence), 1), ...
   repmat(directions(2), round(directionPriors(2).*trialsPerCoherence), 1));

% Make grid of directions, coherences
[directionGrid, coherenceGrid] = meshgrid(directionArray, coherences);

% Get number of trials and make randomized vectors
numTrials = numel(directionGrid);
indices = randperm(numTrials);
directionGrid = directionGrid(indices)';
coherenceGrid = coherenceGrid(indices)';

% Add structure array to the task's nodeData
task.nodeData.trialData = struct( ...
   'trialIndex', (1:numTrials)', ...
   'direction', num2cell(directionGrid), ...
   'coherence', num2cell(coherenceGrid), ...
   'choice', nan, ...
   'RT', nan, ...
   'correct', nan, ...
   'time_screen_roundTrip', 0, ...
   'time_local_trialStart', nan, ...
   'time_ui_trialStart', nan, ...
   'time_screen_trialStart', nan, ...
   'time_TTLFinish', nan, ...
   'time_insOn', nan, ...
   'time_fixOn', nan, ...
   'time_targsOn', nan, ...
   'time_dotsOn', nan, ...
   'time_choice', nan, ...
   'time_dotsOff', nan, ...
   'time_fdbkOn', nan, ...
   'time_local_trialFinish', nan, ...
   'time_ui_trialFinish', nan, ...
   'time_screen_trialFinish', nan);

%% ---- Add the start task fevalable with task-specific instructions
task.startFevalable = {@RTDstartTask, datatub, task, instructions};
