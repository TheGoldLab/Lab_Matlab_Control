function [tree, list] = configurePredInf2011(logic, av, options)
% Configure Snow Dots for Matt Nassar's Predictive Inference task.
%
% Ben Heasly created configurePredInf2011 in 2011, based on Matt Nassar's
% configurePredInfTask from 2010.
%

if nargin < 1 || isempty(logic)
    logic = PredInfLogic();
end

if nargin < 2 || isempty(av)
    av = PredInfAV();
    av.logic = logic;
end

if nargin < 3 || isempty(options) || ~isstruct(options)
    options.isKeyboardTrigger = false;
    options.triggerKeyName = 'KeyboardT';
    options.triggerMaxWait = 5*60;
    options.isPositionMapping = false;
    options.isBucketPickup = false;
    options.bucketPickupRange = [1 1]*logic.maxOutcome;
end

if ~isfield(options, 'keyboardKeys')
    options.keyboardKeys.left = 'KeyboardF';
    options.keyboardKeys.right = 'KeyboardJ';
    options.keyboardKeys.leftFine = 'KeyboardG';
    options.keyboardKeys.rightFine = 'KeyboardH';
    options.keyboardKeys.commit = 'KeyboardSpacebar';
    options.keyboardKeys.info = 'KeyboardI';
    options.keyboardKeys.abort = 'KeyboardQ';
end

if ~isfield(options, 'gamepadButtons')
    options.gamepadButtons.leftFine = 5;
    options.gamepadButtons.rightFine = 6;
    options.gamepadButtons.commit = 1;
    options.gamepadButtons.info = 3;
    options.gamepadButtons.abort = 4;
end

if ~isfield(options, 'eyeTracker')
    options.eyeTracker.isEyeTracking = false;
    options.eyeTracker.inputRect = [-13.49 10.95 13.49.*2 -10.95.*2]*100;
    options.eyeTracker.xyRect = [-12 -10 24 20];
    options.eyeTracker.sampleFrequency = 120;
    options.eyeTracker.fixWindow = [-4.5 -4.5 9 9];
end

if ~isfield(options, 'gamepadCalibration')
    options.gamepadCalibration = {[], [], [-1, +1]};
end

% prepare to record flow of control data
topsDataLog.flushAllData();
[dataPath, dataName, dataExt] = fileparts(logic.dataFileName);
if isempty(dataPath)
    dataPath = dotsTheMachineConfiguration.getDefaultValue('dataPath');
end
logName = sprintf('%s-topsDataLog.mat', dataName);
logFullFile = fullfile(dataPath, logName);
topsDataLog.writeDataFile(logFullFile);


%% Make a container for all kinds of data and objects
list = topsGroupedList();
list{'logic'}{'object'} = logic;
list{'audio-visual'}{'object'} = av;
list{'options'}{'struct'} = options;

% allocate space for trial-by-trial data
[statusData payoutData] = logic.getDataArrays();
list{'logic'}{'statusData'} = statusData;
list{'logic'}{'payoutData'} = payoutData;

%% Try for a gamepad, fall back on the keyboard
gp = dotsReadableHIDGamepad();
if gp.isAvailable
    ui = gp;
    
    % map x-axis -1 to left and +1 to right
    %   these can be held down
    isX = strcmp({gp.components.name}, 'x');
    xAxis = gp.components(isX);
    uiMap.left.ID = xAxis.ID;
    uiMap.right.ID = xAxis.ID;
    gp.setComponentCalibration(xAxis.ID, options.gamepadCalibration{:});
    
    % should game pad axis map to prediction speed or position?
    uiMap.isPositionMapping = options.isPositionMapping;
    
    % assign button events by named fields and numbers
    %   these fire once, even if held down
    buttons = options.gamepadButtons;
    names = fieldnames(buttons);
    for ii = 1:numel(names)
        name = names{ii};
        number = buttons.(name);
        isButton = [gp.components.ID] == gp.buttonIDs(number);
        button = gp.components(isButton);
        gp.defineEvent(button.ID, name, button.CalibrationMax);
    end
    
