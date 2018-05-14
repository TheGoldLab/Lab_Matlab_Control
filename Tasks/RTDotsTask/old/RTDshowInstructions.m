function RTDshowInstructions(state)
% RTDshowInstructions(state)
%
% Show instructions defined in configureGraphicsRTDots.m
%
% Inputs:
%   state      -  A topsGroupedList object containing experimental parameters
%                 as well as data recorded during the experiment.


%% ---- Get current task type
taskArray = state{'Task'}{'taskArray'};
taskCounter = state{'Task'}{'taskCounter'};
taskType  = taskArray{1, taskCounter};
if any(strcmp(taskType, {'Quest' 'meanRT'}))
   taskType = 'NN';
end

%% ---- Get instructions ensemble
instructionsEnsemble = state{'Graphics'}{'instructionsEnsemble'};

%% ---- Set SAT instruction string
SATindex     = state{'Graphics'}{'SATtext ind'};
SATstrings   = state{'Graphics'}{'SATstrings'};
SATi         = strcmp(taskType(1), SATstrings(:,1));
if any(SATi)
   instructionsEnsemble.setObjectProperty('string', SATstrings{SATi, 2}, SATindex);
   instructionsEnsemble.setObjectProperty('isVisible', true, SATindex);
else
   instructionsEnsemble.setObjectProperty('isVisible', false, SATindex);
end

%% ---- Set BIAS instruction string
BIASindex    = state{'Graphics'}{'BIAStext ind'};
BIASstrings  = state{'Graphics'}{'BIASstrings'};
BIASi = strcmp(taskType(2), BIASstrings(:,1));
if any(BIASi)
   instructionsEnsemble.setObjectProperty('string', BIASstrings{BIASi, 2}, BIASindex);
   instructionsEnsemble.setObjectProperty('isVisible', true, BIASindex);
else
   instructionsEnsemble.setObjectProperty('isVisible', false, BIASindex);
end

%% ---- Get the instructions screen composite and run one iteration
instructionsScreenComposite = state{'Graphics'}{'instructionsScreenComposite'};
instructionsScreenComposite.run(1);


