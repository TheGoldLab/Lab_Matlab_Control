function [taskTree, taskList] = configPulses(baseCoh, pulseCoh,...
    REMOTE_MODE, DEBUG_MODE, FULL_SCREEN, QUERY_CONF, SAVE_MODE)
% Configures a dots kinetogram 2-AFC task that permits construction of the
% psychometric fxn: % correct as fxn of coherence
%
%   To run, type:
%   [taskTree, taskList] = configPulses(threshcoh); taskTree.run;
%   where:
%       threshcoh = coh that gives threshold performance
%       should get threshcoh from running config2afc
%   Saves output data in a file called 'yl_basic....mat' w/ var data
%   
%
%   Code adapted from config2afc
%   Last updated YL 2010-09-10

%% Stuff to control code flow
%% Check var
if nargin < 3
    REMOTE_MODE = 1;
    DEBUG_MODE = 1;
    FULL_SCREEN = 1;
    QUERY_CONF = 1;
    SAVE_MODE = 1;
end

DOTS_RDK = 0;                   % if 1 then use JIG's dotsDrawableRDK class, w/ seed feature
if nargin < 1
    baseCoh = 50;
    pulseCoh = 80;
end

%% Organization:
% a container for all task data and objects
%   partitioned into arbitrary groups
%   viewable with taskList.gui
taskList = topsGroupedList;

% give the task a name, used below
taskName = 'dotsPulses';


%% Constants:
% store some constants in the taskList container
%   used during configuration
%   used while task is running
taskList{'timing'}{'preparation'} = 1;              % fixation duration
taskList{'timing'}{'stimulus'} = 1;                % motion stimulus duration
taskList{'timing'}{'pulse'} = .1;                   % motion pulse duration
taskList{'timing'}{'choice'} = inf;                 % determines how long the targets stay there
taskList{'timing'}{'dClick'} = .5;                  % duration w/i which a double-click counts
taskList{'timing'}{'feedback'} = .5;
taskList{'timing'}{'trialTimeout'} = 600;
taskList{'timing'}{'intertrial'} = .5;
taskList{'timing'}{'tic'} = [];                 % start time for trial (initializaed in startExper)

taskList{'graphics'}{'white'} = [255 255 255];
taskList{'graphics'}{'gray'} = [128 128 128];
taskList{'graphics'}{'red'} = [196 64 32];
taskList{'graphics'}{'green'} = [64 196 32];
taskList{'graphics'}{'pink'} = [255 51 204];
taskList{'graphics'}{'aqua'} = [51 255 204];

taskList{'graphics'}{'stimDiameter'} = 10;      % size of aperture
taskList{'graphics'}{'density'} = 40;               % dots/deg^2/s (Naeker)
taskList{'graphics'}{'speed'} = 4;                  % deg/s (Jazayeri, 2007)
taskList{'graphics'}{'dotSize'} = 3;               % pixel size of individual dots

% the critical motion stimulus parameters
taskList{'stim'}{'basecoh'} = baseCoh;
taskList{'stim'}{'pulsecoh'} = pulseCoh;

taskList{'stim'}{'coh'} = baseCoh;
taskList{'stim'}{'dir'} = [0 180];
if DEBUG_MODE
    taskList{'stim'}{'numpercond'} = 2;                % # of trials per cond
    taskList{'stim'}{'posX'} = [0 -15 15];
    taskList{'stim'}{'posY'} = [0];
else
    taskList{'stim'}{'numpercond'} = 9;                % # of trials per cond
    taskList{'stim'}{'posX'} = [0 -15 15];
    taskList{'stim'}{'posY'} = [0];
end
taskList{'stim'}{'cohToUse'} = baseCoh;                 % trial-by-trial coh
        % (array of indices that refer to actual coh conditions in the {stim}{coh} cell array)
taskList{'stim'}{'dirToUse'} = [];
taskList{'stim'}{'posXToUse'} = [];
taskList{'stim'}{'posYToUse'} = 0;

taskList{'graphics'}{'fixation pixels'} = 10;
taskList{'graphics'}{'leftward'} = 180;
taskList{'graphics'}{'rightward'} = 0;
taskList{'graphics'}{'leftSide'} = -5;
taskList{'graphics'}{'rightSide'} = 5;
taskList{'graphics'}{'neutralPixels'} = [5, 5];
taskList{'graphics'}{'leftBigPixels'} = [30, 5];
taskList{'graphics'}{'rightBigPixels'} = [5, 30];
taskList{'graphics'}{'leftConfidPixels'} = [35, 5];
taskList{'graphics'}{'rightConfidPixels'} = [5, 35];
taskList{'graphics'}{'leftGuessPixels'} = [20, 5];
taskList{'graphics'}{'rightGuessPixels'} = [5, 20];

