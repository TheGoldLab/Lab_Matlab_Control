function [taskTree, taskList] = configThresh(REMOTE_MODE, DEBUG_MODE, FULL_SCREEN, QUERY_CONF, SAVE_MODE)
% Configures a dots kinetogram 2-AFC task that permits construction of the
% psychometric fxn, and identification of threshold
%
%   To run, type:
%   [taskTree, taskList] = configThresh; taskTree.run;
%   
%
%   Code adapted from configureDots2afcTask from snow dots demo
%   2010-09-16:  asks sbj guess vs. not (YL)
%   2010-09-17:  makes the guess an option that can be turned off (YL)
%   2010-09-20:  uses double-click to indicate confidence
%   2010-10-05:  added countdown to beginning (LAM)
%   2010-10-08:  changed feedback to arrows (LAM)

%% Stuff to control code flow
if nargin < 1
    REMOTE_MODE = 0;
    QUERY_CONF = 1;             % run the code for querying confidence
    DEBUG_MODE = 1;
    FULL_SCREEN = 0;
    SAVE_MODE = 1;
end

DOTS_RDK = 0;                   % if 1 then use JIG's dotsDrawableRDK class, w/ seed feature

% waitTime=.001;
%% Organization:
% a container for all task data and objects
%   partitioned into arbitrary groups
%   viewable with taskList.gui

taskList = topsGroupedList;

% give the task a name, used below
taskName = 'dotsThresh';

%% Constants:
% store some constants in the taskList container
%   used during configuration
%   used while task is running
taskList{'timing'}{'preparation'} = 1;              % fixation duration
taskList{'timing'}{'stimulus'} = 1;                % motion stimulus duration
taskList{'timing'}{'choice'} = inf;                 % how long sbj gets to make choice
taskList{'timing'}{'dClick'} = .5;                  % duration w/i which a double-click counts
taskList{'timing'}{'feedback'} = .5;
taskList{'timing'}{'trialTimeout'} = 600;
taskList{'timing'}{'intertrial'} = .5;
taskList{'timing'}{'confid'} = inf;
taskList{'timing'}{'tic'} = [];                 % start time for trial (initializaed in startExper)

taskList{'graphics'}{'white'} = [255 255 255];
taskList{'graphics'}{'gray'} = [128 128 128];
taskList{'graphics'}{'red'} = [196 64 32];
taskList{'graphics'}{'green'} = [64 196 32];
taskList{'graphics'}{'pink'} = [255 51 204];
taskList{'graphics'}{'aqua'} = [51 255 204];

taskList{'graphics'}{'stimDiameter'} = 10;     % size of aperture
taskList{'graphics'}{'density'} = 40;               % dots/deg^2/s
taskList{'graphics'}{'speed'} = 6;                  % deg/s
taskList{'graphics'}{'dotSize'} = 3;               % pixel size of individual dots

% the critical motion stimulus parameters
% taskList{'stim'}{'coh'} = [0, 15, 25, 50, 70, 85, 100];
% taskList{'stim'}{'coh'} = [0, 1, 3, 10, 25, 50, 99];
if DEBUG_MODE
    taskList{'stim'}{'coh'} = [100, 100, 100];
    taskList{'stim'}{'dir'} = [0, 180];
    taskList{'stim'}{'numPerCond'} = 2;                % # of trials per cond
else
%     taskList{'stim'}{'coh'} = [0, 3.2, 6.4, 12.8, 25.6, 51.2, 99.9];
    taskList{'stim'}{'coh'} = [0, 3.2, 25.6, 99.9];
    taskList{'stim'}{'dir'} = [0, 180];
    taskList{'stim'}{'numPerCond'} = 5;                % # of trials per cond
end

taskList{'stim'}{'cohToUse'} = [];
taskList{'stim'}{'dirToUse'} = [];

taskList{'graphics'}{'fixPixels'} = 10;
taskList{'graphics'}{'leftward'} = 180;
taskList{'graphics'}{'rightward'} = 0;
taskList{'graphics'}{'leftSide'} = -5;
taskList{'graphics'}{'rightSide'} = 5;
taskList{'graphics'}{'neutralPixels'} = [5, 5];
taskList{'graphics'}{'leftBigPixels'} = [25, 5];
taskList{'graphics'}{'rightBigPixels'} = [5, 25];
taskList{'graphics'}{'leftConfidPixels'} = [35, 5];
taskList{'graphics'}{'rightConfidPixels'} = [5, 35];
taskList{'graphics'}{'leftGuessPixels'} = [20, 5];
taskList{'graphics'}{'rightGuessPixels'} = [5, 20];
taskList{'graphics'}{'guessSide'} = 3;
taskList{'graphics'}{'text size'} = 30;

