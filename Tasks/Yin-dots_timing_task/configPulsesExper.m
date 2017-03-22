function [sessionTree, tList] = configPulsesExper()
% Configures a full pulses experiment with the following layout:
%
% session: sessionTree
% blocks:
%   1. Quest Stim 1
%   2. Quest Stim 2
%   3. Pulse Stim 1 x 4 iterations
%   4. Quest Stim 1
%
%   Don't forget: also need instructions!!
%   To run, type:
%       [sessionTree, tList] = configQuest;
%       sessionTree.run;
%   
%
%   Code adapted from configureDots2afcTask from snow dots demo
%   2010-09-20:  uses double-click to indicate confidence
%   2010-09-29:  implement QUEST
%   2010-10-07:  implement new structure that puts all the settings in
%   functions
%   2010-10-08:  implement mechanism to save files
%   2010-10-11:  implement a rough 'count down'
%   2010-10-13:  added Pulse blocks
%   2010-10-18:  implement new Quest method (altered spacing + 'noise')
%   2010-10-19:  can present stimuli @ 2 locale
%   2010-10-20:  stores stim pos, block duration, block #

%% Stuff to control code flow
REMOTE_MODE = 1;
QUERY_CONF = 1;             % run the code for querying confidence
DEBUG_MODE = 0;
FULL_SCREEN = 1;
DOTS_RDK = 0;                   % if 1 then use JIG's dotsDrawableRDK class, w/ seed feature
PULSE_QUEST = 1;                % run code for doing Quest on Pulse coherence

%% Organization:
% a container for all task data and objects
%   partitioned into arbitrary groups
%   viewable with tList.gui

tList = topsGroupedList;

% give the task a name, used below
taskName = 'pulsesExperiment';

%% Constants:
global fastStruct

% constants that control code flow
tList{'control'}{'debug'} = DEBUG_MODE;               % set to 1 to display debug-related outputs
tList{'control'}{'fullscreen'} = FULL_SCREEN;          % set to 1 to display full screen
tList{'control'}{'remote'} = REMOTE_MODE;            % set to 1 to do remote stuff
tList{'control'}{'queryConf'} = QUERY_CONF;      % set to 1 if want to run code to query confidence
tList{'control'}{'dotsRDK'} = DOTS_RDK;
tList{'control'}{'pulseQuest'} = PULSE_QUEST;

% constants that don't change across branches
setListDefaults(tList);

%% Graphics:
% decide whether to do things remotely or not
dm = dotsTheDrawablesManager.theObject;

if tList{'control'}{'remote'}
    dm.reset('serverMode', false, 'clientMode', true);          % reset also initiliaze
else
    dm.reset('serverMode', false, 'clientMode', false);
end

% make the text big!
dm.setScreenTextSetting('TextSize', tList{'graphics'}{'textSize'});


% this bit of code makes display full-screen
if tList{'control'}{'fullscreen'}
    dm.setScreenProperty('displayRect', []);
end

% a fixation point
fp = dm.newObject('dotsDrawableTargets');
fp.color = tList{'graphics'}{'gray'};
fp.dotSize = tList{'graphics'}{'fixationPixels'};
fp.isVisible = false;
tList{'graphics'}{'fixationPoint'} = fp;

% target dots
targs = dm.newObject('dotsDrawableTargets');
targs.color = tList{'graphics'}{'gray'};
targs.dotSize = tList{'graphics'}{'neutralPixels'};
targs.x = tList{'graphics'}{'targX'};
targs.y = tList{'graphics'}{'targY'};
targs.isVisible = false;
tList{'graphics'}{'targets'} = targs;

% dots stimulus
if tList{'control'}{'dotsRDK'}
    stim=dm.newObject('dotsDrawableRDK_yl');
else
    stim = dm.newObject('dotsDrawableDotKinetogram');         % replace dotsDrawableRDK w/ dotsDrawableDotKinetogram
end
stim.color = tList{'graphics'}{'white'};
stim.diameter = tList{'stim'}{'diameter'};
stim.density = tList{'stim'}{'density'};
stim.speed = tList{'stim'}{'speed'};
stim.dotSize = tList{'stim'}{'dotSize'};
stim.x = tList{'stim1'}{'x'};
stim.y = tList{'stim1'}{'y'};
stim.isVisible = false;
tList{'graphics'}{'stim1'} = stim;
tList{'graphics'}{'stimulus'} = stim;                           % this is a handle to the stimulus we are actually using

if tList{'control'}{'dotsRDK'}
    stim2=dm.newObject('dotsDrawableRDK_yl');
else
    stim2 = dm.newObject('dotsDrawableDotKinetogram');         % replace dotsDrawableRDK w/ dotsDrawableDotKinetogram
end
stim2.color = tList{'graphics'}{'white'};
stim2.diameter = tList{'stim'}{'diameter'};
stim2.density = tList{'stim'}{'density'};
stim2.speed = tList{'stim'}{'speed'};
stim2.dotSize = tList{'stim'}{'dotSize'};
stim2.x = tList{'stim2'}{'x'};
stim2.y = tList{'stim2'}{'y'};
stim2.isVisible = false;
tList{'graphics'}{'stim2'} = stim2;

% confidText: to query for confidence
confidText = dm.newObject('dotsDrawableText');
confidText.string = 'Sure?';
confidText.isVisible = false;
tList{'graphics'}{'confidText'} = confidText;

% progText text
progText = dm.newObject('dotsDrawableText');
progText.x = 10;
progText.y = -10;
progText.isVisible = false;
tList{'graphics'}{'progText'} = progText;

% add all objects to one group, to be drawn simultaneously
taskGraphics = tList{'graphics'}{'task'};
dm.addObjectToGroup(fp, taskGraphics);
dm.addObjectToGroup(targs, taskGraphics);
dm.addObjectToGroup(stim, taskGraphics);
dm.addObjectToGroup(stim2, taskGraphics);
dm.addObjectToGroup(progText, taskGraphics);
dm.addObjectToGroup(confidText, taskGraphics);
dm.activateGroup(taskGraphics);

% will also have another set of graphics for instructions
instructText = dm.newObject('dotsDrawableText');
instructText.x = 0;
instructText.y = 0;
instructText.string = 'Please type your initials and press [ENTER]:';
instructText.isVisible = false;
tList{'graphics'}{'instructText'} = instructText;

instructG = tList{'graphics'}{'instruction'};
dm.addObjectToGroup(instructText, instructG);
dm.activateGroup(instructG);

