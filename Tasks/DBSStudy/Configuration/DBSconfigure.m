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

%  Default filename is based on the clock
c = clock;
filename = fullfile( ...
   dotsTheMachineConfiguration.getDefaultValue('dataPath'), name, 'Raw', ...
   sprintf('data_%.4d_%02d_%02d_%02d_%02d.mat', ...
   c(1), c(2), c(3), c(4), c(5)));

% Other defaults
settings = { ...
   'taskSpecs',                  {'VGS' 1 'NN' 1 'Quest' 1 'AN' 1 'SN' 1 'NL' 1 'NR' 1}, ...
   'runGUI',                     'eyeGUI', ...
   'subjectGUI',                 [], ...
   'useRemoteDrawing',           true, ...
   'instructionDuration',        10, ...
   'displayIndex',               1, ... % 0=small, 1=main
   'userInput',                  'dotsReadableEyePupilLabs', ...
   'filename',                   filename, ...
   'sendTTLs',                   false, ...
   'targetDistance',             8, ...
   'fixWindowSize',              6, ...
   'fixWindowDur',               0.15, ...
   'trgWindowSize',              6, ...
   'trgWindowDur',               0.15, ...   
   'saccadeDirections',          0:90:270, ...
   'referenceRT',                500, ... % for speed feedback
   'coherences',                 [0 3.2 6.4 12.8 25.6 51.2], ...
   };

% Update from argument list (property/value pairs)
for ii = 1:2:nargin
   settings{find(strcmp(varargin{ii}, settings),1) + 1} = varargin{ii+1};
end

%% ---- Create topsCallLists for experiment start/finish fevalables
%
% Add a topsGroupedList as the nodeData, plus other fields
%
topNode = topsTreeNodeTopNode(name);
topNode.nodeData = topsGroupedList();
topNode.nodeData.makeGroupFromList('Settings', settings);
topNode.filename        = topNode.nodeData{'Settings'}{'filename'};
topNode.databaseGUIname = topNode.nodeData{'Settings'}{'subjectGUI'};
topNode.runGUIname      = topNode.nodeData{'Settings'}{'runGUI'};

%% ---- Configure elements
%
% Done in separate files for readability
DBSconfigureDrawables(topNode);
DBSconfigureReadables(topNode);
DBSconfigureTasks(topNode);