taskList{'control'}{'blocks per session'} = 1;    % taskTree.iterations
taskList{'control'}{'trials per block'} = ...
    length(taskList{'stim'}{'coh'})*length(taskList{'stim'}{'dir'})*...
    taskList{'stim'}{'numPerCond'};               % pfTree.iterations
taskList{'control'}{'dirName'} = ...
    '/Volumes/XServerData/Psychophysics/Yin Data/';
taskList{'control'}{'fname'} = 'pf';              % name of file saved to
taskList{'control'}{'trialnum'} = 1;              % an internal counter for how many trials has passed
taskList{'control'}{'guessFlag'} = 0;             % set to 1 if in guess mode
taskList{'control'}{'debug'} = DEBUG_MODE;               % set to 1 to display debug-related outputs
taskList{'control'}{'fullscreen'} = FULL_SCREEN;          % set to 1 to display full screen
taskList{'control'}{'remote'} = REMOTE_MODE;            % set to 1 to do remote stuff
taskList{'control'}{'queryConf'} = QUERY_CONF;      % set to 1 if want to run code to query confidence
taskList{'control'}{'dotsRDK'} = DOTS_RDK;

taskList{'control'}{'currentChoice'} = NaN;
taskList{'control'}{'currentConfid'} = 0;
taskList{'control'}{'check'} = false;
taskList{'control'}{'countUp'} = 0;
taskList{'control'}{'count'} = 5;
taskList{'control'}{'x'} = 6;

% trial data to be stored
taskList{'data'}{'stim'} = [];
taskList{'data'}{'coh'} = [];
taskList{'data'}{'dir'} = [];
taskList{'data'}{'choice'} = [];
taskList{'data'}{'confid'} = [];
taskList{'data'}{'threshCoh'} = [];
taskList{'data'}{'pulseCoh'} = [];

%% Graphics:
% create some graphics objects
%   configure them using constants from above
%   store them in the taskList container
% decide whether to do things remotely or not
dm = dotsTheDrawablesManager.theObject;
% dm.initialize;                              % this clears the manager of previous elements
dm.setScreenTextSetting('TextSize', taskList{'graphics'}{'text size'});

% dm.waitFevalable={@WaitSecs, waitTime};
if taskList{'control'}{'remote'}
    dm.reset('serverMode', false, 'clientMode', true);          % reset also does initiliaze
else
    dm.reset('serverMode', false, 'clientMode', false);
end

% dm.waitFevalable={@WaitSecs, waitTime};

% this bit of code makes display full-screen
if taskList{'control'}{'fullscreen'}
    s = dotsTheScreen.theObject;
    s.displayRect = [];
end

% a fixation point
fp = dm.newObject('dotsDrawableTargets');
fp.color = taskList{'graphics'}{'gray'};
fp.dotSize = taskList{'graphics'}{'fixPixels'};
fp.isVisible = false;
taskList{'graphics'}{'fixation point'} = fp;

% target dots
targs = dm.newObject('dotsDrawableTargets');
targs.color = taskList{'graphics'}{'gray'};
targs.dotSize = taskList{'graphics'}{'neutralPixels'};
left = taskList{'graphics'}{'leftSide'};
right = taskList{'graphics'}{'rightSide'};
targs.x = [left, right];
targs.y = [0 0];
targs.isVisible = false;
taskList{'graphics'}{'targets'} = targs;

%arrows to indicate motion direction
arrowLeft = dm.newObject('dotsDrawableLines');
arrowLeft.color = taskList{'graphics'}{'gray'};
arrowLeft.width = 4;
left = taskList{'graphics'}{'leftSide'} + 1;
arrowLeft.x = [left 0];
arrowLeft.y = [0 0];
arrowLeft.isVisible = false;
taskList{'graphics'}{'arrow left'} = arrowLeft;

