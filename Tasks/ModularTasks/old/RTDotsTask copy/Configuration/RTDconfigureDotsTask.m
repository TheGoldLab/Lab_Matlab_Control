function RTDconfigureDotsTask(task, datatub, trialsPerCoherence)
% RTDconfigureDotsTask(task, datatub, trialsPerCoherence)
%
% RTD = Response-Time Dots
%
% Fills in information in a topsTreeNode representing a task 
%  "child" of the maintask. Uses the name of the task to determine
%  behavior:
%     'Quest'
%     'MeanRT'
%     A two-character key indicating
%        1. SAT type: 'S'peed, 'A'ccuracy, 'X' for neither
%        2. BIAS type: 'L'eft, 'R'ight, 'X' for neither
%
% Inputs:
%  task        ... the topsTreeNode
%  datatub     ... tub o' data
%  trialsPerCoherence ... number of trials
%
% 5/11/18 written by jig

%% ---- Check arg
if isempty(trialsPerCoherence)
   trialsPerCoherence = datatub{'Input'}{'trialsPerCoherence'};
end

%% ---- Instruction strings. 
%
% Define them here so they can be consistent across task types
SATstrings = { ...
   'Be as fast as possible'; ...
   'Be as accurate as possible'; ...
   'Be as fast and accurate as possible'};
BIASstrings = { ...
   'LEFT is more likely'; ...
   'RIGHT is more likely'; ...
   'BOTH directions equally likely'};

%% ---- Initialize some variables
directions      = datatub{'Input'}{'directions'};
coherences      = datatub{'Task'}{'referenceCoherence'};
directionPriors = [50 50];

%% ---- Case on task type
%
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
      task.taskData.quest = qpInitialize(qpParams( ...
         'stimParamsDomainList', {stimRange}, ...
         'psiParamsDomainList',  {thresholdRange, slopeRange, guessRate, lapseRange}));
      
      % Collect information to make trials
      coherences = min(100, max(0, qpQuery(task.taskData.quest)));
      
      % Choose the set of instructions
      instructions = {SATstrings{3}, BIASstrings{3}};
      
      % Make a quest callList to update quest status between trials
      questCallList = topsCallList('questCallList');
      questCallList.alwaysRunning = false;
      questCallList.addCall({@RTDupdateReferences, datatub}, 'update');
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
      meanRTCallList.addCall({@RTDupdateReferences, datatub}, 'update');
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

% Add structure array to the task's trialData
task.trialData = dealMat2Struct(task.trialData, ...
   'trialIndex', 1:numel(directionGrid), ...
   'direction', directionGrid(:)', ...
   'coherence', coherenceGrid(:)');

%% ---- Add the start task fevalable with task-specific instructions
task.startFevalable = {@RTDstartTask, datatub, task, instructions};