taskList{'control'}{'blocks per session'} = 1;    % taskTree.iterations
taskList{'control'}{'trials per block'} = ...
    length(taskList{'stim'}{'posX'})*length(taskList{'stim'}{'posY'})*...
    length(taskList{'stim'}{'dir'})*...
    taskList{'stim'}{'numpercond'};               % posTree.iterations
taskList{'control'}{'dirName'} = ...
    '/Volumes/XServerData/Psychophysics/Yin Data/';
taskList{'control'}{'fname'} = 'pos';        % name of file saved to
taskList{'control'}{'trialnum'} = 1;              % an internal counter for how many trials has passed
taskList{'control'}{'segnum'} = 1;             % an internal counter for how many segments w/i a stimulus has passed

taskList{'control'}{'debug'} = DEBUG_MODE;               % set to 1 to display debug-related outputs
taskList{'control'}{'fullscreen'} = FULL_SCREEN;          % set to 1 to display full screen
taskList{'control'}{'remote'} = REMOTE_MODE;            % set to 1 to do remote stuff
taskList{'control'}{'queryConf'} = QUERY_CONF;
taskList{'control'}{'dotsRDK'} = DOTS_RDK;

taskList{'control'}{'currentChoice'} = NaN;
taskList{'control'}{'currentConfid'} = 0;
taskList{'control'}{'guessFlag'} = 0;

% trial data to be stored
taskList{'data'}{'stim'} = [];
taskList{'data'}{'coh'} = [];
taskList{'data'}{'dir'} = [];
taskList{'data'}{'choice'} = [];
taskList{'data'}{'confid'} = [];
taskList{'data'}{'posX'} = [];
taskList{'data'}{'posY'} = [];


%% Graphics:
% create some graphics objects
%   configure them using constants from above
%   store them in the taskList container
dm = dotsTheDrawablesManager.theObject;
% dm.initialize;                              % this clears the manager of previous elements

% decide whether to do things remotely or not
% N.B. reset() also initializes the drawables manager
if taskList{'control'}{'remote'}
    dm.reset('serverMode', false, 'clientMode', true);
else
    dm.reset('serverMode', false, 'clientMode', false);
end

% this bit of code makes display full-screen
if taskList{'control'}{'fullscreen'}
    s = dotsTheScreen.theObject;
    s.displayRect = [];
end

% a fixation point
fp = dm.newObject('dotsDrawableTargets');
fp.color = taskList{'graphics'}{'gray'};
fp.dotSize = taskList{'graphics'}{'fixation pixels'};
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

% RAND DOTS STIMULUS ------------------------------------
% see taskConditions for conditions to be used
if taskList{'control'}{'dotsRDK'}
    stim = dm.newObject('dotsDrawableRDK');
else
    stim = dm.newObject('dotsDrawableDotKinetogram'); 
end
stim.color = taskList{'graphics'}{'white'};
stim.diameter = taskList{'graphics'}{'stimDiameter'};
stim.density = taskList{'graphics'}{'density'};
stim.speed = taskList{'graphics'}{'speed'};
stim.dotSize = taskList{'graphics'}{'dotSize'};
stim.isVisible = false;
% stim.x = -10;
taskList{'graphics'}{'stimulus'} = stim;

% progress text
prog = dm.newObject('dotsDrawableText');
prog.x = 10;
prog.y = -10;
prog.isVisible = false;
taskList{'graphics'}{'progress'} = prog;

% query name text
nameText = dm.newObject('dotsDrawableText');
nameText.x = 0;
nameText.y = 5;
nameText.string = 'Please type your initials and press [ENTER].';
nameText.isVisible = false;
taskList{'graphics'}{'name'} = nameText;

% add all objects to one group, to be drawn simultaneously
dm.addObjectToGroup(fp, taskName);
dm.addObjectToGroup(targs, taskName);
dm.addObjectToGroup(stim, taskName);
dm.addObjectToGroup(prog, taskName);
dm.addObjectToGroup(nameText, taskName);
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
taskTree.name = 'pulse task:';
taskTree.iterations = taskList{'control'}{'blocks per session'};
taskTree.startFevalable = {@startExper, taskList};
taskTree.finishFevalable = {@finishExper, taskList};