%% Input:
% create input object
qm = dotsTheQueryablesManager.theObject;
gp = qm.newObject('dotsQueryableHIDGamepad');
tList{'input'}{'gamepad'} = gp;
if gp.isAvailable
    left = gp.phenomenons{'pressed'}{'pressed_button_5'};   % L finger key
    right = gp.phenomenons{'pressed'}{'pressed_button_6'};  % R finger key
    
    % 'escape' key
    pressL = gp.phenomenons{'axes'}{'any_axis'};  % left set of keys
    pressR = gp.phenomenons{'pressed'}{'any_pressed'};  % right set
    quit = dotsPhenomenon.composite([pressL,pressR],'intersection');
    
    % any key
    any = dotsPhenomenon.composite([left,right,pressL,pressR],'union');

    hid = gp;
else
    kb = qm.newObject('dotsQueryableHIDKeyboard');
    tList{'input'}{'keyboard'} = kb;
    left = kb.phenomenons{'pressed'}{'pressed_KeyboardLeftArrow'};
    right = kb.phenomenons{'pressed'}{'pressed_KeyboardRightArrow'};
    quit = kb.phenomenons{'pressed'}{'pressed_KeyboardEscape'};

    any = dotsPhenomenon.composite([left,right],'union');
    
    hid = kb;
end
tList{'input'}{'using'} = hid;
% classify phenomenons to produce arbitrary outputs
%   each output will match a state name, below
hid.addClassificationInGroupWithRank(left, 'leftward', taskName, 2);
hid.addClassificationInGroupWithRank(right, 'rightward', taskName, 3);
hid.addClassificationInGroupWithRank(quit, 'quit', taskName, 4);
hid.addClassificationInGroupWithRank(any, 'anyPressed', taskName, 1);
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
%   store them in the tList container

% the trunk of the tree, branches are added below
sessionTree = topsTreeNode;
sessionTree.name = 'sessionTree';
sessionTree.iterations = 1;
sessionTree.startFevalable = {@startSession, tList};
sessionTree.finishFevalable = {@finishSession, tList};


% a batch of function calls that apply to all the trial types below
%   start- and finishFevalable get called once per trial
%   any addCall fevalables get called repeatedly during a trial
trialCalls = topsCallList;
trialCalls.name = 'call functions';
trialCalls.alwaysRunning = true;
% trialCalls.startFevalable = {@mayDrawNextFrame, dm, true};        % not in MN's code
trialCalls.addCall({@readData, hid});
trialCalls.addCall({@mayDrawNextFrame,dm});
% trialCalls.finishFevalable = {@mayDrawNextFrame, dm, false};
tList{'control'}{'trial calls'} = trialCalls;

%% Start Block asks for some information to be used by everyone
startMachine = topsStateMachine;
startMachine.name = 'startMachine';
sName = {@showName, tList};
qName = {@queryName, tList};
startStates = { ...
    'name',    'entry',   'timeout', 'input', 'exit',  'next'; ...
    'showName',  sName,    0,         {},      {},  'queryName';...
    'queryName', qName,    0,         {},      {},         '';...   % place to put instructions
};
startMachine.addMultipleStates(startStates);

startCc = topsConcurrentComposite;
startCc.name = 'startCc';
startCc.addChild(dm);
startCc.addChild(trialCalls);
startCc.addChild(startMachine);

sessionTree.addChild(startCc);


%% Trials to Establish the Threshold Coherence for Stim 1
questBlock = sessionTree.newChildNode;
questBlock.name = 'questBlock';
questBlock.iterations = tList{'control'}{'numQuestBlocks'};
questBlock.startFevalable = {@startQuestBlocks, tList};

% count down machine
countDownM = topsStateMachine;
countDownM.name = 'countDownM';

wStart = {@waitStart,tList};
cDown = {@startCountDown,tList};
cCount = {@checkCountDown,tList};

% input fxn
QR = {@queryAsOfTime, hid};

cdStates = { ...
    'name',     'entry','timeout','input', 'exit', 'next';...
    'waitStart',  wStart,   inf,    QR,       {},  '';...
    'countDown',  cDown,        1,     {}, cCount, 'checkCount';...
    'leftward',      {},        0,     {},     {}, 'anyPressed';...
    'rightward',     {},        0,     {},     {}, 'anyPressed';...
    'checkCount',    {},        0,     {},     {}, '';...
    'anyPressed',    {},        0,     {},      {}, 'countDown';...
    };

countDownM.addMultipleStates(cdStates);
tList{'control'}{'countDownM'} = countDownM;

countDownCc = topsConcurrentComposite;
countDownCc.name = 'countDownCc';
countDownCc.addChild(dm);   
countDownCc.addChild(trialCalls);
countDownCc.addChild(countDownM);

questBlock.addChild(countDownCc);

% quest trials stuff
questTrial = questBlock.newChildNode;
questTrial.name = 'questTrial';
questTrial.iterations = tList{'control'}{'numQuestTrialsPerBlock'};
questTrial.startFevalable={@startQuestBlock,tList};
questTrial.finishFevalable={@finishQuestBlock,tList};

% quest machine
questTaskM = topsStateMachine;
questTaskM.name = 'questTaskM';

% timing
questTaskM.clockFunction = @()GetSecs*tList{'timing'}{'scaleFactor'};
PT = tList{'timing'}{'fixation'};            % fixation time
ST = tList{'timing'}{'stimulus'};            % stim time
CT = tList{'timing'}{'choice'};              % choice time
DT = tList{'timing'}{'dClick'};              % time to double click
FT = tList{'timing'}{'feedback'};            % feedback time
IT = tList{'timing'}{'intertrial'};

% entry fxn
showStim = {@setStimQuest,tList,questTaskM};                % set stimulus condition
hStim = {@hideStim,tList};
dispC = {@dispChoice, tList};
dispG = {@dispGuess, tList};                 % display guess text and targets 
ackLeft = {@acknowledgeLeft, tList};         % make left bigger
ackRight = {@acknowledgeRight, tList};       % make right bigger
feedback = {@drawCorrectIncorrect, tList};   % give feedback (red vs. green)
whichMode = {@decideMode, tList}; 


questStates = { ...
    'name',         'entry',   'timeout', 'input', 'exit',     'next'; ...
    'showFP',       {@show,fp},     PT,     {},      {},       'stimulus';...
    'stimulus',     showStim,       ST,     {},   hStim,       'choice';...
    'choice',       dispC,          CT,     QR,      {},       'gchoice,';...
    'gchoice',      dispG,          DT,     QR,      {},       'feedback';...     % hi-jacking the 'guess' module for double-clicking
    'leftward',     ackLeft,        0,      {},      {},       'responded';...
    'rightward',    ackRight,       0,      {},      {},       'responded';...
    'responded',    whichMode,      0,      {},   {@hide, fp}, '';...  % if in guess mode -> time for feedback
    'feedback',     feedback,       FT,     {},      {},       '';...
    'quit',         {@quitTask},    0,      {},      {},       '';...
};

