function demoStateMachineRemote
% function demoStateMachineRemote
% 
% This function demonstrates the usage of the topsStateMachine object to
% organize the moving dots stimulus built in demoStimulus. Because we are
% not yet using the topsTreeNode object, it will be necessary to manually
% code for exiting the simulation loop. Furthermore, this function will
% attempt to incorporate keyboard input in order to respond to the task.
% Note that the final experimental code should seek to use eye fixations in
% order to determine the subject's decision.
%
% The state machine design is as shown below:
%
% Prepare stimulus -> Present stimulus -> Check input -> Display feedback
% -> Restart or exit
%
% 9/12/17    xd  wrote it

%% Create a topsGroupedList
%
% This is a versatile data structure that will allow use to pass the state
% of the state machine around as it advances.
state = topsGroupedList();

%% Create stimulus parameters
%
% We define some parameters that describe the task. In addition, a list of
% stimuli must be pre-generated and shuffled so that the code knowswhich
% stimulus to present during each trial. Note that each coherence level
% must have the same number of left and right stimuli.

state{'stimulus'}{'coherences'} = [50];
state{'stimulus'}{'trialsPerCoherencePerDirection'} = 3;
state{'stimulus'}{'trialCount'} = 1;
state{'stimulus'}{'fixationCueSize'} = 1;
state{'stimulus'}{'saccadeTargetOffset'} = 10;
state{'stimulus'}{'saccadeTargetSize'} = 1;

state{'FixationCue'}{'size'} = 1;
state{'SaccadeTarget'}{'offset'} = 10;
state{'SaccadeTarget'}{'size'} = 1;

% These paramemters are dependent on the preset ones.
state{'stimulus'}{'numTrials'} = length(state{'stimulus'}{'coherences'}) * state{'stimulus'}{'trialsPerCoherencePerDirection'} * 2;

