function [tree, list] = predInfIsoluminant()
% Configure the Isoluminant version of the 2011 predictive inference task.

% Organize predictive inference logic with a custom object
time = clock;
randSeed = time(6)*10e6;
logic = PredInfLogic(randSeed);
logic.name = 'Predictive Inference Isoluminant';
logic.time = time;
logic.nBlocks = 2;
logic.blockHazards = [1 1 1] * 0.1;
logic.safetyTrials = 3;
logic.blockStds = [5 5 15];
logic.trialsPerBlock = 5;
logic.isBlockShuffle = false;
logic.fixedOutcomes = [];
logic.maxOutcome = 300;
logic.isPredictionReset = true;
logic.isPredictionLimited = true;

% Choose payout structure.
% "weights" tell how to mix [omniscient and amnesiac] observers
logic.goldObserverWeights = [2 1];
logic.silverObserverWeights = [1 2];
logic.bronzeObserverWeights = [0 1];
logic.goldPayout = '$15';
logic.silverPayout = '$12';
logic.bronzePayout = '$10';

% Choose the Isoluminant audio-visual look and feel
isClient = false;
av = PredInfAVIsoluminant(isClient);
av.logic = logic;
av.tIdle = 30;
av.tPredict = 0;
av.tUpdate = 30;
av.tDelta = 0;
av.tSuccess = 1;
av.tFailure = 1;

% Choose whether to use an eye tracker
options.isEyeTracking = false;
if options.isEyeTracking
    av.tCommit = 1;
    av.tOutcome = 4;
else
    av.tCommit = 1;
    av.tOutcome = 1;
end

% fill in other options
options.isKeyboardTrigger = false;
options.isPositionMapping = false;
options.isBucketPickup = false;

% try out av behaviors without user input
%demoPredInfAV(av, logic);

% Wire up the logic and audio-visual objects
%   with flow control and user inputs
[tree, list] = configurePredInf2011(logic, av, options);
tree.run();

% visualize the task outline
%tree.gui();