questTaskM.addMultipleStates(questStates);
questTaskM.startFevalable = {@startQuestTrial, tList};
questTaskM.finishFevalable = {@finishQuestTrial, tList};
tList{'control'}{'questTaskM'} = questTaskM;

questTaskCc = topsConcurrentComposite;
questTaskCc.name = 'questTaskCc';
questTaskCc.addChild(dm);                                          % not in Matt's code
questTaskCc.addChild(trialCalls);
questTaskCc.addChild(questTaskM);

questTrial.addChild(questTaskCc);


%% Trials to do the pulses
pulseBlock = sessionTree.newChildNode;
pulseBlock.name = 'pulseBlock';
pulseBlock.startFevalable={@startPulseBlocks,tList,pulseBlock};

% add count down machine to the pulseBlock
pulseBlock.addChild(countDownCc);

% pulse trials stuff
pulseTrial = pulseBlock.newChildNode;
pulseTrial.name = 'pulseTrial';
pulseTrial.startFevalable={@startPulseBlock, tList, pulseTrial};
pulseTrial.finishFevalable={@finishPulseBlock, tList};

% pulse machine
pulseTaskM = topsStateMachine;
pulseTaskM.name = 'pulseTaskM';

ST = tList{'timing'}{'dt'};         % 'stim time' is now just 'pulse time'
initStim = {@initStimPulse,tList};
showStim = {@setStimPulse,tList};
cStim = {@checkStimPulse,tList};

pulseStates = {...
    'name',        'entry',  'timeout','input', 'exit',    'next'; ...
    'initialize',   initStim,       0,      {},     {},    'showFP';...
    'showFP',       {@show,fp},     PT,     {},     {},    'stimulus';...
    'stimulus',     showStim,       ST,     {},  cStim,    'checkStim';...       % loops in stimulus until end of coherence set
    'checkStim',    {},             0,      {},     {},    'stimulus';...
    'choice',       dispC,          CT,     QR,     {},    'gchoice,';...
    'gchoice',      dispG,          DT,     QR,     {},    'feedback';...     % hi-jacking the 'guess' module for double-clicking
    'leftward',     ackLeft,        0,      {},     {},    'responded';...
    'rightward',    ackRight,       0,      {},     {},    'responded';...
    'responded',    whichMode,      0,      {}, {@hide, fp},    '';...  % if in guess mode -> time for feedback
    'feedback',     feedback,       FT,     {},     {},         '';...
    'quit',         {@quitTask},    0,      {},     {},         '';...
};

pulseTaskM.addMultipleStates(pulseStates);

pulseTaskM.startFevalable = {@startPulseTrial, tList};
pulseTaskM.finishFevalable = {@finishPulseTrial, tList};
tList{'control'}{'pulseTaskM'} = pulseTaskM;

pulseTaskCc = topsConcurrentComposite;
pulseTaskCc.name = 'pulseTaskCc';
pulseTaskCc.addChild(dm);
pulseTaskCc.addChild(trialCalls);
pulseTaskCc.addChild(pulseTaskM);

pulseTrial.addChild(pulseTaskCc);


function startSession(tList)
% called by startFevalable of toplevel sessionTree

% global SESSION_TIC
% SESSION_TIC = tic;
global fastStruct
tList{'timing'}{'sessionTic'} = tic;
fastStruct.tStamp = [];
fastStruct.t_init = tList{'timing'}{'sessionTic'};

% open the screen
dm = dotsTheDrawablesManager.theObject;
dm.openScreenWindow;

if tList{'control'}{'dotsRDK'}
    stim = tList{'graphics'}{'stimulus'};
    stim.coherence = 50;
     stim.t_init = tic;
end

% set the timing scale of dotsTheDrawablesManager
% dm.clockFunction = @()GetSecs*tList{'timing'}{'scaleFactor'};

% set the timing scales
% ds = dotsTheSwitchboard.theObject;
% cf = @()GetSecs*100;
% ds.setSharedPropertyValue('clockFunction',cf);
% ds.setSharedPropertyValue('windowFrameRate',120);
% stim.windowFrameRate =
% stim.windowFrameRate*tList{'timing'}{'scaleFactor'};     % speed up timing according to scaleFactor

function showName(tList)
% called by startBlock

% activate the instruction graphics
dm = dotsTheDrawablesManager.theObject;
dm.activateGroup(tList{'graphics'}{'instruction'});
show(tList{'graphics'}{'instructText'});

function queryName(tList)
% called by startBlock

% query user name
subj = input('Please enter your name and press [ENTER]: ','s');
tList{'sessionData'}{'subj'} = lower(subj);


function finishSession(tList)
% called by finishFevalable of toplevel sessionTree

% already done in saveToFile()
% close the screen
dm = dotsTheDrawablesManager.theObject;
dm.closeScreenWindow;

% end the timer
% secElapsed = toc(tList{'timing'}{'tic'});
% minElapsed = round(secElapsed/60);
% if tList{'control'}{'debug'}
%     if minElapsed > 1;
%         disp(['Time elapsed: ' num2str(minElapsed) ' min.']);
%     else
%         disp(['Time elapsed: ' num2str(secElapsed) ' sec.']);
%     end
% end

function startQuestBlock(tList)
% called by questTrial.startFevalable
setQuestStim1(tList);

tList{'timing'}{'tic'} = tic;
% fire up the Quest stuff
tGuess = median(log10(tList{'stim'}{'coh'}));
tGuessSD = 2;
pThresh = tList{'stim'}{'pThresh'};
beta = 3.5;
delta = 0.01;
gamma = 0.5;

q = QuestCreate(tGuess,tGuessSD,pThresh,beta,delta,gamma);
q.normalizePdf = 1;
tList{'blockData'}{'q'} = q;

% disp stuff
disp(['--- ' datestr(now,13) ' ' ...
    'blockType: ' tList{'blockData'}{'blockType'} ' ' ...
    'blockNum: ' num2str(tList{'sessionData'}{'blockNum'})]);

function startPulseBlock(tList, node)
% called by pulseTrial.startFevalable
% node = pulseTrial

tList{'blockData'}{'blockType'} = 'Pulse';
tList{'timing'}{'tic'} = tic;

% set the # of times to iterate the Pulse trials
node.iterations = tList{'control'}{'numTrialsPerPulseBlock'};

stimCoh = 1:length(tList{'stim'}{'coh'});
stimDir = tList{'stim'}{'dir'};