arrowRight = dm.newObject('dotsDrawableLines');
arrowRight.color = taskList{'graphics'}{'gray'};
arrowRight.width = 4;
right = taskList{'graphics'}{'rightSide'} - 1;
arrowRight.x = [0 right];
arrowRight.y = [0 0];
arrowRight.isVisible = false;
taskList{'graphics'}{'arrow right'} = arrowRight;


% RAND DOTS STIMULUS ------------------------------------
if taskList{'control'}{'dotsRDK'}
    stim=dm.newObject('dotsDrawableRDK');
else
    stim = dm.newObject('dotsDrawableDotKinetogram');         % replace dotsDrawableRDK w/ dotsDrawableDotKinetogram
end
stim.color = taskList{'graphics'}{'white'};
stim.diameter = taskList{'graphics'}{'stimDiameter'};
stim.density = taskList{'graphics'}{'density'};
stim.speed = taskList{'graphics'}{'speed'};
stim.dotSize = taskList{'graphics'}{'dotSize'};
stim.isVisible = false;
taskList{'graphics'}{'stimulus'} = stim;

% progress text
prog = dm.newObject('dotsDrawableText');
prog.x = 10;
prog.y = -10;
prog.isVisible = false;
taskList{'graphics'}{'progress'} = prog;

% guess text
guessText = dm.newObject('dotsDrawableText');
guessText.x = 0;
guessText.y = taskList{'graphics'}{'guessSide'};
guessText.string = 'Did you guess?';
guessText.isVisible = false;
taskList{'graphics'}{'guess'} = guessText;

% guess target text
guessYes = dm.newObject('dotsDrawableText');
guessNo  = dm.newObject('dotsDrawableText');
guessYes.x = taskList{'graphics'}{'leftSide'};
guessNo.x = taskList{'graphics'}{'rightSide'};
guessYes.y = taskList{'graphics'}{'guessSide'};
guessNo.y = taskList{'graphics'}{'guessSide'};
guessYes.string = 'Yes Guess';
guessNo.string = 'No Guess';
guessYes.isVisible = false;
guessNo.isVisible = false;
taskList{'graphics'}{'guessYes'} = guessYes;
taskList{'graphics'}{'guessNo'} = guessNo;

% query name text
nameText = dm.newObject('dotsDrawableText');
nameText.x = 0;
nameText.y = 5;
nameText.string = 'Please type your initials and press [ENTER].';
nameText.isVisible = false;
taskList{'graphics'}{'name'} = nameText;

%press button to begin
beginText = dm.newObject('dotsDrawableText');
beginText.x = 0;
beginText.y = 0;
beginText.string = 'Please press any button to begin';
beginText.isVisible = false;
taskList{'graphics'}{'beginText'} = beginText;


%countdown display
countDown = dm.newObject('dotsDrawableText');
countDown.x = 0;
countDown.y = 0;
countDown.string = '5';
countDown.isVisible = false;
taskList{'graphics'}{'countDown'} = countDown;




% add all objects to one group, to be drawn simultaneously
dm.addObjectToGroup(fp, taskName);
dm.addObjectToGroup(targs, taskName);
dm.addObjectToGroup(stim, taskName);
dm.addObjectToGroup(prog, taskName);
dm.addObjectToGroup(nameText, taskName);
dm.addObjectToGroup(guessText, taskName);
dm.addObjectToGroup(guessYes, taskName);
dm.addObjectToGroup(guessNo, taskName);
dm.addObjectToGroup(beginText, taskName);
dm.addObjectToGroup(countDown, taskName);
dm.addObjectToGroup(arrowLeft, taskName);
dm.addObjectToGroup(arrowRight, taskName);
dm.activateGroup(taskName);

% use a name for the draw manager in the gui
dm.name = 'draw';

%% Input:
% create input object
qm = dotsTheQueryablesManager.theObject;
gp = qm.newObject('dotsQueryableHIDGamepad');
taskList{'input'}{'gamepad'} = gp;
if gp.isAvailable
    % identify axes movement phenomenons
    %   see gp.phenomenons.gui()
    left = gp.phenomenons{'pressed'}{'pressed_button_5'};   % L finger key
    right = gp.phenomenons{'pressed'}{'pressed_button_6'};  % R finger key
    start = gp.phenomenons{'pressed'}{'any_pressed'};
    
    % identify primary button press phenomenon
    %   see gp.phenomenons.gui()
    pressL = gp.phenomenons{'axes'}{'any_axis'};  % left set of keys
    pressR = gp.phenomenons{'pressed'}{'any_pressed'};  % right set
    quit = dotsPhenomenon.composite([pressL,pressR],'intersection');

    hid = gp;
