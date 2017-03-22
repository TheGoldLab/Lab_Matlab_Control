function demoPredInfAV(av, logic)
% Run a PredInfAV object through its paces, without user input.

if nargin < 1 || isempty(av)
    av = PredInfAV();
end

if nargin < 2 || isempty(logic)
    logic = PredInfLogic();
end
av.logic = logic;

%%
% clear
% clear classes
% clc
% logic = PredInfLogic();
% av = PredInfAVHelicopter();
% av.logic = logic;
%%

% do preliminary things
logic.startSession();
av.initialize();

av.doPreviousInstruction();
av.doNextInstruction();
av.doNextInstruction();
av.doMessage('message');
av.doMessage('');

% do trial-related things
logic.startBlock();
logic.startTrial();

av.doPredict();
av.updatePredict();
av.updatePredict();
av.doCommit();
av.doOutcome();
av.doDelta();
av.doSuccess();
av.doFailure();

% do feedback things
logic.finishTrial();
av.doFeedback();

% clean up
av.terminate();