if tList{'control'}{'pulseQuest'}
    % {'stim'}{'coh'} that will get changed at the start of each trial
    numPerCond = ceil(node.iterations/(length(stimCoh)*length(stimDir)));
    
    tGuess = median(log10(tList{'stim'}{'pulseCoh'}));
    tGuessSD = 2;
    pThresh = tList{'stim'}{'pPulseThresh'};
    beta = 3.5;
    delta = 0.01;
    gamma = 0.5;
    
    q = QuestCreate(tGuess,tGuessSD,pThresh,beta,delta,gamma);
    q.normalizePdf = 1;
    tList{'blockData'}{'q'} = q;
else
    numPerCond = tList{'stim'}{'numPerCond'};
end

% generate shuffled list of coh/dir here
[cohToUse, dirToUse] = pairshuffle(stimCoh, stimDir,numPerCond);
if length(cohToUse) > node.iterations
    % truncate the lists
    cohToUse = cohToUse(1:node.iterations);
    dirToUse = dirToUse(1:node.iterations);
end

tList{'blockData'}{'cohToUse'} = cohToUse;
tList{'blockData'}{'dirToUse'} = dirToUse;

if tList{'control'}{'debug'}
    disp(['startPulseBlock: ' node.name]);
end

% disp stuff
disp(['--- ' datestr(now,13) ' ' ...
    'blockType: ' tList{'blockData'}{'blockType'} ' ' ...
    'blockNum: ' num2str(tList{'sessionData'}{'blockNum'})]);

function finishQuestBlock(tList)
% called by questTrial.finishFevalable

saveToFile(tList);
resetBlockData(tList);
tList{'sessionData'}{'blockNum'} = tList{'sessionData'}{'blockNum'} + 1;

function finishPulseBlock(tList)
% called by pulseTrial.finishFevalable

saveToFile(tList);
resetBlockData(tList);
tList{'sessionData'}{'blockNum'} = tList{'sessionData'}{'blockNum'} + 1;


function waitStart(tList)
% used by count down
    
instructText = tList{'graphics'}{'instructText'};
instructText.string = ['Press any key to begin task.'];
dm = dotsTheDrawablesManager.theObject;
dm.activateGroup(tList{'graphics'}{'instruction'});
show(instructText);

        

function startCountDown(tList)
% this should only get called for the first trial of a block
counter = tList{'blockData'}{'counter'};

instructText = tList{'graphics'}{'instructText'};
instructText.string = ['The task will begin in ' num2str(counter) ' seconds.'];

if tList{'control'}{'debug'}
    disp(['startCountDown() ' num2str(counter)]);
end

    

function checkCountDown(tList)
% called by count down machine

machine = tList{'control'}{'countDownM'};
counter = tList{'blockData'}{'counter'};

if counter > 1
    counter = counter - 1;
    machine.editStateByName('checkCount', 'next', 'countDown');
else
    counter = tList{'timing'}{'maxCount'};
    hide(tList{'graphics'}{'instructText'});
    machine.editStateByName('checkCount', 'next', '');
end
    
tList{'blockData'}{'counter'} = counter;



function startQuestTrial(tList)
% called by questTaskM.startFevalable
startTrial(tList);

function startPulseTrial(tList)
% called by pulseTaskM.startFevalable
startTrial(tList);

if tList{'control'}{'pulseQuest'}
    q = tList{'blockData'}{'q'};
    pulseCoh = tList{'stim'}{'pulseCoh'};
    baseCoh = tList{'stim'}{'baseCoh'};
    
    % get suggestion from Quest
    tTest = QuestQuantile(q);
    [~,closestCoh_i] = min((log10(pulseCoh)-tTest).^2);
    
    % now we randomly pick an index in a 2-index neighborhood
    cohToUse_i = closestCoh_i + randi(5) - 3; 
    cohToUse_i = max(min(cohToUse_i, length(pulseCoh)), 1);  % bound it from 1 to length of 'coh'
    
    pulseCohToUse = pulseCoh(cohToUse_i);
    tList{'stim'}{'coh'} = makeCohCellArray(baseCoh, pulseCohToUse, tList{'stim'}{'cohTemplate'});
    
    if tList{'control'}{'debug'}
        disp(['startPulseTrial pulseCohToUse = ' num2str(pulseCohToUse)]);
    end
end

function startTrial(tList)
% called by startFevalable of task machines

% activate the task graphics
dm = dotsTheDrawablesManager.theObject;
dm.activateGroup(tList{'graphics'}{'task'});

hid = tList{'input'}{'using'};
hid.flushData;



function finishQuestTrial(tList)
% called by questTaskM.finishFevalable
updateBlockData(tList)

% reset w/i trial data
resetTrialData(tList);
hideDisp(tList);

WaitSecs(tList{'timing'}{'intertrial'});

function finishPulseTrial(tList)
% called by pulseTaskM.finishFevalable
updateBlockData(tList)

% reset w/i trial data
resetTrialData(tList);
hideDisp(tList);

WaitSecs(tList{'timing'}{'intertrial'});



function updateBlockData(tList)
% gets called by the finishTrial functions of each trial type

% get the relevant variables from tList
stim = tList{'graphics'}{'stimulus'};
blockType = tList{'blockData'}{'blockType'};
trialNum = tList{'blockData'}{'trialNum'};

if strcmp(blockType, 'Quest')
    % update Quest
    q = tList{'blockData'}{'q'};
    resp = tList{'trialData'}{'resp'};
    q = QuestUpdate(q,log10(stim.coherence),resp);
    tList{'blockData'}{'q'} = q;
    
    dataThreshEst = [tList{'blockData'}{'threshEst'} 10^QuestMean(q)];
    tList{'blockData'}{'threshEst'} = dataThreshEst;
    
    % concatenate w/ old data
    dataCoh = [tList{'blockData'}{'coh'} stim.coherence];
    dataDir = [tList{'blockData'}{'dir'} stim.direction];
elseif strcmp(blockType, 'Pulse')
    if tList{'control'}{'pulseQuest'}
        % update the Quest struct
        q = tList{'blockData'}{'q'};
        resp = tList{'trialData'}{'resp'};
        
        cohPossible = tList{'stim'}{'coh'};
        machine = tList{'control'}{'pulseTaskM'};
        trialNum = machine.caller.caller.iterationCount;
        cohToUse = tList{'blockData'}{'cohToUse'};
        pulseCoh = max(cohPossible{cohToUse(trialNum)});     % get the curr pulse coherence
        
        q = QuestUpdate(q,log10(pulseCoh),resp);
        tList{'blockData'}{'q'} = q;
        tList{'blockData'}{'threshEst'} = [tList{'blockData'}{'threshEst'} 10^QuestMean(q)];                
        
        % update stimulus parameters
        tList{'blockData'}{'pulseCoh'} = [tList{'blockData'}{'pulseCoh'}...
            pulseCoh];
        tList{'blockData'}{'baseCoh'} = [tList{'blockData'}{'baseCoh'}...
            tList{'stim'}{'baseCoh'}];
    end
    
    % stim parameters for Pulse blocks are preset
    dataCoh = tList{'blockData'}{'cohToUse'};
    dataDir = tList{'blockData'}{'dirToUse'};

