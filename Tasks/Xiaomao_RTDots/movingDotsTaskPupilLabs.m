function state = movingDotsTaskPupilLabs
% state = movingDotsTaskEyelink
% 
% This function runs the actual experiment. This is a combination of the
% functions that do the coherence task and the SAT/BIAS task because both
% should be run in the pre-op session. Therefore, it would be easier to
% have just one file that does the entire experiment, with appropriate
% flags that control which stimuli get presented. This script uses the
% topsStateMachine to control the flow of the experiment.
%
% Outputs:
%   state  -  A topsGroupedList object containing experimental parameters
%             as well as data recorded during the experiment.
%
% 10/2/17    xd  wrote it

%% Create a topsGroupedList
%
% This is a versatile data structure that will allow us to pass the state
% of the state machine around as it advances.
state = topsGroupedList();

%% Experimental logic flags
%
% A series of logic flags will be used to control which stimuli are
% presented during the experiment. These flags determine which states the
% state machine is allowed to enter. Note that if all flags are set to
% true, the order of will be QUEST -> meanRT -> coherence -> SAT/BIAS.
% Disabling any part will not change the relative order of the presentation
% of the different experimental stages.

state{'Flag'}{'QUEST'} = true;
state{'Flag'}{'meanRT'} = false;
state{'Flag'}{'coherence'} = false;
state{'Flag'}{'SAT/BIAS'} = false;

%% Create timing parameters
%
% These pararmeters determine how long different parts of the task
% presentation should take. These are kept the same across trials. All
% fields values are in seconds.

state{'Timing'}{'meanFixationCueAndSaccadeTargets'} = 0.5;
state{'Timing'}{'maxFCandST'} = 1.25;
state{'Timing'}{'feedback'} = 0.65;
state{'Timing'}{'rest'} = 0.5;
state{'Timing'}{'fixationCueFixationDuration'} = 0.200;
state{'Timing'}{'targetFixationDuration'} = 0.125;
state{'Timing'}{'pauseForTargetFixation'} = 0.125;
state{'Timing'}{'instructionPresentation'} = 5;
state{'Timing'}{'speedContextTemporalThreshold'} = 1;

%% General Stimulus Params
%
% These parameters are shared across the different types of stimulus. These
% essentially dictate things like size of stimulus and location on screen.

% Size of the fixation cue in dva. Additionally, we will want to store the
% pixel coordinates for the center of the screen to use in comparisons with
% Eyelink samples later.
state{'FixationCue'}{'size'} = 5/2;
state{'FixationCue'}{'xDVA'} = 0;
state{'FixationCue'}{'yDVA'} = 0;

% Position (horizontal distance from center of screen) and size of the
% saccade targets in dva. Similar to the fixation cue, we also want to
% store the pixel positions for these.
state{'SaccadeTarget'}{'offset'} = 10;
state{'SaccadeTarget'}{'size'}   = 3/2;
state{'SaccadeTarget'}{'rightXDVA'} = state{'FixationCue'}{'xDVA'} + state{'SaccadeTarget'}{'offset'};
state{'SaccadeTarget'}{'leftXDVA'}  = state{'FixationCue'}{'xDVA'} - state{'SaccadeTarget'}{'offset'};
state{'SaccadeTarget'}{'rightYDVA'} = state{'FixationCue'}{'yDVA'};
state{'SaccadeTarget'}{'leftYDVA'}  = state{'FixationCue'}{'yDVA'};

% Parameters for the moving dots stimuli that will be shared across every
% trial. Also store the pixel position for the center of the stimuli.
state{'MovingDots'}{'stencilNumber'} = 1;
state{'MovingDots'}{'pixelSize'} = 6;
state{'MovingDots'}{'diameter'} = 10;
state{'MovingDots'}{'density'} = 150;
state{'MovingDots'}{'speed'} = 3;
state{'MovingDots'}{'xDVA'} = 0;
state{'MovingDots'}{'yDVA'} = 0;

%% QUEST
% 
% These parameters control how the QUEST adaptive threshold measurements
% behave. The parameters are fed into the QUEST function that comes with
% psychtoolbox. See that function for more details.

stimRange = 0:1:100;
thresholdRange = 0:50;
slopeRange = 2:5;
guessRate = 0.5;
lapseRange = 0.00:0.01:0.05;

state{'Quest'}{'numTrials'} = 40;   % Target number of trials
state{'Quest'}{'counter'} = 1;      % Current QUEST trial
questData = qpParams('stimParamsDomainList',{[stimRange]}, ...
    'psiParamsDomainList',{thresholdRange, slopeRange, guessRate, lapseRange});