% a batch of function calls that apply to all the trial types below
%   start- and finishFevalable get called once per trial
%   any addCall fevalables get called repeatedly during a trial
trialCalls = topsCallList;
trialCalls.name = 'call functions';
trialCalls.alwaysRunning = true;
trialCalls.startFevalable = {@mayDrawNextFrame, dm, true};
trialCalls.addCall({@readData, hid});
trialCalls.finishFevalable = {@mayDrawNextFrame, dm, false};
taskList{'control'}{'trial calls'} = trialCalls;

% each trial type gets its own state machine and tree "branch"
%   state machines share many states

%% Trials to Test Effects of Pulses on Behavior @ Threshold
posMachine = topsStateMachine;
posMachine.name = 'pos trials';

% timing
PT = taskList{'timing'}{'preparation'};         % fixation time
ST = taskList{'timing'}{'stimulus'};               % stim (pulse) time
CT = taskList{'timing'}{'choice'};              % choice time
FT = taskList{'timing'}{'feedback'};            % feedback time
TT = taskList{'timing'}{'trialTimeout'};       % trial timeout (not used)
IT = taskList{'timing'}{'intertrial'};          % inter-trial wait
DT = taskList{'timing'}{'dClick'};              % time to double click

% entry fxn
showStim = {@setStim, taskList};
dispC = {@dispChoice, taskList};                % clears the HID first, then waits for input
dispG = {@dispGuess, taskList};                 % display guess text and targets 
feedback = {@drawCorrectIncorrect, taskList};
ackLeft = {@acknowledgeLeft, taskList};
ackRight = {@acknowledgeRight, taskList};
updateD = {@updateData, taskList};
whichMode = {@decideMode, taskList}; 

% input fxn
QR = {@queryAsOfTime, hid};

fixedStates = { ...
    'name',        'entry',  'timeout', 'input',  'exit',  'next'; ...
    'showFP',       {@show,fp},     PT,     {},     {},    'stimulus';...
    'stimulus',     showStim,       ST,     {},     {@hide,stim},    'choice';...       % loops in stimulus until end of coherence set
    'choice',       dispC,          CT,     QR,     {},    'gchoice,';...
    'gchoice',      dispG,          DT,     QR,     {},    'feedback';...     % hi-jacking the 'guess' module for double-clicking
    'leftward',     ackLeft,        0,      {},     {},    'responded';...
    'rightward',    ackRight,       0,      {},     {},    'responded';...
    'responded',    whichMode,      0,      {},   {@hide, fp},    '';...  % if in guess mode -> time for feedback
    'feedback',     feedback,       FT,     {},     {},    'updateData';...
    'updateData',   updateD,        IT,     {},     {},    '';...
    'quit',         {@quitTask},    0,      {},     {},    '';...
};

posMachine.addMultipleStates(fixedStates);
posMachine.startFevalable = {@startTrial, taskList};
posMachine.finishFevalable = {@finishTrial, taskList};
taskList{'control'}{'posMachine'} = posMachine;

posConcurrents = topsConcurrentComposite;
posConcurrents.name = 'pulseCurrents';
posConcurrents.addChild(dm);
posConcurrents.addChild(trialCalls);
posConcurrents.addChild(posMachine);

% add a branch to the tree trunk to launch a psychometric fxn trial
posTree = taskTree.newChildNode;
posTree.name = 'posTree';
posTree.iterations = taskList{'control'}{'trials per block'};    
% fixedTree.addChild(taskConditions);
posTree.addChild(posConcurrents);
posTree.startFevalable = {@startPosTask, taskList};     % here I shuffle the list of stim parameters to use

%% Save the Data
if SAVE_MODE
    saveMachine = topsStateMachine;
    saveMachine.name = 'save data to file';

    nameText = taskList{'graphics'}{'name'};

    saveStates = {...
        'name',     'entry',     'timeout','input', 'exit', 'next';...
        'queryName',{@show,nameText},    0,     {},     {}, 'save';
        'save', {@saveToFile, taskList}, 0,     {},     {}, 'disp';...
        'disp', {@dispResults, taskList},0,     {},     {},     '';...
        'quit', {@quitTask},             0,     {},     {},     '';...
        };

    saveMachine.addMultipleStates(saveStates);
    taskList{'control'}{'save machine'} = saveMachine;

    saveConcurrents = topsConcurrentComposite;
    saveConcurrents.name = 'saveConcurrents:';
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

% close the screen
dm = dotsTheDrawablesManager.theObject;
dm.closeScreenWindow;

