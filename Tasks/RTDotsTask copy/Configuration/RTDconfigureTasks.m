function RTDconfigureTasks(maintask, datatub)
% function RTDconfigureTasks(datatub)
%
% RTD = Response-Time Dots
%
% Creates new topsTreeNodes representing task "children" of the maintask
%
% Inputs:
%  maintask    ... the top-level topsTreeNode
%  datatub     ... tub o' data
%
% 5/11/18 written by jig

% Instruction strings. Define them here so they can be consistent across
% task types
SATstrings = { ...
   'Be as fast as possible'; ...
   'Be as accurate as possible'; ...
   'Be as fast and accurate as possible'}; 
BIASstrings = { ...
   'LEFT is more likely'; ...
   'RIGHT is more likely'; ...
   'BOTH directions equally likely'};

% Get the stateMachine and stateMachineComposite. The former we add to the 
%  nodeData for each task (topsTreeNode). The later is added as a child.
stateMachine = datatub{'Control'}{'stateMachine'};
stateMachineComposite = datatub{'Control'}{'stateMachineComposite'};

% The standard "nodeData" struct to add to each task (topsTreeNode)
taskNumber = 1; % for feedback (see RTDstartTrial)
nodeData = struct( ...
   'stateMachine', stateMachine, ...
   'taskNumber', 0, ...
   'taskData',  [], ...
   'trialData', [], ...
   'totalCorrect', 0, ...
   'totalError', 0, ...   
   'currentTrial', 1, ...
   'repeatTrial', false);

%% ---- Loop through the taskSpecs celery
%
taskSpecs   = datatub{'Input'}{'taskSpecs'};
directions  = datatub{'Input'}{'directions'};
coherences  = datatub{'Input'}{'coherences'};
referenceRT = datatub{'Input'}{'referenceRT'};

for tt = 1:2:length(taskSpecs)
      
   % Parse the name and trial numbers from sequential arguments
   name = taskSpecs{tt};
   trialsPerCoherence  = taskSpecs{tt+1};
   if isempty(trialsPerCoherence)
      trialsPerCoherence = datatub{'Input'}{'trialsPerCoherence'};
   end
   
   % Initialize some variables
   taskData = [];
   children = {};
   
   % Case on task type
   if strcmp(name, 'Quest')

      % Quest block!      
      % Will use Quest to determine coherences for the other blocks
      coherences = nan;
      
      % Quest params
      stimRange = 0:1:100;
      thresholdRange = 0:50;
      slopeRange = 2:5;
      guessRate = 0.5;
      lapseRange = 0.00:0.01:0.05;
      
      % Initialize and save Quest object
      taskData = qpInitialize(qpParams( ...
         'stimParamsDomainList', {stimRange}, ...
         'psiParamsDomainList',  {thresholdRange, slopeRange, guessRate, lapseRange}));
            
      % Make trials using the first quest coherence and add to task array
      trialData = RTDconfigureTrials(directions, ...
         min(100, max(0, qpQuery(taskData))), [], trialsPerCoherence);

      % Choose the set of instructions
      instructions = {SATstrings{3}, BIASstrings{3}};
      
      % Make a quest callList to update quest status between trials
      questCallList = topsCallList('questCallList');
      questCallList.alwaysRunning = false;
      questCallList.addCall({@RTDupdateQuest, datatub}, 'update');
      children = {questCallList};
            
   elseif strcmp(name, 'meanRT')
      
      % meanRT block!
      % Will use meanRT to determine referenceRT for the other blocks
      referenceRT = nan;

      % Make trials
      trialData = RTDconfigureTrials(directions, coherences, ...
         [], trialsPerCoherence, []);
   
      % Choose the set of instructions
      instructions = {SATstrings{3}, BIASstrings{3}};

      % Make a quest callList to update quest status between trials
      meanRTCallList = topsCallList('meanRTCallList');
      meanRTCallList.alwaysRunning = false;
      meanRTCallList.addCall({@RTDupdateMeanRT, datatub}, 'update');
      children = {meanRTCallList};
      
   else

      % Standard test block, with SAT/BIAS conditions!      
      % Parse instructions
      instructions = {[], []};
      
      % SAT
      switch name(1)
         case {'S'}
            instructions{1} = SATstrings{1};
         case {'A'}
            instructions{1} = SATstrings{2};
         otherwise
            instructions{1} = SATstrings{3};
      end
      
      % Bias
      switch name(2)
         case {'L'}
            priors  = fliplr(datatub{'Input'}{'biasedPriors'});
            instructions{2} = BIASstrings{1};
         case {'R'}
            priors = datatub{'Input'}{'biasedPriors'};
            instructions{2} = BIASstrings{2};
         otherwise
            priors = [50 50];
            instructions{3} = BIASstrings{3};
      end
            
      % Make trials
      trialData = RTDconfigureTrials(directions, coherences, priors, ...
         trialsPerCoherence);
   end

   % Make the task
   task = maintask.newChildNode(name);
   task.startFevalable      = {@RTDstartTask, datatub, task, instructions};
   task.finishFevalable     = {@RTDfinishTask};
   task.nodeData            = nodeData;
   task.nodeData.taskNumber = taskNumber;
   task.nodeData.trialData  = trialData;
   task.nodeData.taskData   = taskData;
   task.iterations          = inf;
   task.addChild(stateMachineComposite);
   for cc = 1:length(children)
      task.addChild(children{cc});
   end
   taskNumber = taskNumber + 1;
end

% use
datatub{'Task'}{'referenceCoherence'} = coherences(1);
datatub{'Task'}{'referenceRT'} = referenceRT;