else
    kb = qm.newObject('dotsQueryableHIDKeyboard');
    taskList{'input'}{'keyboard'} = kb;
    left = kb.phenomenons{'pressed'}{'pressed_KeyboardLeftArrow'};
    right = kb.phenomenons{'pressed'}{'pressed_KeyboardRightArrow'};
    start = kb.phenomenons{'pressed'}{'pressed_KeyboardSpacebar'};
    % up = kb.phenomenons{'pressed'}{'pressed_KeyboardUpArrow'};
    % down = kb.phenomenons{'pressed'}{'pressed_KeyboardDownArrow'};
%     commit = kb.phenomenons{'pressed'}{'pressed_KeyboardSpacebar'};
    quit = kb.phenomenons{'pressed'}{'pressed_KeyboardEscape'};

    hid = kb;
end
taskList{'input'}{'using'} = hid;
% classify phenomenons to produce arbitrary outputs
%   each output will match a state name, below
hid.addClassificationInGroupWithRank(left, 'leftward', taskName, 2);
hid.addClassificationInGroupWithRank(right, 'rightward', taskName, 3);
hid.addClassificationInGroupWithRank(start, 'countdown', taskName, 4);
% hid.addClassificationInGroupWithRank(commit, 'commitment', taskName, 4);
hid.addClassificationInGroupWithRank(quit, 'quit', taskName, 5);
hid.activeClassificationGroup = taskName;

%% Control:
% create three types of control objects:
%       - topsConditions organizes combinations of parameter values for
%       each trial
%       - topsTreeNode organizes flow outside of trials
%       - topsStateMachine organizes flow within trials
%       - topsCallList organizes batches of functions to be called together
%       - topsConcurrentComposite interleaves behaviors of the drawables
%       manager, state machine, and call list.
%   connect these to each other
%   store them in the taskList container


% the trunk of the tree, branches are added below
taskTree = topsTreeNode;
taskTree.name = 'pf task:';
taskTree.iterations = taskList{'control'}{'blocks per session'};
taskTree.startFevalable = {@startExper, taskList};
taskTree.finishFevalable = {@finishExper, taskList};

% a batch of function calls that apply to all the trial types below
%   start- and finishFevalable get called once per trial
%   any addCall fevalables get called repeatedly during a trial
trialCalls = topsCallList;
trialCalls.name = 'call functions';
trialCalls.alwaysRunning = true;
trialCalls.startFevalable = {@mayDrawNextFrame, dm, true};        % not in MN's code
trialCalls.addCall({@readData, hid});
% trialCalls.addCall({@mayDrawNextFrame,dm});
trialCalls.finishFevalable = {@mayDrawNextFrame, dm, false};
taskList{'control'}{'trial calls'} = trialCalls;

% each trial type gets its own state machine and tree "branch"
%   state machines share many states

%%Beginning Screen
beginMachine = topsStateMachine;
beginMachine.name = 'begin screen';

%timing
TT = taskList{'timing'}{'trialTimeout'};
CDT = 3;
PT = taskList{'timing'}{'feedback'};

showIt = {@showCount, taskList};
hideIt = {@hideCount, taskList};

%input fxn
QR = {@queryAsOfTime, hid};


fixedStates = { ...
    'name',         'entry',          'timeout', 'input', 'exit',             'next'; ...
    'begin',        {@show,beginText},   TT,      QR,     {@hide, beginText}, 'countdown'; ...
    'countdown',    showIt,              CDT,     {},     hideIt,             'countdown';...
    'pause',        {},                  PT,      {},     {},                 '';...
};

beginMachine.addMultipleStates(fixedStates);
taskList{'control'}{'beginMachine'} = beginMachine;

beginConcurrents = topsConcurrentComposite;
beginConcurrents.name = 'beginConcurrents';
beginConcurrents.addChild(dm);                                          % not in Matt's code
beginConcurrents.addChild(trialCalls);
beginConcurrents.addChild(beginMachine);

% add a branch to the tree trunk to launch a psychometric fxn trial
beginTree = taskTree.newChildNode;
beginTree.name = 'beginTree';
beginTree.iterations = 1;    
beginTree.addChild(beginConcurrents);