else
    kb = dotsReadableHIDKeyboard();
    ui = kb;
    
    % map keys.left=-1 to left keys.right=+1 to right
    %   these can be held down
    keys = options.keyboardKeys;
    keyNames = {kb.components.name};
    isKey = strcmp(keyNames, keys.left);
    keyName = kb.components(isKey);
    uiMap.left.ID = keyName.ID;
    kb.setComponentCalibration(keyName.ID, [], [], [0 -1]);
    
    isKey = strcmp(keyNames, keys.right);
    keyName = kb.components(isKey);
    uiMap.right.ID = keyName.ID;
    kb.setComponentCalibration(keyName.ID, [], [], [0 +1]);
    
    % keyName presses map to prediction speed, not position position.
    uiMap.isPositionMapping = false;
    
    % undefine default keypress events
    IDs = kb.getComponentIDs();
    for ii = 1:numel(IDs)
        kb.undefineEvent(IDs(ii));
    end
    
    % assign new keypress events by named fields and keyName names
    %   these fire once, even if held down
    names = fieldnames(keys);
    for ii = 1:numel(names)
        name = names{ii};
        keyName = keys.(name);
        isKey = strcmp(keyNames, keyName);
        keyName = kb.components(isKey);
        kb.defineEvent(keyName.ID, name, keyName.CalibrationMax);
    end
end
list{'input'}{'controller'} = ui;
list{'input'}{'mapping'} = uiMap;

%% Optionally set up an eye tracker
if options.eyeTracker.isEyeTracking
    et = dotsQueryableEyeASL();
    
    if et.isAvailable
        
        list{'input'}{'eye tracker'} = et;
        
        et.inputRect = options.eyeTracker.inputRect;
        et.xyRect = options.eyeTracker.xyRect;
        et.sampleFrequency = options.eyeTracker.sampleFrequency;
        et.initialize();
        
        % TODO: implement with topsClassification, coming soon
        % if et.openEyeTracker
        %     fixWindow = options.eyeTracker.fixWindow;
        %     temp = et.getPhenomenonTemplate;
        %     inBox = dotsPhenomenon.rectangle( ...
        %         temp, 'xPos', 'yPos', fixWindow, 'in');
        %     outBox = dotsPhenomenon.rectangle( ...
        %         temp, 'xPos', 'yPos', fixWindow, 'out');
        %
        %     et.addClassificationInGroupWithRank( ...
        %         inBox, 'outcome', 'acquire', 1);
        %     et.addClassificationInGroupWithRank( ...
        %         outBox, 'abort', 'hold', 1);
        
    else
        disp('Problem: eye tracker is unavailable');
        options.eyeTracker.isEyeTracking = false;
    end
else
    options.eyeTracker.isEyeTracking = false;
end

%% Outline the structure of the exeriment with topsRunnable objects
%   visualize the structure with tree.gui()
%   run the experiment with tree.run()

% "tree" is the start point for the whole experiment
tree = topsTreeNode('open/close screen');
tree.iterations = 1;
tree.startFevalable = {@initialize, av};
tree.finishFevalable = {@terminate, av};

% "instructions" is a branch of the tree with an instructional slide show
instructions = topsTreeNode('instructions');
instructions.iterations = 1;
tree.addChild(instructions);

viewSlides = topsConcurrentComposite('slide show');
viewSlides.startFevalable = {@flushData, ui};
viewSlides.finishFevalable = {@flushData, ui};
instructions.addChild(viewSlides);

instructionStates = topsStateMachine('instruction states');
viewSlides.addChild(instructionStates);

instructionCalls = topsCallList('instruction updates');
instructionCalls.alwaysRunning = true;
viewSlides.addChild(instructionCalls);

% "session" is a branch of the tree with the task itself
session = topsTreeNode('session');
session.iterations = logic.nBlocks;
session.startFevalable = {@startSession, logic};
tree.addChild(session);

% Must each block wait for a trigger signal?
if options.isKeyboardTrigger
    trigger = topsTreeNode('trigger');
    keyName = options.triggerKeyName;
    maxWait = options.triggerMaxWait;
    trigger.startFevalable = ...
        {@waitForKeyboardTrigger, keyName, maxWait, av};
    session.addChild(trigger);
end

block = topsTreeNode('block');
block.iterations = logic.trialsPerBlock;
block.startFevalable = {@startBlock, logic};
session.addChild(block);