state{'Quest'}{'object'}  = qpInitialize(questData);
state{'Quest'}{'results'} = cell(state{'Quest'}{'numTrials'},1);

%% Mean RT
%
% For the SAT/BIAS condition, we may also need to find out the mean RT of
% the subject to the threshold coherence (if this value is not known
% already). The parameters in this section allows us to either set the mean
% RT or to set how many trials it should take to determine the mean RT.
state{'MeanRT'}{'value'} = 0.85;
state{'MeanRT'}{'numTrials'} = 20;
state{'MeanRT'}{'counter'} = 1;

%% Coherence

% We define some parameters that describe the task. Note that each
% coherence level must have the same number of left and right stimuli.
% Therefore, the total number of trials is the number of coherence levels *
% trialsPerCoherencePerDirection * 2. The stimulus is hardcoded to appear
% at the center of the screen.
state{'Coherence'}{'coherences'} = [0 3.2 6.4 12.8 25.6 51.2];
state{'Coherence'}{'trialsPerCoherencePerDirection'} = 15;
state{'Coherence'}{'counter'} = 1;
state{'Coherence'}{'numTrials'} = length(state{'Coherence'}{'coherences'}) * state{'Coherence'}{'trialsPerCoherencePerDirection'} * 2;

%% SAT/BIAS

% We define some parameters that describe the task. There are four stimulus
% contexts that each appear twice with 30 trials. This means that the total
% number of trials will be 240. The stimulus is hardcoded to appear at the
% center of the screen.
state{'SAT/BIAS'}{'trialsPerContext'} = 30;
state{'SAT/BIAS'}{'coherenceThreshold'} = 2;
state{'SAT/BIAS'}{'useQuestThreshold'} = state{'Flag'}{'QUEST'};
state{'SAT/BIAS'}{'counter'} = 1;
state{'SAT/BIAS'}{'contextCounter'} = 1;
% state{'SAT/BIAS'}{'contextTrialCounter'} = 1;
state{'SAT/BIAS'}{'contextSwitch'} = true;

% We create the contexts by shuffling a list of SAT and a list of BIAS
% trial markers. Then, we zip them together so that the subject is always
% following a SAT-BIAS sequence. T1 refers to left, and T2 refers to right.
SATList  = {'S' 'A' 'S' 'A'};
BIASList = {'T1' 'T2' 'T1' 'T2'};
contexts = cell(length(SATList) + length(BIASList),1);
contexts(1:2:end) = SATList(randperm(length(SATList)));
contexts(2:2:end) = BIASList(randperm(length(BIASList)));
state{'SAT/BIAS'}{'contexts'} = contexts;
state{'SAT/BIAS'}{'numContexts'} = length(contexts);
state{'SAT/BIAS'}{'numTrials'} = state{'SAT/BIAS'}{'numContexts'} * state{'SAT/BIAS'}{'trialsPerContext'};
state{'SAT/BIAS'}{'trials'} = cell(state{'SAT/BIAS'}{'numTrials'},1);

%% PupilLabs

% These values represent the radius of acceptible error of fixation for
% subjects to make for each part of the trial. Units are in degrees visual
% angle.
acceptibleFixationCueErrorRadius = 8;
acceptibleSaccadeTargetErrorRadius = 10;
acceptibleStimulusErrorRadius = 8;

state{'PupilLabs'}{'fixationCueErrorRad2'} = acceptibleFixationCueErrorRadius^2;
state{'PupilLabs'}{'saccadeTargetErrorRad2'} = acceptibleSaccadeTargetErrorRadius^2;
state{'PupilLabs'}{'stimulusErrorRad2'} = acceptibleStimulusErrorRadius^2;

%% Remote control
clientIP = '158.130.221.199';
clientPort = 30000;
serverIP = '158.130.217.154';
serverPort = 30001;

state{'Remote'}{'clientIP'} = clientIP;
state{'Remote'}{'clientPort'} = clientPort;
state{'Remote'}{'serverIP'} = serverIP;
state{'Remote'}{'serverPort'} = serverPort;

sc.windowRect = [0 0 1920 1080];
ui = dotsReadableEyePupilLabs();
ui.calibratePupilLab(sc,clientIP,clientPort,serverIP,serverPort);
ui.calibrateSnowDots(clientIP,clientPort,serverIP,serverPort);
state{'Remote'}{'ui'} = ui;

% mPupilLabs.init();
% mPupilLabs.calibrate(sc,clientIP,clientPort,serverIP,serverPort);
% calibrateSnowdotsToPupilLabs(clientIP,clientPort,serverIP,serverPort);

