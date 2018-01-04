function [tree, list] = predInfHelicopter()
% Configure the Helicopter version of the 2011 predictive inference task.

% Organize predictive inference logic with a custom object
time = clock;
randSeed = time(6)*10e6;
logic = PredInfLogic(randSeed);
logic.name = 'Predictive Inference Helicopter';
logic.dataFileName = 'myDataFile';
logic.time = time;
logic.nBlocks = 2;
logic.blockHazards = [1 1 1] * 0.1;
logic.safetyTrials = 3;
logic.blockStds = [5 5 15];
logic.trialsPerBlock = 5;
logic.isBlockShuffle = false;
logic.fixedOutcomes = [];
logic.maxOutcome = 300;
logic.isPredictionReset = false;
logic.isPredictionLimited = false;

% The task has many input and flow options
options.isKeyboardTrigger = true;
options.triggerKeyName = 'KeyboardT';
options.triggerMaxWait = 5*60;
options.isPositionMapping = false;
options.isBucketPickup = false;
options.bucketPickupRange = [1 1]*logic.maxOutcome;

% try this with the fMRI non-metal joystick
%   omit the "commit" field to require subject to wait
% options.gamepadButtons.leftFine = 2;
% options.gamepadButtons.rightFine = 3;
% % options.gamepadButtons.commit = 1;
% options.gamepadButtons.info = 4;
% options.gamepadButtons.abort = 5;
% options.gamepadCalibration = {[100 860], [], [-1, +1]};

% Choose the Helicopter look and feel
isClient = true;
av = PredInfAVHelicopter(isClient);
av.pleaseWaitString = 'Please wait.';
av.isCloudy = false;
av.width = 30;
av.height = 20;
av.backgroundWidth = av.width;
av.backgroundHeight = 15;
av.cloudsHeight = 5;
av.yHelicopter = (av.backgroundHeight/2) - (av.cloudsHeight/2);
av.yClouds = av.yHelicopter;
av.logic = logic;
av.coins = struct( ...
    'name', {'gold', 'silver', 'bronze'}, ...
    'color', {[1.0 0.84 0], [0.7 0.7 0.8], [0.8 0.5 0.2]}, ...
    'value', {2, 1, 0}, ...
    'frequency', {1 1 1});
av.inactivePrediction = logic.maxOutcome;

% chose timing which applies to audiovisual elements and flow states
av.tIdle = 30;
av.tPredict = 0;
av.tUpdate = 10;
av.tCommit = 0.25;
av.tOutcome = 2;
av.tDelta = 0;
av.tSuccess = 0;
av.tFailure = 0;
% Wire up the logic and audio-visual objects
%   with flow control and user inputs
[tree, list] = configurePredInf2011(logic, av, options);
tree.run();

% visualize the task outline
%tree.gui();

% try out av behaviors without user input
%demoPredInfAV(av, logic);