trial = topsConcurrentComposite('trial');
block.addChild(trial);

trialStates = topsStateMachine('trial states');
trial.addChild(trialStates);

trialCalls = topsCallList('trial updates');
trialCalls.alwaysRunning = true;
trial.addChild(trialCalls);

% add concurrent objects that the av object uses, if any
avConcurrents = av.getConcurrents();
for ii = 1:numel(avConcurrents)
    trial.addChild(avConcurrents{ii});
end

feedback = topsConcurrentComposite('feedback');
session.addChild(feedback);

feedbackStates = topsStateMachine('feedback states');
feedback.addChild(feedbackStates);

feedbackCalls = topsCallList('feedback updates');
feedbackCalls.alwaysRunning = true;
feedback.addChild(feedbackCalls);

list{'outline'}{'tree'} = tree;

%% Organize the presentation of instructions
% the instructions state machine will respond to user input commands
states = { ...
    'name'      'next'      'timeout'	'entry'     'input'; ...
    'showSlide' ''          av.tIdle    {}          {@getNextEvent ui}; ...
    'rightFine' 'showSlide' 0           {@doNextInstruction av}	{}; ...
    'leftFine'  'showSlide' 0           {@doPreviousInstruction av} {}; ...
    'abort'     ''          0           {}          {}; ...
    };
instructionStates.addMultipleStates(states);
instructionStates.startFevalable = {@doPreviousInstruction av};
instructionStates.finishFevalable = {@doMessage av ''};

% the instructions call list runs in parallel with the state machine
instructionCalls.addCall({@read, ui}, 'input');

%% Organize the presentation of feedback following each block
% the feedback state machine will respond to user input commands
states = { ...
    'name'      'next'      'timeout'	'input'; ...
    'feedback'  ''          av.tIdle    {@getNextEvent ui}; ...
    'commit'    ''          0           {}; ...
    'abort'     ''          0           {}; ...
    };
feedbackStates.addMultipleStates(states);
feedbackStates.startFevalable = {@doFeedback av};
feedbackStates.finishFevalable = {@doMessage av ''};

% the feedback call list runs in parallel with the state machine
feedbackCalls.addCall({@read, ui}, 'input');

%% Organize the flow through each trial
% The trial state machine will respond to user input commands
%   and control timing.

% some behaviors depend on eye tracking vs. no eye tracking
if options.eyeTracker.isEyeTracking
    % subject must acquire fixation in order to fully commit
    %   the "acquire" group can return the state name "outcome"
    commitNext = 'commit';
    commitInput = {@queryAsOfTime, et, 'acquire'};
    
    % subject must hold fixation in order to complete the trial
    %   the "acquire" group can return the state name "abort"
    outcomeInput = {@queryAsOfTime, et, 'hold'};
    
    % need to check the eye tracker in parallel with everything else
    trialCalls.addCall({@readData, et}, 'eye input');
    
else
    % proceed unconditionally from commit to outcome
    commitNext = 'outcome';
    commitInput = {};
    outcomeInput = {};
end

states = { ...
    'name'      'next'      'timeout'	'entry'     'exit'  'input'; ...
    'predict'   'update'	av.tPredict {@doPredict, av} {} {}; ...
    'update'    'commit'    av.tUpdate  {@toggleUpdates, trialCalls, true} ...
    {@toggleUpdates, trialCalls, false} ...
    {@getHappeningEvent, ui}; ...
    'commit'    commitNext, av.tCommit  {@doCommit av} {}  commitInput; ...
    'outcome'   'delta'     av.tOutcome {@doOutcome av} {} outcomeInput; ...
    'delta'     'complete'	av.tDelta	{@doDelta av} {}   {}; ...
    'abort'     'failure'   0           {@setGoodTrial logic false} {} {}; ...
    'failure'   ''          av.tFailure {@doFailure av} {} {}; ...
    'complete'  'success'   0           {@setGoodTrial logic true} {} {}; ...
    'success'   ''          av.tSuccess {@doSuccess av} {} {}; ...
    'info'      'update',   0           {@run instructions} {} {}; ...
    };
