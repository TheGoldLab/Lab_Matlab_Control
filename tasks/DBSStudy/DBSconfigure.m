function topNode =  DBSconfigure(varargin)
%% function topNode =  DBSconfigure(varargin)
%
% This function sets up a DBS experiment. We keep this logic separate from
% running and cleaning up an experiment because we may want to decide
% when/how do do those other things on the fly (e.g., add/subtract tasks
% depending on the subject's motivation, etc).
%
% Arguments:
%  varargin  ... optional <property>, <value> pairs for settings variables
%                 note that <property> can be a cell array for nested
%                 property structures in the task object
%
% Returns:
%  mainTreeNode ... the topsTreeNode at the top of the hierarchy
%
% 11/17/18   jig wrote it

%% ---- Parse arguments for configuration settings
%
% Name of the experiment, which determines where data are are stored
name = 'DBSStudy';

% Other defaults
settings = { ...
   'taskSpecs',                  {'VGS' 1 'MGS' 1}, ... %'NN' 1 'Quest' 1 'AN' 1 'SN' 1 'NL' 1 'NR' 1}, ...
   'runGUIname',                 'eyeGUI', ...
   'databaseGUIname',            [], ...
   'remoteDrawing',              false, ...
   'instructionDuration',        1.0, ...
   'displayIndex',               0, ... % 0=small, 1=main
   'readables',                  {'dotsReadableHIDKeyboard'}, ...
   'doCalibration',              true, ...
   'doRecording',                true, ...
   'queryDuringCalibration',     false, ...
   'sendTTLs',                   false, ...
   'targetDistance',             10, ...
   'gazeWindowSize',             6, ...
   'gazeWindowDuration',         0.15, ...
   'saccadeDirections',          0:90:270, ...
   'dotDirections',              [0 180], ...
   'referenceRT',                500, ... % for speed feedback   
   'showFeedback',               true, ...   % for graphical feedback
   };

% Update from argument list (property/value pairs)
for ii = 1:2:nargin
   settings{find(strcmp(varargin{ii}, settings),1) + 1} = varargin{ii+1};
end

%% ---- Create topsTreeNodeTopNode to control the experiment
%
% Make the topsTreeNodeTopNode
topNode = topsTreeNodeTopNode(name);

% Add a topsGroupedList as the nodeData, which here just stores the
% property/value "settings" we use to control task behaviors
topNode.nodeData = topsGroupedList.createGroupFromList('Settings', settings);

% Add GUIS. The first is the "run gui" that has some buttons to start/stop
% running and some real-time output of eye position. The "database gui" is
% a series of dialogs that execute at the beginning to collect subject/task
% information and store it in a standard format.
topNode.addGUIs('run', topNode.nodeData{'Settings'}{'runGUIname'}, ...
   'database', topNode.nodeData{'Settings'}{'databaseGUIname'});

% Add the screen ensemble as a "helper" object. See
% topsTaskHelperScreenEnsemble for details
topNode.addHelpers('screenEnsemble',  ...
   topNode.nodeData{'Settings'}{'displayIndex'}, ...
   topNode.nodeData{'Settings'}{'remoteDrawing'}, ...
   topNode);

% Add a basic feedback helper object, which includes text, images, 
% and sounds. See topsTaskHelperFeedback for details.
topNode.addHelpers('feedback');

% Add readable(s). See topsTaskHelperReadable for details.
readables = topNode.nodeData{'Settings'}{'readables'};
for ii = 1:length(readables)
   topNode.addHelpers('readable', readables{ii}, topNode);
   
   % Possibly set default gaze window size, duration
   if isa(topNode.helpers.(readables{ii}).theObject, 'dotsReadableEye')
      topNode.helpers.(readables{ii}).theObject.setGazeWindows( ...
         topNode.nodeData{'Settings'}{'gazeWindowSize'}, ...
         topNode.nodeData{'Settings'}{'gazeWindowDuration'});
   end         
end