else
    if tList{'control'}{'debug'} 
        disp(['updateBlockData() block type' blockType]);
    end
end

% concatenate w/ old data
dataChoice = [tList{'blockData'}{'choice'} tList{'trialData'}{'choice'}];
dataResp = [tList{'blockData'}{'resp'} tList{'trialData'}{'resp'}];
dataConf = [tList{'blockData'}{'confid'} tList{'trialData'}{'confid'}];

if tList{'control'}{'dotsRDK'}
%     dataSeed = [tList{'blockData'}{'seed'} stim.seed];
end

% update the data in tList
tList{'blockData'}{'coh'} = dataCoh;
tList{'blockData'}{'dir'} = dataDir;
tList{'blockData'}{'choice'} = dataChoice;
tList{'blockData'}{'resp'} = dataResp;
tList{'blockData'}{'confid'} = dataConf;
if tList{'control'}{'dotsRDK'}
%     tList{'blockData'}{'seed'} = dataSeed;
end
tList{'blockData'}{'trialNum'} = tList{'blockData'}{'trialNum'}+1;  % no longer needed

if tList{'control'}{'debug'}
    disp(['coh: ' num2str(dataCoh(end)) ...
        ', dir: ' num2str(dataDir(end)) ...
        ', choice: ' num2str(dataChoice(end)) ...
        ', confid: ' num2str(dataConf(end))...
        ]);
end

function setStimQuest(tList, machine)
    
% get the relevant variables from tList
q = tList{'blockData'}{'q'};
trialNum = machine.caller.caller.iterationCount;
stim = tList{'graphics'}{'stimulus'};
coh = tList{'stim'}{'coh'};
dir = tList{'stim'}{'dir'};

% get the suggestion from Quest
tTest = QuestQuantile(q);
[~, closestCoh_i] = min((log10(coh)-tTest).^2);     % find the closest match

% now we randomly pick an index in a 2-index neighborhood
cohToUse_i = closestCoh_i + randi(5) - 3; 
cohToUse_i = max(min(cohToUse_i, length(coh)), 1);  % bound it from 1 to length of 'coh'

% Quest is updated at end of each trial

% set stim's parameters
stim.coherence = coh(cohToUse_i);
stim.direction = dir(randi(length(dir)));           % randomly select an angle from 'dir'

% set the seed
if tList{'control'}{'dotsRDK'}
%     stim.seed = sum(clock);
end

% show the stimulus
show(stim);

% update progText text
progText = tList{'graphics'}{'progText'};
progText.string = [num2str(trialNum) '/' num2str(tList{'control'}{'numQuestTrialsPerBlock'})];
if tList{'control'}{'debug'}
    progText.show;
end

addTimeStamp(tList);

function hideStim(tList)
% called by exit() of 'stimulus' state in questTaskM
hide(tList{'graphics'}{'stimulus'});

function initStimPulse(tList)
% get variables from tList, assign them to fastStruct to improve timing
% performance
global fastStruct
A=0

tic
machine = tList{'control'}{'pulseTaskM'};
trialNum = machine.caller.caller.iterationCount;
stim = tList{'graphics'}{'stimulus'};
coh = tList{'stim'}{'coh'};
cohToUse = tList{'blockData'}{'cohToUse'};
dirToUse = tList{'blockData'}{'dirToUse'};

% fastStruct = [];            % clear it
fastStruct.trialNum = trialNum;
fastStruct.totTrials = length(cohToUse);
fastStruct.segNum = 1;      % always start off w/ 1
fastStruct.coh = coh{cohToUse(trialNum)};
fastStruct.dir = dirToUse(trialNum);
fastStruct.m = machine;
fastStruct.stim = stim;

% set the stim direction here
stim.direction = fastStruct.dir;
toc

function setStimPulse(tList)
global fastStruct

addTimeStamp(tList);
if tList{'control'}{'debug'}
    disp(['setStimPulse start']);
end
% A=1

% tic;
% get the relevant variables from fastStruct
stim = fastStruct.stim;
% toc

% tic
% update parameters of the current stimulus
% for 'pulse Quest' blocks, coh is set in startPulseTrial
stim.coherence = fastStruct.coh(fastStruct.segNum);       % i-th seg in coherence profile
% toc 

if fastStruct.segNum == 1
%     tic
    % stim direction is set in initStimPulse
%     stim.direction = fastStruct.dir;
    stim.show;
    
    % udate progress text
    if tList{'control'}{'debug'}
        prog = tList{'graphics'}{'progText'};
        prog.string = [num2str(fastStruct.trialNum) '/' num2str(fastStruct.totTrials)];
        show(prog); disp(['setStimPulse trialNum = ' num2str(fastStruct.trialNum)]);
    end
%     toc
end

if tList{'control'}{'debug'}
    disp(['setStimPulse end segNum = ' num2str(segNum) ', coh = ' num2str(stim.coherence)]);
end

% tic
% toc

function checkStimPulse(tList)
global fastStruct

% A = 2
% tic
machine = fastStruct.m;
segNum = fastStruct.segNum;
totSegs = length(fastStruct.coh);
% toc

if  segNum < totSegs
    segNum = segNum + 1;
%     tic
    machine.editStateByName('checkStim','next','stimulus');
%     toc
else
    % reached the last seg of current stimulus
    segNum = 1;
%     tic
    machine.editStateByName('checkStim', 'next','choice');
%     toc
%     tic
    hide(fastStruct.stim);
%     toc
end

fastStruct.segNum = segNum;


function startQuestBlocks(tList)
% called by questBlock.startFevalable
tList{'sessionData'}{'blockNum'} = 1;

function startPulseBlocks(tList, node)
% called by pulseBlock.startFevalable
% sets values for ALL the pulse blocks
setPulseBlock(tList);
node.iterations = tList{'control'}{'numPulseBlocks'};
tList{'sessionData'}{'blockNum'} = 1;

if tList{'control'}{'debug'}
    disp(['startPulseBlocks: ' node.name]);
end


% TaskMachine-shared functions
function dispChoice(tList)
addTimeStamp(tList);
     