trialStates.addMultipleStates(states);
trialStates.startFevalable = {@startTrial list};
trialStates.finishFevalable = {@finishTrial list};

% the trial call list will keep multiple things running
trialCalls.addCall({@read, ui}, 'input');
trialCalls.addCall({@updatePredictLogic, logic, ui, uiMap, options}, ...
    'update logic');
trialCalls.addCall({@updatePredict av}, 'update av');

% "update" calls can be toggled on and off with this subfunction
toggleUpdates(trialCalls, false);


%% Define a few subfunctions invoked during the task

% Wait until any keyboard presses a given keyName.
function waitForKeyboardTrigger(keyName, maxWait, av)
% show a message asking the subject to wait
av.doMessage(av.pleaseWaitString);

% block until any keybaord reports the given key press
kbs = dotsReadableHIDKeyboard.openManyKeyboards();
[isPressed, waitTime, data, kb] = ...
    dotsReadableHIDKeyboard.waitForKeyPress(kbs, keyName, maxWait);
av.doMessage('');
dotsReadableHIDKeyboard.closeManyKeyboards(kbs);

% record the key press data
topsDataLog.logDataInGroup(isPressed, 'triggerIsPressed');
topsDataLog.logDataInGroup(waitTime, 'triggerWaitTime');
topsDataLog.logDataInGroup(data, 'triggerData');
if isobject(kb)
    topsDataLog.logDataInGroup(kb.deviceInfo, 'triggerDeviceInfo');
end

% Initialize each trial.
function startTrial(list)
logic = list{'logic'}{'object'};
logic.startTrial();

ui = list{'input'}{'controller'};
ui.flushData();

options = list{'options'}{'struct'};
if options.isBucketPickup
    logic.isPredictionActive = false;
end


% Do accounting and write data to disk after each trial.
function finishTrial(list)
logic = list{'logic'}{'object'};
logic.finishTrial();

% fill in predictive inference data for this trial
tt = logic.blockTotalTrials;
bb = logic.currentBlock;
statusData = list{'logic'}{'statusData'};
payoutData = list{'logic'}{'payoutData'};
statusData(tt,bb) = logic.getStatus();
payoutData(tt,bb) = logic.getPayout();
list{'logic'}{'statusData'} = statusData;
list{'logic'}{'payoutData'} = payoutData;

% write new predictive inference data to disk
[dataPath, dataName, dataExt] = fileparts(logic.dataFileName);
if isempty(dataPath)
    dataPath = dotsTheMachineConfiguration.getDefaultValue('dataPath');
end
dataFullFile = fullfile(dataPath, dataName);
save(dataFullFile, 'statusData', 'payoutData')

% write new tops flow-of-control data to disk
topsDataLog.writeDataFile();


% Get subject input data and assign to the logic object.
function updatePredictLogic(logic, ui, uiMap, options)

% set the new prediction based on user input
if uiMap.isPositionMapping
    
    % get the left-right axis value which calibrated in [-1 1]
    %   and convert directly to outcome space
    val = ui.getValue(uiMap.left.ID);
    p = (1 + val)/2;
    prediction = p*logic.maxOutcome;
    logic.setPrediction(prediction);
    
else
    % look for held-down left and right using uiMap
    isLeft = ui.getValue(uiMap.left.ID) == -1;
    isRight = ui.getValue(uiMap.right.ID) == +1;
    
    % look for one-time presses using ui events
    event = ui.getNextEvent();
    
    % increment the outcome
    if strcmp(event, 'leftFine') || isLeft
        logic.setPrediction(logic.getPrediction() - 1);
        
    elseif strcmp(event, 'rightFine') || isRight
        logic.setPrediction(logic.getPrediction() + 1);
    end
end

% reactivate the prediction, if it needs to be picked up
if options.isBucketPickup
    prediction = logic.currentPrediction;
    rangeLow = options.bucketPickupRange(1);
    rangeHigh = options.bucketPickupRange(2);
    if (prediction >= rangeLow) && (prediction <= rangeHigh)
        logic.isPredictionActive = true;
    end
end

% Switch rapid prediction updating on or off.
function toggleUpdates(trialCalls, isActive)
trialCalls.setActiveByName(isActive, 'update logic');
trialCalls.setActiveByName(isActive, 'update av');