%% Graphics
%
% We will also pregenerate and store the graphics objects in the state
% topsGroupedList object. This will allow us to quickly gather the frames
% that need to be presented during the experiment. These basic frames are
% created in an external function so that the code organization is a bit
% easier to follow.
createBasicMovingDotsStimulusFrames(state);
addStimulusFramesForSAT(state);

%% Generate trials
%
% We generate all the trials ahead of time (the coherence and direction of
% each trial to be presented). This is so that we can guarantee an exact
% distribution of trials with stimulus going to the left and the right.
% Normally, doing this during the experiment would be 'OK' but because we
% are limited for trials due the time constraints in the operating room, we
% will enforce a strict adherence to percent.
createMeanRTTrials(state);
createContextTrials(state);
createCoherenceTrials(state);
createQuestTrials(state);

%% State machine
%
% We will define the list of fixed states that defines the transitions
% between each state during the experiment.

% The following functions check which part of the experiment we are on and
% direct the state machine to the appropriate functions based on flags set
% initially as well as flags updated by the program.
checkQuest = {@checkFlag state 'QUEST' {'prepareQuestStimulus' 'checkRT'}};
checkMeanRT = {@checkFlag state 'meanRT' {'prepareMeanRTStimulus' 'checkCoherence'}};
checkCoherence = {@checkFlag state 'coherence' {'prepareCoherenceStimulus' 'checkSATBIAS'}};
checkSATBIAS = {@checkFlag state 'SAT/BIAS' {'prepareSATBIASStimulus' ''}};

% These function load the next stimulus to be presented based on the
% current part of the experiment we are on.
prepareMeanRT = {@prepareStimulus state 'MeanRT'};
prepareCoherence = {@prepareStimulus state 'Coherence'};
prepareSATBIAS = {@prepareStimulus state 'SAT/BIAS'};

% Define the state machine and transitions
fixedStates = {...
    'name'                     'entry'                             'input'                   'next'                ; ...
    'checkQuest'               {}                                  checkQuest                ''                    ; ...
    'checkRT'                  {}                                  checkMeanRT               ''                    ; ...
    'checkCoherence'           {}                                  checkCoherence            ''                    ; ...
    'checkSATBIAS'             {}                                  checkSATBIAS              ''                    ; ...
    'prepareQuestStimulus'     {@prepareQuestStimulus state}       {}                        'presentInstructions' ; ... 
    'prepareMeanRTStimulus'    prepareMeanRT                       {}                        'presentInstructions' ; ...
    'prepareCoherenceStimulus' prepareCoherence                    {}                        'presentInstructions' ; ...
    'prepareSATBIASStimulus'   prepareSATBIAS                      {}                        'presentInstructions' ; ...
    'presentInstructions'      {@presentContextInstructions state} {}                        'presentFixationCue'  ; ...
    'presentFixationCue'       {@presentFixationCue state}         {}                        'presentStimulus'     ; ...
    'presentStimulus'          {}                                  {@presentStimulus state}  ''                    ; ...
    'intime'                   {@presentInTime state}              {}                        'finishTrial'         ; ... 
    'slow'                     {@presentSlow state}                {}                        'finishTrial'         ; ...
    'correct'                  {@presentCorrect state}             {}                        'finishTrial'         ; ...
    'incorrect'                {@presentIncorrect state}           {}                        'finishTrial'         ; ...
    'invalid'                  {@presentInvalid state}             {}                        'finishTrial'         ; ...    
    'finishTrial'              {}                                  {@finishTrial state}      ''                    ; ...
    'updateQuestState'         {@updateQuestState state}           {}                        ''                    ; ...
    'updateMeanRTState'        {@updateMeanRTState state}          {}                        ''                    ; ...
    'updateCoherenceState'     {@updateCoherenceState state}       {}                        ''                    ; ...
    'updateContextState'       {@updateContextState state}         {}                        ''                    };

% Put stuff together so that it will run
stateMachine = topsStateMachine();
stateMachine.addMultipleStates(fixedStates);

maintask = topsTreeNode();
maintask.iterations = state{'Quest'}{'numTrials'} * state{'Flag'}{'QUEST'} + ...
                      state{'MeanRT'}{'numTrials'} * state{'Flag'}{'meanRT'} + ...
                      state{'Coherence'}{'numTrials'} * state{'Flag'}{'coherence'} + ...
                      state{'SAT/BIAS'}{'numTrials'} * state{'Flag'}{'SAT/BIAS'};
% maintask.iterations = 5;
maintask.addChild(stateMachine);

maintask.run();
% dotsTheScreen.closeWindow();

end