% Add writable (TTL out). See topsTaskHelperTTL for details.
if topNode.nodeData{'Settings'}{'sendTTLs'}
   topNode.addHelpers('TTL');
end

%% ---- Make call lists to show text/images between tasks
%
%  Use the sharedHelper screenEnsemble
%
% Welcome call list
paceStr = 'Work at your own pace.';
strs = { ...
   'dotsReadableEye',         paceStr, 'Each trial starts by fixating the central cross.'; ...
   'dotsReadableHIDGamepad',  paceStr, 'Each trial starts by pulling either trigger.'; ...
   'dotsReadableHIDButtons',  paceStr, 'Each trial starts by pushing either button.'; ...
   'dotsReadableHIDKeyboard', paceStr, 'Each trial starts by pressing the space bar.'; ...
   'default',                 'Each trial starts automatically.', ''};
for index = 1:size(strs,1)
   if ~isempty(topNode.getHelperByClassName(strs{index,1}))
      break;
   end
end
welcome = {@show, topNode.helpers.feedback, 'text', strs(index, 2:3), ...
   'showDuration', topNode.nodeData{'Settings'}{'instructionDuration'}};

% Countdown call list
callStrings = cell(10, 1);
for ii = 1:10
   callStrings{ii} = {'string', sprintf('Next task starts in: %d', 10-ii+1), 'y', -9};
end
countdown = {@showMultiple, topNode.helpers.feedback, ...
   'text', callStrings, 'image', {2, 'y', 4, 'height', 13}, ...
   'showDuration', 1.0, 'pauseDuration', 0.0, 'blank', false};

%% ---- Loop through the task specs array, making tasks with appropriate arg lists
%
taskSpecs = topNode.nodeData{'Settings'}{'taskSpecs'};
QuestTask = [];
noDots    = true;
for ii = 1:2:length(taskSpecs)
   
   % Make list of properties to send
   args = {taskSpecs{ii:ii+1}, ...
      {'settings', 'targetDistance'},   topNode.nodeData{'Settings'}{'targetDistance'}, ...
      {'timing',   'showInstructions'}, topNode.nodeData{'Settings'}{'instructionDuration'}, ...
      'taskID',                         (ii+1)/2, ...
      'taskTypeID',  find(strcmp(taskSpecs{ii}, {'VGS' 'MGS' 'Quest' 'NN' 'NL' 'NR' 'SN' 'SL' 'SR' 'AN' 'AL' 'AR'}),1)};
   
   switch taskSpecs{ii}
      
      case {'VGS' 'MGS'}
         
         % Make Saccade task with args
         task = topsTreeNodeTaskSaccade.getStandardConfiguration(args{:});
         task.setIndependentVariableByName('direction', 'value', ...
            topNode.nodeData{'Settings'}{'saccadeDirections'});
         
      otherwise
         
         % If there was a Quest task, use to update coherences in other tasks
         if ~isempty(QuestTask)
            args = cat(2, args, ...
               {{'settings' 'useQuest'},   QuestTask, ...
               {'settings' 'referenceRT'}, QuestTask});
         end
         
         % Make RTDots task with args
         task = topsTreeNodeTaskRTDots.getStandardConfiguration(args{:});
         task.setIndependentVariableByName('direction', 'value', ...
            topNode.nodeData{'Settings'}{'dotDirections'});
         
         % Add special instructions for first dots task
         if noDots
            task.settings.textStrings = cat(1, ...
               {'When flickering dots appear, decide their overall direction', ...
               'of motion, then look at the target in that direction'}, ...
               task.settings.textStrings);
            noDots = false;
         end
         
         % Special case of quest ... use output as coh/RT refs
         if strcmp(taskSpecs{ii}, 'Quest')
            QuestTask = task;
         end
   end
   
   % Add some fevalables to show instructions/feedback before/after tasks
   if ii == 1
      task.addCall('start', welcome);
   else
      task.addCall('start', countdown);
   end
   
   % Add as child to the maintask.
   topNode.addChild(task);
end
