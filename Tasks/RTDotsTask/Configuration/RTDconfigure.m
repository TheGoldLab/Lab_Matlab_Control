function [datatub, maintask] = RTDconfigure(varargin)
% function [datatub, maintask] = RTDconfigure(varargin)
%
% RTD = Response-Time Dots
%
% Configure the RTD experiment, which consists of a combination of 
%  multiple different tasks:
%  1. Quest             - Adaptive procedure to determine psychophysical 
%                          threshold for coherence
%  2. MeanRT            - Determine mean RT for speed-accuracy trade-off 
%                          (SAT) feedback
%  3. test              - RT dots with SAT and bias manipulations. see
%                          blockSpects below for details
%
% Inputs are property/value pairs:
%  'coherences'   - coherences to use in non-Quest blocks. If Quest
%                     is used, this is overridedn
%  'directions'   - dot directions 
%  'biasedPriors' - priors to use in BIAS blocks
%  'referenceRT'  - scalar value (in sec) to use as reference for feeback 
%                    on 'speed' trials. If none given, computed from 
%                    Quest or meanRT block
%  'taskSpecs'    - cell array that defines the tasks. Each pair is:
%                     1 : Task name, which can be 'Quest', 'meanRT', or
%                         a pair of keys: 
%                           <SAT instruction key, 'S'=Speed, 'A'=Accuracy,
%                                'N'=Neutral, 'X'=None>
%                           <BIAS stimulus key, 'L'=More left, 
%                                'R'=More right, 'N'=Neutral>
%                     2 : <number of trials>
%  'useEyeTracking', - flag if eye tracking (pupil labs) is used
%  'gazeWindowSize', - standard size of gaze window, in degrees vis angle
%  'gazeWindowDur',  - standard duration for gaze window (gaze holding time)
%  'sendTTLs'     - flag, set to true to send TTL pulses via the PMD
%  'useRemote'    - true or false. If true, use RTDconfigureIPs to set
%                          communication parameters
%  'displayIndex' - see dotsTheScreen (0:small window; 1=main window;
%                          2:secondary window)
%  'filePath'     - <string> where to put the data files
%  'fileName'     - <string> name. Note that when pupil labs is used,
%                          a second file is created with name
%                          <filename>_pupil
%
% Outputs:
%   datatub             -  A topsGroupedList object containing experimental 
%                          parameters as well as data recorded during the 
%                          experiment.
%   maintask            - the topsTreeNode object to run
%
% 5/11/18   updated by jig
% 10/2/17   xd wrote it

%% ---- Create a topsGroupedList
%
% This is a versatile data structure that will allow us to pass the state
% of the state machine around as it advances.
datatub = topsGroupedList();

%% ---- Make machine-specific data file path
[~,machineName] = system('scutil --get ComputerName');
switch deblank(machineName)
    case {'GoldLabMacbookPro'}
        filePath = '/Users/lab/ActiveFiles/Data/RTDdata';
    case {'LabMacMini'}
        filePath = '/Users/neurosurgery/ActiveFiles/Data/RTDdata';
    otherwise
        filePath = '/Users/jigold/GoldWorks/Local/Data/Projects/RTDots';
end

%% ---- Parse arguments
c = clock;
defaultArguments = { ...
   'coherences',           [0 3.2 6.4 12.8 25.6 51.2]; ...
   'directions',           [0 180]; ...
   'biasedPriors',         [20 80]; ...
   'referenceRT',          nan; ...
   'trialsPerCoherence',   40; ....
   'taskSpecs',            {'Quest', 40, 'meanRT', 20, 'SN' 20 'AN' 20}; ...
   'useEyeTracking',       true; ...
   'gazeWindowSize',       4; ...
   'gazeWindowDur',        0.2; ...
   'sendTTLs',             false; ...
   'useRemote',            false; ...
   'displayIndex',         1; ...
   'filePath',             filePath; ...
   'fileName',             sprintf('data_%.4d_%02d_%02d_%02d_%02d.mat', c(1), c(2), c(3), c(4), c(5)); ...
   };

% Arguments are property/value pairs
for ii = 1:2:nargin
   defaultArguments{strcmp(varargin{ii}, defaultArguments(:,1)),2} = varargin{ii+1};
end

