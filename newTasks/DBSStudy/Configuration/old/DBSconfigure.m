function DBSconfigure(maintask, datatub, varargin)
% function DBSconfigure(maintask, datatub, varargin)
%
% Configure a DBS experiment, which consists of a combination of
%  multiple topsTreeNodeTaskRTDots and topsTreeNodeTaskSaccade tasks
%
% Inputs:
%   datatub       -  A topsGroupedList object containing experimental
%                    parameters as well as data recorded during the
%                    experiment.
%   maintask      - the topsTreeNode object to run
%
%  plus varargin, which are property/value pairs:
%
%  'coherences'      - coherences to use in non-Quest blocks. If Quest
%                       is used, this is overridedn
%  'dotDirections'   - dot directions
%  'biasedPriors'    - priors to use in BIAS blocks
%  'referenceRT'     - scalar value (in sec) to use as reference for feeback
%                       on 'speed' trials. If none given, computed from
%                       Quest or meanRT block
%  'taskSpecs'       - cell array that defines the tasks. Each pair is:
%                       1 : Task name, which can be 'Quest', 'meanRT', or
%                         a pair of keys:
%                           <SAT instruction key>:
%                             'S'=Speed, 'A'=Accuracy, 'N'=Neutral
%                           <BIAS stimulus key>:
%                             'L'=More left, 'R'=More right, 'N'=Neutral
%                       2 : <number of trials>
%  'uiDevice',        - string name of dotsReadable* class to use for
%                       choice input
%  'fixWindowSize',   - diameter of fixation gaze window, in degrees vis angle
%  'targetWindowSize', - diameter of target gaze window, in degrees vis angle
%  'fixWindowDur',    - duration for fix window (gaze holding time), in sec
%  'trgWindowDur',    - duration for target window (gaze holding time), in sec
%  'sendTTLs'         - flag, set to true to send TTL pulses via the PMD
%  'useRemoteDrawing' - true or false. If true, use RTDconfigureIPs to set
%                          communication parameters
%  'displayIndex'      - see dotsTheScreen (0:small window; 1=main window;
%                          2:secondary window)
%  'filePath'          - <string> where to put the data files
%  'fileName'          - <string> name. Note that when pupil labs is used,
%                          a second file is created with name
%                          <filename>_pupil
%
% 5/28/18   written by jig

%% ---- Parse arguments
c = clock;
defaultArguments = { ...
   'taskSpecs',            {'Quest', 40, 'SN' 20 'AN' 20}; ...
   'coherences',           [0 3.2 6.4 12.8 25.6 51.2]; ...
   'dotDirections',        [0 180]; ...
   'biasedPriors',         [20 80]; ...
   'referenceRT',          nan; ...
   'trialsPerCoherence',   40; ....
   'saccadeDirections',    0:90:270; ... %0:45:315; ...
   'targetDistance',       8; ...
   'trialsPerDirection',   4; ...
   'uiDevice',             'dotsReadableEyePupilLabs'; ...
   'fixWindowSize',        3; ...
   'fixWindowDur',         0.02; ...
   'trgWindowSize',        4; ...
   'trgWindowDur',         0.02; ...
   'sendTTLs',             false; ...
   'useRemoteDrawing',     true; ...
   'displayIndex',         1; ...
   'filePath',             DBSfilepath(); ...
   'fileName',             sprintf('data_%.4d_%02d_%02d_%02d_%02d.mat', c(1), c(2), c(3), c(4), c(5)); ...
   };

% Arguments are property/value pairs
for ii = 1:2:nargin-2
   defaultArguments{strcmp(varargin{ii}, defaultArguments(:,1)),2} = varargin{ii+1};
end

% Save to state list
for ii = 1:size(defaultArguments, 1)
   datatub{'Input'}{defaultArguments{ii,1}} = defaultArguments{ii,2};
end

%% ---- Configure common drawables
DBSconfigureDrawables(datatub);

%% ---- Configure User input
DBSconfigureUserInput(datatub);

%% ---- Configure Tasks
DBSconfigureTasks(maintask, datatub);
