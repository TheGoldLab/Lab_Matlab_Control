function [tree, list] = predInfTitanAttacks()
% Configure the "Titan Attacks" version of the 2011 predictive inference
% task.

% Organize predictive inference logic with a custom object
time = clock;
randSeed = time(6)*10e6;
logic = PredInfLogic(randSeed);
logic.name = 'Predictive Inference Titan Attacks';
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
av = PredInfAVTitanAttacks(isClient);
av.logic = logic;
av.tIdle = 30;
av.tPredict = 0;
av.tUpdate = 30;
av.tCommit = 1;
av.tOutcome = 1;
av.tDelta = 1;
av.tSuccess = 0;
av.tFailure = 0;

% try out av behaviors without user input
%demoPredInfAV(av, logic);

% Wire up the logic and audio-visual objects
%   with flow control and user inputs
[tree, list] = configurePredInf2011(logic, av);
tree.run();

% view the task outline
%tree.gui();