%% Trials to Establish the Psychometric Fxn (& Thus the Threshold Coh)
pfMachine = topsStateMachine;
pfMachine.name = 'psychometric fxn';

% timing
PT = taskList{'timing'}{'preparation'};         % fixation time
ST = taskList{'timing'}{'stimulus'};            % stim time
CT = taskList{'timing'}{'choice'};              % choice time
DT = taskList{'timing'}{'dClick'};              % time to double click
FT = taskList{'timing'}{'feedback'};            % feedback time
TT = taskList{'timing'}{'trialTimeout'};       % trialTimeout (not used in this version)
IT = taskList{'timing'}{'intertrial'};
% GT = taskList{'timing'}{'guess'};

% entry fxn
setConds = {@setStim, taskList};                % set stimulus condition
dispC = {@dispChoice, taskList};
dispG = {@dispGuess, taskList};                 % display guess text and targets 
ackLeft = {@acknowledgeLeft, taskList};         % make left bigger
ackRight = {@acknowledgeRight, taskList};       % make right bigger
feedback = {@drawCorrectIncorrect, taskList};   % give feedback (red vs. green)
updateD = {@updateData, taskList};              % update data
whichMode = {@decideMode, taskList}; 

% input fxn
QR = {@queryAsOfTime, hid};

% exit fxn
hideAll = {@hideDisp, taskList};
resetTargs = {@resetVal, taskList};

fixedStates = { ...
    'name',         'entry',   'timeout', 'input', 'exit',        'next'; ...
    'conditions',   setConds,       0,      {},      {},         'showFP'; ...
    'showFP',       {@show,fp},     PT,     {},      {},         'stimulus';...
    'stimulus',     {@show,stim},   ST,     {},   {@hide, stim},  'choice';...
    'choice',       dispC,          CT,     QR,      {},         'gchoice,';...
    'gchoice',      dispG,          DT,     QR,      {},         'feedback';...     % hi-jacking the 'guess' module for double-clicking
    'leftward',     ackLeft,        0,      {},      {},         'responded';...
    'rightward',    ackRight,       0,      {},      {},         'responded';...
    'responded',    whichMode,      0,      {},   {@hide, fp},    '';...  % if in guess mode -> time for feedback
    'feedback',     feedback,       FT,     {},      {},  'updateData';...
    'updateData',   updateD,        IT,     {},      {},         '';...
    'quit',         {@quitTask},    0,      {},      {},         '';...
};

pfMachine.addMultipleStates(fixedStates);
pfMachine.startFevalable = {@startTrial, taskList};
pfMachine.finishFevalable = {@finishTrial, taskList};
taskList{'control'}{'pfMachine'} = pfMachine;

pfConcurrents = topsConcurrentComposite;
pfConcurrents.name = 'pfConcurrents';
pfConcurrents.addChild(dm);                                          % not in Matt's code
pfConcurrents.addChild(trialCalls);
pfConcurrents.addChild(pfMachine);

% add a branch to the tree trunk to launch a psychometric fxn trial
% pfTree = taskTree.newChildNode;
% pfTree.name = 'pfTree';
% pfTree.iterations = taskList{'control'}{'trials per block'};    
% % fixedTree.addChild(taskConditions);
% pfTree.addChild(pfConcurrents);
% pfTree.startFevalable = {@startPF, taskList};     % here I shuffle the list of stim parameters to use

%% Save the Data
if SAVE_MODE
    saveMachine = topsStateMachine;
    saveMachine.name = 'save data to file';

    name = taskList{'graphics'}{'name'};

    saveStates = {...
        'name', 'entry',        'timeout', 'input','exit', 'next';...
        'queryName', {@show, name},     0,      {},     {},'save';...
        'save', {@saveToFile, taskList},0,      {},     {},'disp';...
        'disp', {@dispPF, taskList},    0,      {},     {},    '';...
        'quit', {@quitTask},            0,      {},     {},    '';...
        };

    saveMachine.addMultipleStates(saveStates);
    taskList{'control'}{'save machine'} = saveMachine;

    saveConcurrents = topsConcurrentComposite;
    saveConcurrents.name = 'run() concurrently save:';
    saveConcurrents.addChild(dm);
    saveConcurrents.addChild(trialCalls);
    saveConcurrents.addChild(saveMachine);

    % add a branch to the tree trunk to launch a psychometric fxn trial
    saveTree = taskTree.newChildNode;
    saveTree.name = 'save:';
    saveTree.iterations = 1;
    saveTree.addChild(saveConcurrents);