% flush the input (we only care about choice after sbj has seen everything)
hid = tList{'input'}{'using'};

if tList{'control'}{'debug'}
    disp('dispChoice()1');
    for i = 1:length(hid.trackingTimestamps)
        disp(hid.queryNextTracked);
    end
end

hid.flushData;

% display the choice targets
show(tList{'graphics'}{'targets'});
if tList{'control'}{'debug'}
  disp('dispChoice()2');
end


function dispGuess(tList)
% flush the input (we only care about choice after sbj has seen everything)
hid = tList{'input'}{'using'};
hid.flushData;

% set the guess mode flag
tList{'trialData'}{'confid'} = NaN;       % by default (i.e., no-click), is NaN
tList{'trialData'}{'guessFlag'} = 1;

% show the guess text
show(tList{'graphics'}{'confidText'});

function acknowledgeLeft(tList)
targs = tList{'graphics'}{'targets'};

if tList{'trialData'}{'guessFlag'} == 0
    tList{'trialData'}{'choice'} = 180;    
    targs.dotSize = tList{'graphics'}{'leftBigPixels'};
else
    % sbj is confident if 2nd click is same as first click
    if tList{'trialData'}{'choice'} == 180;
        tList{'trialData'}{'confid'} = 1;
        targs.dotSize = tList{'graphics'}{'leftConfidPixels'};
    else
        % if 2nd click is opposite - sbj is 'guessing'
        tList{'trialData'}{'confid'} = -1;
        targs.dotSize = tList{'graphics'}{'rightGuessPixels'};
    end
end


function acknowledgeRight(tList)
targs = tList{'graphics'}{'targets'};

if tList{'trialData'}{'guessFlag'} == 0
    tList{'trialData'}{'choice'} = 0;    
    targs.dotSize = tList{'graphics'}{'rightBigPixels'};
else
    % sbj is confident if 2nd click is same as first click
    if tList{'trialData'}{'choice'} == 0;
        tList{'trialData'}{'confid'} = 1;
        targs.dotSize = tList{'graphics'}{'rightConfidPixels'};
    else
        % if 2nd click is opposite - sbj is 'guessing'
        tList{'trialData'}{'confid'} = -1;
        targs.dotSize = tList{'graphics'}{'leftGuessPixels'};
    end
end


function decideMode(tList)
% called by responded state - which is the state after ackL/R
% ONLY query confidence in 2/3 cases.  So:
    % if guess mode or rand > 2/3 -> set next state as feedback
% otherwise, just go to gchoice
if strcmp(tList{'blockData'}{'blockType'}, 'Quest')
    machine = tList{'control'}{'questTaskM'};
elseif strcmp(tList{'blockData'}{'blockType'}, 'Pulse')
    machine = tList{'control'}{'pulseTaskM'};
else
    if tList{'control'}{'debug'}
        disp('decideMode - the block is of unknown type!');
    end
end

if tList{'control'}{'debug'}
    disp(['decidemode demo: guessFlag' num2str(tList{'trialData'}{'guessFlag'})]);
end

if tList{'control'}{'queryConf'}
    % get feedback if the last task was query confidence OR 
    % if last task was L/R decision, but rand > desired frequency of querying confidence
    if tList{'trialData'}{'guessFlag'} || rand > tList{'control'}{'freqConfidQuery'};
        hide(tList{'graphics'}{'confidText'});
        machine.editStateByName('responded','next','feedback');
    else
        machine.editStateByName('responded','next','gchoice');
    end
else
    machine.editStateByName('responded','next','feedback');
end

function drawCorrectIncorrect(tList)
% here is where we figure out whether the subject's choice matches the dir
% and set 'resp' = 1 if correct, 0 if incorrect


stim = tList{'graphics'}{'stimulus'};
stimDir = stim.direction;

choiceDir = tList{'trialData'}{'choice'};
targs = tList{'graphics'}{'targets'};

resp = sign(cos(stimDir/(180/pi))) == sign(cos(choiceDir/(180/pi)));
tList{'trialData'}{'resp'} = resp;
if resp
    targs.color = tList{'graphics'}{'green'};
else
    targs.color = tList{'graphics'}{'red'};
end

function saveToFile(tList)
% save the trial stimulus train and response in a data struct

% ideally:
% 1. load the file from disk (if available)
% 2. concatenate this data struct to existing one - as a cell array
% 3. in data struct, include information about type of trial, and ID of
% trial (e.g., 3rd Pulse Trial)
% 4. save the data cell array back into the file

% organize into struct

global fastStruct;
stim = tList{'graphics'}{'stimulus'};

% common to both block types
coh = tList{'blockData'}{'coh'};
dir = tList{'blockData'}{'dir'};
choice = tList{'blockData'}{'choice'};
resp = tList{'blockData'}{'resp'};
confid = tList{'blockData'}{'confid'};
seed = tList{'blockData'}{'seed'};
subj = tList{'sessionData'}{'subj'};
bType = tList{'blockData'}{'blockType'};
bNum = tList{'sessionData'}{'blockNum'};
tElapsed = toc(tList{'timing'}{'tic'});
tStamp = fastStruct.tStamp; %tList{'timing'}{'timestamp'};
stimX = stim.x;
stimY = stim.y;
% dataLog = topsDataLog.getSortedDataStruct;

% flush the data log (should save faster now)
% topsDataLog.flushAllData;

blockData = struct(...
    'coh', coh,...
    'dir', dir,...
    'pos', [stimX stimY],...
    'seed', seed,...
    'choice', choice,...
    'resp', resp,...
    'confid', confid,...
    'date', now,...
    'subj', subj,...
    'blockType', bType,...
    'blockNum', bNum,...
    'duration', tElapsed,...
    'tStamp', tStamp);
%     'dataLog', dataLog);

if tList{'control'}{'dotsRDK'}
    blockData.frameTime = stim.frameTime;
end

if strcmp(bType,'Quest')
    % unique to Quest blocks
    q = tList{'blockData'}{'q'};
    qThresh = tList{'blockData'}{'threshEst'};
    
    blockData.q = q;
    blockData.qThresh = qThresh;
elseif strcmp(bType, 'Pulse')
    % unique to Pulse blocks
    blockData.cohCode = tList{'stim'}{'coh'};
    blockData.baseCoh = tList{'blockData'}{'baseCoh'};
    blockData.pulseCoh = tList{'blockData'}{'pulseCoh'};
    blockData.deltaT = tList{'timing'}{'dt'};
    
    if tList{'control'}{'pulseQuest'}
        % unique to pulse Quest blocks
        blockData.cohCode = tList{'stim'}{'cohTemplate'};
        blockData.q = tList{'blockData'}{'q'};
        blockData.qThresh = tList{'blockData'}{'threshEst'};
    end