% end the timer
secElapsed = toc(taskList{'timing'}{'tic'});
minElapsed = round(secElapsed/60);
if minElapsed > 1;
    disp(['Time elapsed: ' num2str(minElapsed) ' min.']);
else
    disp(['Time elapsed: ' num2str(secElapsed) ' sec.']);
end

function startPosTask(taskList)
% start of the posMachine
% generate shuffled list of pos/dir here
stimPosX = taskList{'stim'}{'posX'};
stimDir = taskList{'stim'}{'dir'};
numpercond = taskList{'stim'}{'numpercond'};

[posXToUse, dirToUse] = pairshuffle(stimPosX, stimDir, numpercond);

taskList{'stim'}{'posXToUse'} = posXToUse;
taskList{'stim'}{'dirToUse'} = dirToUse;


function startTrial(taskList)
hid = taskList{'input'}{'using'};
hid.flushData;

resetVal(taskList);
hideDisp(taskList);

function finishTrial(taskList)
taskList{'control'}{'trialnum'} = taskList{'control'}{'trialnum'}+1;
% hideDisp(taskList);
WaitSecs(taskList{'timing'}{'intertrial'});


%% Key Function that Updates Stimulus Parameters
% the logic is that of 2 for loops:
%   1. trialnum controls looping across trials
%   2. segnum controls looping w/i a trial
function setStim(taskList)
% get the relevant variables from tasklist
trialnum = taskList{'control'}{'trialnum'};          % intertrial counter
% segnum = taskList{'control'}{'segnum'};            % intratrial counter
stim = taskList{'graphics'}{'stimulus'};            % the current stimulus object
% coh = taskList{'stim'}{'coh'};                      % cell array of stim parameters
cohToUse = taskList{'stim'}{'cohToUse'};             % the parameters are already shuffled
dirToUse = taskList{'stim'}{'dirToUse'};
posXToUse = taskList{'stim'}{'posXToUse'};
posYToUse = taskList{'stim'}{'posYToUse'};
machine = taskList{'control'}{'posMachine'};

% update parameters of the current stimulus
stim.coherence = cohToUse;
stim.direction = dirToUse(trialnum);
stim.x = posXToUse(trialnum);
stim.y = posYToUse;

% if segnum == 1
    if taskList{'control'}{'dotsRDK'}
    stim.seed = sum(clock);                 % only set seed once per trial
    end
    stim.prepareToDrawInWindow;
    stim.show;                              % only invoke this once per trial
 
    % update progress text
    prog = taskList{'graphics'}{'progress'};
    prog.string = [num2str(trialnum) '/' num2str(length(posXToUse))];
    if taskList{'control'}{'debug'}
        prog.show;
    end
    taskList{'graphics'}{'progress'} = prog;