end

%% Custom Behaviors:
% define behaviors that are unique to this task
%   the control objects above use these
%   the smaller and fewer of these, the better

function startExper(taskList)
% called by startFevalable of toplevel taskTree

% start the timer
taskList{'timing'}{'tic'} = tic;

% initialize (refresh) and open the screen
dm = dotsTheDrawablesManager.theObject;
dm.openScreenWindow;


function finishExper(taskList)
% called by finishFevalable of toplevel taskTree

% already done in saveToFile()
% close the screen
dm = dotsTheDrawablesManager.theObject;
dm.closeScreenWindow;

% end the timer
secElapsed = toc(taskList{'timing'}{'tic'});
minElapsed = round(secElapsed/60);
if taskList{'control'}{'debug'}
    if minElapsed > 1;
        disp(['Time elapsed: ' num2str(minElapsed) ' min.']);
    else
        disp(['Time elapsed: ' num2str(secElapsed) ' sec.']);
    end
end

function startPF(taskList)
% generate shuffled list of coh/dir here
stimcoh = taskList{'stim'}{'coh'};
stimdir = taskList{'stim'}{'dir'};
numPerCond = taskList{'stim'}{'numPerCond'};

[cohToUse, dirToUse] = pairshuffle(stimcoh, stimdir, numPerCond);

taskList{'stim'}{'cohToUse'} = cohToUse;
taskList{'stim'}{'dirToUse'} = dirToUse;

if taskList{'control'}{'debug'}
    disp(['startPF() cohToUse: ' num2str(cohToUse.*((dirToUse==0)*2-1))]);
end

function startTrial(taskList)
hid = taskList{'input'}{'using'};
hid.flushData;

resetVal(taskList);
hideDisp(taskList);

function finishTrial(taskList)
taskList{'control'}{'trialnum'} = taskList{'control'}{'trialnum'}+1;
% hideDisp(taskList);
WaitSecs(taskList{'timing'}{'intertrial'});


function setStim(taskList)
% get the relevant variables from tasklist
trialnum = taskList{'control'}{'trialnum'};
stim = taskList{'graphics'}{'stimulus'};
cohToUse = taskList{'stim'}{'cohToUse'};             % the parameters are already shuffled
dirToUse = taskList{'stim'}{'dirToUse'};

% get the coh/dir from the list, and set it to stim
% pick a random coh/dir from the list and set it to stim
stim.coherence = cohToUse(trialnum);
stim.direction = dirToUse(trialnum);

% set the seed
if taskList{'control'}{'dotsRDK'}
stim.seed = sum(clock);
end

% update stim in taskList
taskList{'graphics'}{'stimulus'} = stim;

% update progress text
prog = taskList{'graphics'}{'progress'};
prog.string = [num2str(trialnum) '/' num2str(length(cohToUse))];
if taskList{'control'}{'debug'}
    prog.show;
end
taskList{'graphics'}{'progress'} = prog;

 
function dispChoice(taskList)
% flush the input (we only care about choice after sbj has seen everything)
hid = taskList{'input'}{'using'};

if taskList{'control'}{'debug'}
    disp('dispChoice()1');
    for i = 1:length(hid.trackingTimestamps)
        disp(hid.queryNextTracked);
    end
end

hid.flushData;

% display the choice targets
targs = taskList{'graphics'}{'targets'};
targs.show;
if taskList{'control'}{'debug'}
  disp('dispChoice()2');
end


function dispGuess(taskList)
% flush the input (we only care about choice after sbj has seen everything)
hid = taskList{'input'}{'using'};
hid.flushData;

% display the guess text and guess targets
% show(taskList{'graphics'}{'guess'});
% show(taskList{'graphics'}{'guessYes'});
% show(taskList{'graphics'}{'guessNo'});

% set the guess mode flag
taskList{'control'}{'currentConfid'} = 0;         % by default (i.e., single-click), is NOT confident
taskList{'control'}{'guessFlag'} = 1;

function acknowledgeLeft(taskList)
targs = taskList{'graphics'}{'targets'};

if taskList{'control'}{'guessFlag'} == 0
    taskList{'control'}{'currentChoice'} = 180;    
    targs.dotSize = taskList{'graphics'}{'leftBigPixels'};