end

% get the file name
fnamePre = tList{'control'}{'fnamePre'};
fnamePost = tList{'control'}{'fnamePost'};
dname = tList{'control'}{'dirName'};
fname = [dname fnamePre '_' subj '_' fnamePost '.mat'];

% try to load the file
data = {};
if exist(fname,'file')
    d = load(fname,'data');
    data = d.data;
end
data = [data blockData];

save(fname, 'data');


% resets the display
function resetVal(tList)
targs = tList{'graphics'}{'targets'};
targs.color = tList{'graphics'}{'gray'};
targs.dotSize = tList{'graphics'}{'neutralPixels'};

tList{'trialData'}{'choice'} = NaN;
tList{'trialData'}{'confid'} = NaN;
tList{'trialData'}{'guessFlag'} = 0;


function hideDisp(tList)
hide(tList{'graphics'}{'fixationPoint'});
hide(tList{'graphics'}{'targets'});
hide(tList{'graphics'}{'stimulus'});


function cohCellArray = makeCohCellArray(baseCoh, pulseCoh, template)
% makes the coherence cell array using the specified baseCoh, pulseCoh and
% template, which is a cell array, e.g.,
%  template = {[1 0 0 0], [0 1 0 0]}, where 1 = pulse, 0 = base

deltaCoh = pulseCoh-baseCoh;

for i = 1:length(template)
    cohCellArray{i} = template{i}*deltaCoh + baseCoh;
end

function addTimeStamp(tList)
global fastStruct
fastStruct.tStamp = [fastStruct.tStamp toc(fastStruct.t_init)];
% tList{'timing'}{'timestamp'} = [tList{'timing'}{'timestamp'}...
%     toc(tList{'timing'}{'sessionTic'})];


function quitTask()
dm = dotsTheDrawablesManager.theObject;
dm.mayDrawNextFrame(false);
error('User quit the task')

function setListDefaults(tList)
tList{'control'}{'dirName'} = ...
    '/Volumes/XServerData/Psychophysics/Yin Data/';
tList{'control'}{'fnamePre'} = datestr(now,30);       % string to pre-fix to filename
tList{'control'}{'fnamePost'} = 'exper';              % string to post-fix to filename
tList{'control'}{'freqConfidQuery'} = 1/2;            % frequency of querying confidence

tList{'timing'}{'fixation'} = 1;                      % fixation duration
tList{'timing'}{'stimulus'} = .5;                     % motion stimulus duration
tList{'timing'}{'dt'} = .1;                           % pulse step
tList{'timing'}{'choice'} = inf;                      % how long sbj gets to make choice
tList{'timing'}{'dClick'} = inf;                      % how long sbj gets to give confidence
tList{'timing'}{'feedback'} = .5;
tList{'timing'}{'trialTimeout'} = 600;
tList{'timing'}{'intertrial'} = .5;
tList{'timing'}{'maxCount'} = 3;                      % start # for countdowns

tList{'timing'}{'tic'} = [];                          % set at start of each block
tList{'timing'}{'sessionTic'} = [];                   % set at start of the whole session
tList{'timing'}{'timestamp'} = [];                    % add another timestamp for w/i program
tList{'timing'}{'scaleFactor'} = 1;                   % <1 means slower, >1 means faster - amount by which to speed up the timing


tList{'graphics'}{'white'} = [255 255 255];
tList{'graphics'}{'gray'} = [128 128 128];
tList{'graphics'}{'red'} = [196 64 32];
tList{'graphics'}{'green'} = [64 196 32];

tList{'stim'}{'diameter'} = 10;             % size of aperture
tList{'stim'}{'density'} = 40;                  % dots/deg^2/s
tList{'stim'}{'speed'} = 6;                     % deg/s
tList{'stim'}{'dotSize'} = 3;                   % pixel size of individual dots

tList{'graphics'}{'textSize'} = 30;
tList{'graphics'}{'targX'} = [-5 5];               % x-values of target
tList{'graphics'}{'targY'} = [-5 5];
tList{'graphics'}{'fixationPixels'} = 10;       % pixel size of fixation
tList{'graphics'}{'neutralPixels'} = [5, 5];    % when targets are 'neutral'
tList{'graphics'}{'leftBigPixels'} = [25, 5];
tList{'graphics'}{'rightBigPixels'} = [5, 25];
tList{'graphics'}{'leftConfidPixels'} = [35, 5];
tList{'graphics'}{'rightConfidPixels'} = [5, 35];
tList{'graphics'}{'leftGuessPixels'} = [20, 5];
tList{'graphics'}{'rightGuessPixels'} = [5, 20];

% stimulus positions
tList{'stim1'}{'x'} = 0;
tList{'stim1'}{'y'} = 5;
tList{'stim2'}{'x'} = 0;
tList{'stim2'}{'y'} = -5;

% names for diff graphics groups
tList{'graphics'}{'task'} = 'taskGraphics';
tList{'graphics'}{'instruction'} = 'instructionGraphics';

tList{'sessionData'}{'subj'} = [];

% control settings
if tList{'control'}{'debug'}
    tList{'control'}{'numQuestBlocks'}=1;
    tList{'control'}{'numQuestTrialsPerBlock'}=2;
    
    
    tList{'control'}{'numPulseBlocks'} = 1;
else
    tList{'control'}{'numQuestBlocks'}=1;
    tList{'control'}{'numQuestTrialsPerBlock'}=40;
    
    
    tList{'control'}{'numPulseBlocks'} = 1;
end

% session data accumulates across blocks
% tList{'sessionData'}{'initQuest1'} = [];            % data from Quest Stim 1 as a 'struct'
tList{'sessionData'}{'blockNum'} = 1;               % resets when block type changes (e.g. Quest -> Pulse)

resetTrialData(tList);
resetBlockData(tList);

function resetTrialData(tList)
% trial data gets updated every trial
if containsMnemonicInGroup(tList,'targets','graphics')
    if tList{'control'}{'debug'}
        disp('resetTrialData() - graphics.targets');
    end
    targs = tList{'graphics'}{'targets'};
    targs.color = tList{'graphics'}{'gray'};
    targs.dotSize = tList{'graphics'}{'neutralPixels'};
end

tList{'trialData'}{'choice'} = NaN;
tList{'trialData'}{'resp'} = NaN;
tList{'trialData'}{'confid'} = NaN;             
tList{'trialData'}{'guessFlag'} = 0;            % set to 1 if machine in guess/confidence mode
tList{'trialData'}{'segNum'} = 1;