% end
taskList{'graphics'}{'stimulus'} = stim;    % make sure to always update the stimulus
% taskList{'control'}{'trial

% update the counters
% totsegs = length(coh{cohToUse(trialnum)});          % total # of segments w/i trial

% if segnum < totsegs
%     % just update the w/i trial counter & repeat the state
%     taskList{'control'}{'segnum'} = segnum+1;
%     machine.editStateByName('stimulus','next','stimulus');
%     taskList{'control'}{'posMachine'} = machine;
% else
    % we have reached the last segment of the current stimulus
    % => time to advance to the next state
%     taskList{'control'}{'trialnum'} = trialnum+1;   % update in the finish trial fxn
%     taskList{'control'}{'segnum'} = 1;
%     machine.editStateByName('stimulus','next','choice');
%     taskList{'control'}{'posMachine'} = machine;
%     
%     % and hide the stimulus
%     stim.hide;
% end

function dispChoice(taskList)
% flush the input (we only care about choice after sbj has seen everything)
hid = taskList{'input'}{'using'};
hid.flushData;

% display the choice targets
targs = taskList{'graphics'}{'targets'};
targs.show;
if taskList{'control'}{'debug'}
  disp('dispChoice()');
end

function dispGuess(taskList)
% flush the input (we only care about choice after sbj has seen everything)
hid = taskList{'input'}{'using'};
hid.flushData;

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
end

function decideMode(taskList)
% called by responded state - which is the state after ackL/R
% if guess mode -> set next state as feedback
% otherwise, just go to gchoice
machine = taskList{'control'}{'posMachine'};

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

taskList{'control'}{'posMachine'} = machine;

function drawCorrectIncorrect(taskList)
stim = taskList{'graphics'}{'stimulus'};
stimDir = stim.direction;

choiceDir = taskList{'control'}{'currentChoice'};
targs = taskList{'graphics'}{'targets'};
if stimDir == choiceDir
    targs.color = taskList{'graphics'}{'green'};
else
    targs.color = taskList{'graphics'}{'red'};
end


function updateData(taskList)
% get the relevant variables from tasklist
stim = taskList{'graphics'}{'stimulus'};
trialnum = taskList{'control'}{'trialnum'};

% concatenate w/ old data
dataStim = [taskList{'data'}{'stim'} stim];
dataCoh = [taskList{'data'}{'coh'} stim.coherence];   
dataDir = [taskList{'data'}{'dir'} stim.direction];
dataChoice = [taskList{'data'}{'choice'} taskList{'control'}{'currentChoice'}];
dataConf = [taskList{'data'}{'confid'} taskList{'control'}{'currentConfid'}];
dataPosX = [taskList{'data'}{'posX'} stim.x];
dataPosY = [taskList{'data'}{'posY'} stim.y];

% update the data in taskList
taskList{'data'}{'stim'} = dataStim;
taskList{'data'}{'coh'} = dataCoh;
taskList{'data'}{'dir'} = dataDir;
taskList{'data'}{'choice'} = dataChoice;
taskList{'data'}{'confid'} = dataConf;
taskList{'data'}{'posX'} = dataPosX;
taskList{'data'}{'posY'} = dataPosY;

if taskList{'control'}{'debug'}
    disp(['updateData() coh: ' num2str(dataCoh(end)) ...
        ', dir: ' num2str(dataDir(end)) ...
        ', pos: (' num2str(dataPosX(end)) ',' num2str(dataPosY(end)) ')'...
        ', choice: ' num2str(dataChoice(end)) ...
        ', confid: ' num2str(dataConf(end))]);
end

function saveToFile(taskList)
% save the trial stimulus train and response in a data struct
subjName = input('Please type in your initials: ','s');
subjName = lower(subjName);

stim = taskList{'data'}{'stim'};
coh = taskList{'data'}{'coh'};
dir = taskList{'data'}{'dir'};
posX = taskList{'data'}{'posX'};
posY = taskList{'data'}{'posY'};
choice = taskList{'data'}{'choice'};
% cohcode = taskList{'stim'}{'coh'};
% tcoh = taskList{'data'}{'threshCoh'};
% pcoh = taskList{'data'}{'pulseCoh'};
confid = taskList{'data'}{'confid'};

fname = taskList{'control'}{'fname'};
dname = taskList{'control'}{'dirName'};
posData = struct(...                      % pdata = 'pulse data'
    'stim', stim,...
    'coh', coh,...                      % coded as '1' '2' '3', etc.
    'dir', dir,...
    'posX', posX,...
    'posY', posY,...
    'choice', choice,...
    'confid', confid,...
    'date', now,...
    'subj', subjName  );
 
save([dname datestr(now,30) '_' subjName '_' fname '.mat'], 'posData');

function dispResults(taskList)
% display a plot of the psychometric fxn
dir = taskList{'data'}{'dir'};
choice = taskList{'data'}{'choice'};
posX = taskList{'data'}{'posX'};

s = posX;
r = choice == dir;
d=[s',r'];
d2=quick_formatData_yl(d);
figure;
h(1)=plot(d2(:,1),d2(:,2),'.b','MarkerSize',5); hold on;
plot([-1 1]*100, [.5 .5],':k');         % plot the 'chance' line
plot([0 0], [0 1],':k');                   % plot the zero line
xlabel('stimulus position');
ylabel('% correct');

% dispPulses(coh,cohcode,dir,choice);


% resets the display
function resetVal(taskList)
targs = taskList{'graphics'}{'targets'};
targs.color = taskList{'graphics'}{'gray'};
targs.dotSize = taskList{'graphics'}{'neutralPixels'};

taskList{'control'}{'currentChoice'} = NaN;
taskList{'control'}{'currentConfid'} = 0;
taskList{'control'}{'guessFlag'} = 0;

function hideDisp(taskList)
hide(taskList{'graphics'}{'fixation point'});
hide(taskList{'graphics'}{'targets'});
hide(taskList{'graphics'}{'stimulus'});
hide(taskList{'graphics'}{'name'});


function quitTask()
dm = dotsTheDrawablesManager.theObject;
dm.mayDrawNextFrame(false);
error('User quit the task')