else
    % sbj is confident if 2nd click is same as first click
    if taskList{'control'}{'currentChoice'} == 180;
        taskList{'control'}{'currentConfid'} = 1;
        targs.dotSize = taskList{'graphics'}{'leftConfidPixels'};
    else
        % if 2nd click is opposite - sbj is 'guessing'
        taskList{'control'}{'currentConfid'} = -1;
        targs.dotSize = taskList{'graphics'}{'rightGuessPixels'};
    end
%     guessY = taskList{'graphics'}{'guessYes'};
%     guessY.string = 'YES GUESS';
end


function acknowledgeRight(taskList)
targs = taskList{'graphics'}{'targets'};

if taskList{'control'}{'guessFlag'} == 0
    taskList{'control'}{'currentChoice'} = 0;    
    targs.dotSize = taskList{'graphics'}{'rightBigPixels'};
else
    % sbj is confident if 2nd click is same as first click
    if taskList{'control'}{'currentChoice'} == 0;
        taskList{'control'}{'currentConfid'} = 1;
        targs.dotSize = taskList{'graphics'}{'rightConfidPixels'};
    else
        % if 2nd click is opposite - sbj is 'guessing'
        taskList{'control'}{'currentConfid'} = -1;
        targs.dotSize = taskList{'graphics'}{'leftGuessPixels'};
    end
%     guessN = taskList{'graphics'}{'guessNo'};
%     guessN.string = 'NO GUESS';
end


function decideMode(taskList)
% called by responded state - which is the state after ackL/R
% if guess mode -> set next state as feedback
% otherwise, just go to gchoice
machine = taskList{'control'}{'pfMachine'};

if taskList{'control'}{'debug'}
    disp(['decidemode demo: guessFlag' num2str(taskList{'control'}{'guessFlag'})]);
end

if taskList{'control'}{'queryConf'}
    if taskList{'control'}{'guessFlag'}
        machine.editStateByName('responded','next','feedback');
    else
        machine.editStateByName('responded','next','gchoice');
    end
else
    machine.editStateByName('responded','next','feedback');
end

taskList{'control'}{'pfMachine'} = machine;

function drawCorrectIncorrect(taskList)
% hide(taskList{'graphics'}{'guess'});
% hide(taskList{'graphics'}{'guessYes'});
% hide(taskList{'graphics'}{'guessNo'});

stim = taskList{'graphics'}{'stimulus'};
stimDir = stim.direction;
arrowLeft = taskList{'graphics'}{'arrow left'};
arrowRight = taskList{'graphics'}{'arrow right'};


if stimDir == 0
    show(arrowRight)
    if taskList{'control'}{'debug'}
        disp('right arrow');
    end
else
    show(arrowLeft)
    if taskList{'control'}{'debug'}
        disp('left arrow');
    end
end

% choiceDir = taskList{'control'}{'currentChoice'};
% targs = taskList{'graphics'}{'targets'};
% 
% if stimDir == choiceDir
%     targs.color = taskList{'graphics'}{'green'};
% else
%     targs.color = taskList{'graphics'}{'red'};
% end

% disp(['dir: ' num2str(stim.direction) '; coh: ' num2str(stim.coherence) ...
%     '; choice: ' choiceDir]);


function updateData(taskList)
% get the relevant variables from tasklist
stim = taskList{'graphics'}{'stimulus'};

% concatenate w/ old data
dataStim = [taskList{'data'}{'stim'} stim];
dataCoh = [taskList{'data'}{'coh'} stim.coherence];
dataDir = [taskList{'data'}{'dir'} stim.direction];
dataChoice = [taskList{'data'}{'choice'} taskList{'control'}{'currentChoice'}];
dataConf = [taskList{'data'}{'confid'} taskList{'control'}{'currentConfid'}];
    
% update the data in taskList
taskList{'data'}{'stim'} = dataStim;
taskList{'data'}{'coh'} = dataCoh;
taskList{'data'}{'dir'} = dataDir;
taskList{'data'}{'choice'} = dataChoice;
taskList{'data'}{'confid'} = dataConf;

if taskList{'control'}{'debug'}
    disp(['coh: ' num2str(dataCoh(end)) ...
        ', dir: ' num2str(dataDir(end)) ...
        ', choice: ' num2str(dataChoice(end)) ...
        ', confid: ' num2str(dataConf(end))]);