function resetBlockData(tList)
% block data accumulates across trials, but gets refreshed across blocks
tList{'blockData'}{'counter'} = tList{'timing'}{'maxCount'};      % count down timer
tList{'blockData'}{'blockType'} = [];
tList{'blockData'}{'trialNum'} = 1;
tList{'blockData'}{'q'} = [];
tList{'blockData'}{'threshEst'} = [];
tList{'blockData'}{'coh'} = [];
tList{'blockData'}{'baseCoh'} = [];
tList{'blockData'}{'pulseCoh'} = [];
tList{'blockData'}{'dir'} = [];
tList{'blockData'}{'choice'} = [];
tList{'blockData'}{'resp'} = [];
tList{'blockData'}{'confid'} = [];
tList{'blockData'}{'seed'} = [];
tList{'blockData'}{'cohToUse'} = [];
tList{'blockData'}{'dirToUse'} = [];

function setQuestStim1(tList)
% sets the values for Quest Stim 1 block
% idea is that there are block-specific settings
% so each block would have its own function

tList{'blockData'}{'blockType'} = 'Quest';

tList{'stim'}{'coh'} = unique(10.^[linspace(0,1,5),linspace(1,2,10)]);
tList{'stim'}{'dir'} = [45, 45+180];           % angle of dots stimulus
tList{'stim'}{'pThresh'} = dPrimeToPercent(1);     % target pThresh for Quest

% graphics settings
hide(tList{'graphics'}{'stimulus'});
tList{'graphics'}{'stimulus'} = tList{'graphics'}{'stim1'};
hide(tList{'graphics'}{'stimulus'});

% hide(tList{'graphics'}{'stim1'});
tList{'graphics'}{'targX'} = [-5 5];               % x-values of target
tList{'graphics'}{'targY'} = [-5 5];

targs = tList{'graphics'}{'targets'};
targs.x = tList{'graphics'}{'targX'};
targs.y = tList{'graphics'}{'targY'};


function setQuestStim2(tList)
% sets the values for Quest Stim 2 block

tList{'blockData'}{'blockType'} = 'Quest';

tList{'stim'}{'coh'} = unique(10.^[linspace(0,1,5),linspace(1,2,10)]);
tList{'stim'}{'dir'} = [45, 45+180];           % angle of dots stimulus
tList{'stim'}{'pThresh'} = dPrimeToPercent(1);     % target pThresh for Quest

% graphics settings
hide(tList{'graphics'}{'stimulus'});
tList{'graphics'}{'stimulus'} = tList{'graphics'}{'stim2'};
hide(tList{'graphics'}{'stimulus'});

tList{'graphics'}{'targX'} = [-5 5];               % x-values of target
tList{'graphics'}{'targY'} = [5 -5];

targs = tList{'graphics'}{'targets'};
targs.x = tList{'graphics'}{'targX'};
targs.y = tList{'graphics'}{'targY'};

function setPulseBlock(tList)
% sets the values for the Pulse blocks

% hard code this, for now
baseCoh = 20;                            % in final version, want d' = 1
baseCoh2 = 15;                           % in final version, want ~d' = 
deltaCoh = 5;

tList{'stim'}{'baseCoh'} = baseCoh;
% tList{'stim'}{'baseCoh2'} = baseCoh2;
tList{'stim'}{'pulseCoh'} = pulseCoh;


tList{'stim'}{'dir'} = [45, 45+180];           % angle of dots stimulus
tList{'graphics'}{'targX'} = [-5 5];           % x-values of targets
tList{'graphics'}{'targY'} = [-5 5];

% stim1 stuff
targs = tList{'graphics'}{'targets'};
targs.x = tList{'graphics'}{'targX'};
targs.y = tList{'graphics'}{'targY'};

hide(tList{'graphics'}{'stimulus'});
tList{'graphics'}{'stimulus'} = tList{'graphics'}{'stim1'};
hide(tList{'graphics'}{'stimulus'});

if tList{'control'}{'pulseQuest'}
    if tList{'control'}{'debug'}
        tList{'stim'}{'cohTemplate'} = {...
            [1 1 1 1 1]};
        tList{'control'}{'numTrialsPerPulseBlock'} = 2;
    else
        tList{'stim'}{'cohTemplate'} = {...
            [1 1 1 1 1] };
        tList{'control'}{'numTrialsPerPulseBlock'} = 10;
%         tList{'stim'}{'cohTemplate'} = {...
%             [1 0 0 0 0], ...
%             [0 1 0 0 0],...
%             [0 0 1 0 0],...
%             [0 0 0 1 0],...
%             [0 0 0 0 1]};
%         tList{'control'}{'numTrialsPerPulseBlock'} = 80;
    end
    tList{'stim'}{'coh'} = tList{'stim'}{'cohTemplate'};
    tList{'stim'}{'numPerCond'} = NaN;          % not relevant for 'pulse Quest' procedure
else
    if tList{'control'}{'debug'}
        tList{'stim'}{'coh'} = {...
            [0 1 0 0 0 ]*deltaCoh + baseCoh};
    %         [0 0 1 0 0 ]*deltaCoh + baseCoh,...
    %         [0 0 0 0 0 ]*deltaCoh + baseCoh2,...
    %         [0 0 1 0 0 ]*deltaCoh + baseCoh2,...
    %         };
        tList{'stim'}{'numPerCond'} = 2;
    else
        tList{'stim'}{'coh'} = {...
            [0 0 0 0 0 ]*deltaCoh + baseCoh,...
            [1 0 0 0 0 ]*deltaCoh + baseCoh,...
            [0 1 0 0 0 ]*deltaCoh + baseCoh,...
            [0 0 1 0 0 ]*deltaCoh + baseCoh,...
            [0 0 0 1 0 ]*deltaCoh + baseCoh,...
            [0 0 0 0 1 ]*deltaCoh + baseCoh};
    %         [0 0 0 0 0 ]*deltaCoh + baseCoh2,...
    %         [1 0 0 0 0 ]*deltaCoh + baseCoh2,...
    %         [0 1 0 0 0 ]*deltaCoh + baseCoh2,...
    %         [0 0 1 0 0 ]*deltaCoh + baseCoh2,...
    %         [0 0 0 1 0 ]*deltaCoh + baseCoh2,...
    %         [0 0 0 0 1 ]*deltaCoh + baseCoh2};
        tList{'stim'}{'numPerCond'} = 9;
    end
    
    tList{'control'}{'numTrialsPerPulseBlock'} = ...
        length(tList{'stim'}{'dir'})*length(tList{'stim'}{'coh'})*...
        tList{'stim'}{'numPerCond'}
end