% Create a list of trials and shuffle them.
tempCoherences = repmat(state{'stimulus'}{'coherences'}',state{'stimulus'}{'trialsPerCoherencePerDirection'}*2,1);
tempDirections = 180 * ones(length(tempCoherences),1);
tempDirections(1:end/2) = 0;
trials = [tempCoherences tempDirections];
trials = num2cell(trials);
trials = cell2struct(trials,{'coherence','direction'},2);
trials = trials(randperm(length(trials)));

state{'stimulus'}{'trials'} = trials;

%% Remote settings
state{'Remote'}{'clientIP'} = '158.130.221.157';
state{'Remote'}{'clientPort'} = 30000;
state{'Remote'}{'serverIP'} = '158.130.218.111';
state{'Remote'}{'serverPort'} = 30001;fjfff

%% Create graphics
%
% We will also pregenerate and store the graphics objects in the state
% topsGroupedList object. This will allow us to quickly gather the frames
% that need to be presented during the experiment. These basic frames are
% created in an external function so that the code organization is a bit
% easier to follow.
createBasicMovingDotsStimulusFrames(state);

%% Set up ui
%
% Here we set up a simple keyboard input for left and right. We really want
% to be using the eye tracking data as the subject input. This is a
% temporary (?) measure as I do not have the ability to debug with the
% EyeLink right now.

kb = dotsReadableHIDKeyboard();
% Clear default bindings
IDs = kb.getComponentIDs();
for ii = 1:numel(IDs)
    kb.defineEvent(IDs(ii),kb.components(ii).name, 0, 0, true);
end
kb.isAutoRead = 1;
state{'input'}{'controller'} = kb;

%% Define states for state machine
%
% We will define the list of fixed states that defines the transitions
% between each state during the experiment.

fixedStates = {...
    'name'             'entry'                   'input'             'timeout' 'exit'  'next'            ; ...
    'prepareStimulus'  {@prepareStimulus state}  {}                  0         {}      'presentStimulus' ; ...
    'presentStimulus'  {@presentStimulus state}  {}                  0         {}      'checkInput'      ; ...
    'checkInput'       {}                        {@checkInput state} 0         {}      ''                ; ...
    'correct'          {@displayCorrect state}   {}                  0         {}      'finishTrial'     ; ...
    'incorrect'        {@displayIncorrect state} {}                  0         {}      'finishTrial'     ; ...
    'finishTrial'      {@finishTrial state}      {}                  0         {}      ''                };

stateMachine = topsStateMachine();
stateMachine.addMultipleStates(fixedStates);

maintask = topsTreeNode();
maintask.iterations = 5;
maintask.addChild(stateMachine);

maintask.run();
end

function prepareStimulus(state)
    
    % Load the trial we are on.
    trialCount = state{'stimulus'}{'trialCount'};
    trials = state{'stimulus'}{'trials'};
    trial = trials(trialCount);
    
    % Generate an appropriate graphics ensemble to present. We create a
    % moving dots stimulus using the coherence and direction parameters for
    % this particular trial. It will be centered on the screen and put into
    % an ensemble with the two saccade targets.
    saccadeTargets = state{'graphics'}{'saccadeTargetsFrame'};
    
    movingDotStim = dotsDrawableDotKinetogram();
    movingDotStim.stencilNumber = 1;
    movingDotStim.pixelSize = 8;
    movingDotStim.diameter = 7;
    movingDotStim.yCenter = 0;
    movingDotStim.xCenter = 0;
    movingDotStim.density = 200;
    movingDotStim.direction = 0;
    movingDotStim.coherence = 10;
    
    
    clientIP = state{'Remote'}{'clientIP'};
    clientPort = state{'Remote'}{'clientPort'};
    serverIP = state{'Remote'}{'serverIP'};
    serverPort = state{'Remote'}{'serverPort'};
    stimulusAndSaccadeTargets = dotsClientEnsemble('stimulus',clientIP,clientPort,serverIP,serverPort);
    stimulusAndSaccadeTargets.addObject(movingDotStim);
    stimulusAndSaccadeTargets.addObject(saccadeTargets);
    
    stimulusAndSaccadeTargets.automateObjectMethod( ...
        'draw', @dotsDrawable.drawFrame, {}, [], true);
    
%     stimulusAndSaccadeTargets.callObjectMethod(@prepareToDrawInWindow);
%     stimulusAndSaccadeTargets.run(2);
    
    state{'graphics'}{'stimulusAndSaccadeTargets'} = stimulusAndSaccadeTargets;
end

function presentStimulus(state)

    % Gather all the stimulus graphics
    fixationCue = state{'graphics'}{'fixationCue'};
    fixationCueAndSaccadeTargets = state{'graphics'}{'fixationCueAndSaccadeTargets'};
    stimulusAndSaccadeTargets = state{'graphics'}{'stimulusAndSaccadeTargets'};
    saccadeTargets = state{'graphics'}{'saccadeTargets'};
    
    graphicsList = {fixationCue fixationCueAndSaccadeTargets stimulusAndSaccadeTargets saccadeTargets};
    
    % Gather the appropriate durations for each part of the stimulus
    
    durationList = {0.5 0.5 2 0.5};
    
    % Present
    for ii = 1:length(graphicsList)
        graphicsList{ii}.callObjectMethod(@prepareToDrawInWindow);
        graphicsList{ii}.run(durationList{ii});
    end
end

function string = checkInput(state)
    ui = state{'input'}{'controller'};
    ui.flushData();
    
    trialCount = state{'stimulus'}{'trialCount'};
    trials = state{'stimulus'}{'trials'};
    trial = trials(trialCount);
    
    % A while loop is used to wait for user input. The only valid button
    % presses will be J or F
    name = ui.getNextEvent();
    while ~(strcmp(name,'KeyboardJ') || strcmp(name,'KeyboardF'))
        name = ui.getNextEvent();
    end
    
    % Map the J key to right and the F key to left
    if strcmp('KeyboardJ',name)
        decision = 0;
    else
        decision = 180;
    end
    
    if decision == trial.direction
        string = 'correct';
    else
        string = 'incorrect';
    end

end

function displayCorrect(state) 
    correct = state{'graphics'}{'correct'};
    correct.callObjectMethod(@prepareToDrawInWindow);
    correct.run(2);
end

function displayIncorrect(state) 
    incorrect = state{'graphics'}{'incorrect'};
    incorrect.callObjectMethod(@prepareToDrawInWindow);
    incorrect.run(2);
end

function finishTrial(state) 
    trialCount = state{'stimulus'}{'trialCount'};
    state{'stimulus'}{'trialCount'} = trialCount + 1;
end