end

function saveToFile(taskList)
% save the trial stimulus train and response in a data struct
% dm = dotsTheDrawablesManager.theObject;
subjName = input('Please type in your initials: ','s');
subjName = lower(subjName);

stim = taskList{'data'}{'stim'};
coh = taskList{'data'}{'coh'};
dir = taskList{'data'}{'dir'};
choice = taskList{'data'}{'choice'};
tcoh = taskList{'data'}{'threshCoh'};
pcoh = taskList{'data'}{'pulseCoh'};
confid = taskList{'data'}{'confid'};

fname = taskList{'control'}{'fname'};
dname = taskList{'control'}{'dirName'};
pfData = struct(...
    'stim', stim,...
    'coh', coh,...
    'dir', dir,...
    'choice', choice,...
    'confid', confid,...
    'tcoh', tcoh,...
    'pcoh', pcoh,...
    'date', now,...
    'subj', subjName  );

save([dname datestr(now,30) '_' subjName '_' fname '.mat'], 'pfData');


function dispPF(taskList)
% display a plot of the psychometric fxn
coh = taskList{'data'}{'coh'};
dir = taskList{'data'}{'dir'};
choice = taskList{'data'}{'choice'};

tcoh = taskList{'data'}{'threshCoh'};
pcoh = taskList{'data'}{'pulseCoh'};

dispPlot = taskList{'control'}{'debug'};            % only displays plots in debug mode
[tcoh, pcoh]=makePF(coh,dir,choice,dispPlot);

taskList{'data'}{'threshCoh'} = tcoh;
taskList{'data'}{'pulseCoh'} = pcoh;


% resets the display
function resetVal(taskList)
targs = taskList{'graphics'}{'targets'};
targs.color = taskList{'graphics'}{'gray'};
targs.dotSize = taskList{'graphics'}{'neutralPixels'};

guessY = taskList{'graphics'}{'guessYes'};
guessN = taskList{'graphics'}{'guessNo'};
guessY.string = 'Yes Guess';
guessN.string = 'No Guess';
taskList{'graphics'}{'guessYes'} = guessY;
taskList{'graphics'}{'guessNo'} = guessN;

taskList{'control'}{'currentChoice'} = NaN;
taskList{'control'}{'currentConfid'} = 0;
taskList{'control'}{'guessFlag'} = 0;

function hideDisp(taskList)
hide(taskList{'graphics'}{'fixation point'});
hide(taskList{'graphics'}{'targets'});
hide(taskList{'graphics'}{'arrow left'});
hide(taskList{'graphics'}{'arrow right'});
hide(taskList{'graphics'}{'stimulus'});
hide(taskList{'graphics'}{'guess'});
hide(taskList{'graphics'}{'guessYes'});
hide(taskList{'graphics'}{'guessNo'});
hide(taskList{'graphics'}{'name'});


function quitTask()
dm = dotsTheDrawablesManager.theObject;
dm.mayDrawNextFrame(false);
error('User quit the task')


function showCount(taskList)
countDown = taskList{'graphics'}{'countDown'};
count = taskList{'control'}{'count'};
x = taskList{'control'}{'x'};

countUp = taskList{'control'}{'countUp'};
disp(['showCount: countUp=' num2str(countUp)]);
countUp = countUp + 1;
taskList{'control'}{'countUp'} = countUp;

check = taskList{'control'}{'check'};
beginTimeMachine = taskList{'control'}{'beginMachine'};
if countUp < x
    show(countDown);
    countDown.string = num2str(count);
    taskList{'graphics'}{'countDown'} = countDown;
    count = count - 1;
    taskList{'control'}{'count'} = count;
    beginTimeMachine.editStateByName('countdown', 'next', 'countdown');
else
    show(countDown);
    check = true;
    taskList{'control'}{'check'} = check;
    beginTimeMachine.editStateByName('countdown', 'next', 'pause');
end

function hideCount(taskList)
countDown = taskList{'graphics'}{'countDown'};
countUp = taskList{'control'}{'countUp'};
check = taskList{'control'}{'check'};
if check == false
    hide(countDown);
else
    hide(countDown);
    countUp = 0;
    taskList{'control'}{'countUp'} = 0;
    check = false;
    taskList{'control'}{'check'} = check;
end