% Save to state list
for ii = 1:size(defaultArguments, 1)
   datatub{'Input'}{defaultArguments{ii,1}} = defaultArguments{ii,2};
end

%% ---- Timing parameters
% These pararmeters determine how long different parts of the task
% presentation should take. These are kept the same across trials. All
% fields values are in seconds.
datatub{'Timing'}{'showInstructions'} = 3;
datatub{'Timing'}{'waitAfterInstructions'} = 1;
datatub{'Timing'}{'fixationTimeout'} = 5;
datatub{'Timing'}{'holdFixation'} = 0.5;
datatub{'Timing'}{'showTargetForeperiodMin'} = 0.2;
datatub{'Timing'}{'showTargetForeperiodMax'} = 1.0;
datatub{'Timing'}{'showTargetForeperiodMean'} = 0.5;
datatub{'Timing'}{'dotsTimeout'} = 5;
datatub{'Timing'}{'showFeedback'} = 1;
datatub{'Timing'}{'InterTrialInterval'} = 2.0;

%% ---- General Stimulus Params
%
% These parameters are shared across the different types of stimulus. These
% essentially dictate things like size of stimulus and location on screen.

% Size of the fixation cue in dva. Additionally, we will want to store the
% pixel coordinates for the center of the screen to use in comparisons with
% Eyelink samples later.
datatub{'FixationCue'}{'size'} = 1;
datatub{'FixationCue'}{'xDVA'} = 0;
datatub{'FixationCue'}{'yDVA'} = 0;

% Position (horizontal distance from center of screen) and size of the
% saccade targets in dva. Similar to the fixation cue, we also want to
% store the pixel positions for these.
datatub{'SaccadeTarget'}{'offset'} = 10;
datatub{'SaccadeTarget'}{'size'}   = 1.5;

% Parameters for the moving dots stimuli that will be shared across every
% trial. Also store the pixel position for the center of the stimuli.
datatub{'MovingDots'}{'stencilNumber'} = 1;
datatub{'MovingDots'}{'pixelSize'} = 6;
datatub{'MovingDots'}{'diameter'} = 8;
datatub{'MovingDots'}{'density'} = 150;
datatub{'MovingDots'}{'speed'} = 3;
datatub{'MovingDots'}{'xDVA'} = 0;
datatub{'MovingDots'}{'yDVA'} = 0;

% Vertical position of instructions/feedback text
datatub{'Text'}{'yPosition'} = 4;

%% ---- TTL Output (to sync with neural data acquisition system)
if datatub{'Input'}{'sendTTLs'}
   datatub{'dOut'}{'dOutObject'} = dotsDOut1208FS;
   datatub{'dOut'}{'timeBetweenTTLPulses'} = 0.001; % in sec
end

%% ---- Configure Graphics
%
% First check for local/remote graphics
if datatub{'Input'}{'useRemote'}
   [clientIP, clientPort, serverIP, serverPort] = RTDconfigureIPs;
   datatub{'Input'}{'remoteInfo'} = { ...
      true, clientIP, clientPort, serverIP, serverPort};
else
   datatub{'Input'}{'remoteInfo'} = {false};
end
   
% Set up graphics objects
RTDconfigureGraphics(datatub);

%% ---- Configure User input : pupil labs or keyboard
RTDconfigureUI(datatub);

%% ---- Configure State Machine
RTDconfigureStateMachine(datatub);

%% ---- Configure Tasks
% Set up the main tree node and save it
maintask = topsTreeNode('dotsTask');
maintask.iterations = 1; % Go once through the set of tasks
%maintask.startFevalable = {@callObjectMethod, datatub{'Graphics'}{'screenEnsemble'}, @open};
%maintask.finishFevalable = {@callObjectMethod, datatub{'Graphics'}{'screenEnsemble'}, @close};
datatub{'Control'}{'mainTask'} = maintask;

% Add tasks to the main tree node. Here they all use the same stateMachine,
% but in general that does not have to be the case
RTDconfigureTasks(maintask, datatub);

%% ---- Configure Data logging
topsDataLog.flushAllData(); % Flush stale data, just in case
topsDataLog.logDataInGroup(struct(datatub), 'datatub');
topsDataLog.writeDataFile(fullfile(datatub{'Input'}{'filePath'}, datatub{'Input'}{'fileName'}));
topsDataLog.flushAllData(); % Flush again to keep memory demands low

end