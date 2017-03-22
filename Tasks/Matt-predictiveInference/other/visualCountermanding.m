function [taskTree, taskList] = visualCountermanding

%% Organization:
% a container for all task data and objects
%   partitioned into arbitrary groups
%   viewable with taskList.gui
taskList = topsGroupedList;
% give the task a name, used below

%% Constants:
% store some constants in the taskList container
%   used during configuration
%   used while task is running
RAND=clock;

taskList{'control'}{'remote client'} = 0;
taskList{'control'}{'trials per block'} = 10;
taskList{'control'}{'blocks per session'} = 1;
taskList{'control'}{'SSDs'} = [.1 .2 .3 .4];
taskList{'control'}{'stop signal ratio'} = 2/5; % ratio: SSD/total
taskList{'control'}{'targ location prob'} = .5;
taskList{'control'}{'fixed trial'} = 0; % should the trial be a fixed amt of time
taskList{'control'}{'data file name'} ='test';
taskList{'control'}{'session time'} = [num2str(RAND(1)) num2str(RAND(2)) num2str(RAND(3)) num2str(RAND(4)) num2str(RAND(5))];

if taskList{'control'}{'fixed trial'} == 0 % if not fixed time
    taskList{'timing'}{'post SS duration'} = 1.5; % stop signal trials only
end

taskList{'input'}{'usingGamepad'} = 0;
taskList{'input'}{'usingKeyboard'} = 1;

taskList{'timing'}{'preparation'} = 1;
taskList{'timing'}{'fixation'} = 1.5;
taskList{'timing'}{'post stimulus'} = 0;
taskList{'timing'}{'post SSD'} = 0;
taskList{'timing'}{'pre-feedback'} = 1;
taskList{'timing'}{'feedback tone'} = 0.2;
taskList{'timing'}{'no SS duration'} = 2; % from time of target onset

taskList{'graphics'}{'full screen'} = 0;
taskList{'graphics'}{'white'} = [255 255 255];
taskList{'graphics'}{'stimulus diameter'} = 10;
taskList{'graphics'}{'fixation point diameter'} = 10;
taskList{'graphics'}{'left side'} = -5;
taskList{'graphics'}{'right side'} = 5;

% isoluminant graphics variables
taskList{'graphics'}{'background checker size'} = 1;
taskList{'graphics'}{'luminance difference'} = 200;
taskList{'graphics'}{'dark'} = [0 0 0];
taskList{'graphics'}{'light'} = repmat(taskList{'graphics'}{'luminance difference'}, 1, 3);
taskList{'graphics'}{'gray'} = [1 1 1].*floor(taskList{'graphics'}{'luminance difference'}./2);

taskList{'eye tracking'}{'on'} = 0; % is the eye tracker on?
taskList{'eye tracking'}{'input window'} = [-13.49 10.95 13.49*2 -10.95*2].*100;
taskList{'eye tracking'}{'xy window'} = [-12 -10 24 20];
taskList{'eye tracking'}{'frame rate'} = 120;
taskList{'eye tracking'}{'fixation window'} = [-3 -3 6 6]; 

taskList{'Tone frequency'}{'error'} = 400;

taskList{'trial variables'}{'targ location'} = 0; % 0 = left
taskList{'trial variables'}{'trial type'} = 0; %    1 = stop signal
taskList{'trial variables'}{'SSD'} = nan; 
taskList{'control'}{'input type'} = 1;

%% Graphics/Sound Objects:
% create some graphics objects
%   configure them using constants from above
%   store them in the taskList container
s = dotsTheScreen.theObject;

% full screen
if taskList{'graphics'}{'full screen'}
    s.displayRect = [];
end

dm = dotsTheDrawablesManager.theObject;
tm = dotsThePlayablesManager.theObject;



% remote client mode  %%%%%CHECK THIS WITH MATT
if taskList{'control'}{'remote client'}
    dotsTheDrawablesManager.reset('serverMode', false, 'clientMode', true);
else
    dotsTheDrawablesManager.reset('serverMode', false, 'clientMode', false);
end

% isoluminant background
chk = taskList{'graphics'}{'background checker size'};
pixBox = s.displayPixels; % ?????
tx = dm.newObject('dotsDrawableTextures');
tx.textureMakerFevalable = {'textureMakerCheckers', chk, chk, [], [], ...
    taskList{'graphics'}{'dark'}, taskList{'graphics'}{'light'}};
taskList{'graphics'}{'background texture'} = tx; 

% a fixation point
fp = dm.newObject('dotsDrawableTargets');
fp.color = taskList{'graphics'}{'gray'};
fp.dotSize = taskList{'graphics'}{'fixation point diameter'};
fp.isVisible = false;
taskList{'graphics'}{'fixation point'} = fp;

% stimulus dot - left
stimLeft = dm.newObject('dotsDrawableTargets');
stimLeft.color = taskList{'graphics'}{'gray'};
stimLeft.dotSize = taskList{'graphics'}{'stimulus diameter'};
stimLeft.x = taskList{'graphics'}{'left side'};
stimLeft.isVisible = false;
taskList{'graphics'}{'left stimulus'} = stimLeft;

% stimulus dot - right
stimRight = dm.newObject('dotsDrawableTargets');
stimRight.color = taskList{'graphics'}{'gray'};
stimRight.dotSize = taskList{'graphics'}{'stimulus diameter'};
stimRight.x = taskList{'graphics'}{'right side'};
stimRight.isVisible = false;
taskList{'graphics'}{'right stimulus'} = stimRight;

% correct sound
correct = tm.newObject('dotsPlayableFile');
correct.fileName = 'Coin.wav';
taskList{'feedback'}{'correct'} = correct;

% incorrect sound
incorrect = tm.newObject('dotsPlayableFile');
incorrect.fileName = 'Pipe_Warp.wav';
taskList{'feedback'}{'incorrect'} = incorrect;

%error tone
error = tm.newObject('dotsPlayableTone');
error.frequency = taskList{'Tone frequency'}{'error'};
error.duration = taskList{'timing'}{'feedback tone'};
error.isAudible = true;
taskList{'feedback'}{'error'} = error;


dm.addObjectToGroup(stimLeft, 'taskGraphics', 2)
dm.addObjectToGroup(stimRight, 'taskGraphics', 3)
dm.addObjectToGroup(fp, 'taskGraphics', 4)
dm.addObjectToGroup(tx, 'taskGraphics', 1)
dm.activateGroup('taskGraphics')


%% Inputs:
% create an input object
% configure it to classify inputs as needed for this task
% store it in the taskList container

qm = dotsTheQueryablesManager.theObject;
if taskList{'input'}{'usingKeyboard'}
    kb = qm.newObject('dotsQueryableHIDKeyboard');
    taskList{'input'}{'keyboard'} = kb;
    left = kb.phenomenons{'pressed'}{'pressed_KeyboardLeftArrow'};
    right = kb.phenomenons{'pressed'}{'pressed_KeyboardRightArrow'};
    hid = kb;
elseif taskList{'input'}{'usingGamepad'}
    gp = qm.newObject('dotsQueryableHIDGamepad');
    taskList{'input'}{'gamepad'} = gp;
    left = gp.phenomenons{'pressed'}{'pressed_button_5'};
    right = gp.phenomenons{'pressed'}{'pressed_button_6'};
    hid = gp;
end

taskList{'input'}{'using'} = hid;

queryResponseGroup = 'keyboard arrows';
hid.addClassificationInGroupWithRank(left, 'pushedLeft', queryResponseGroup, 1);
hid.addClassificationInGroupWithRank(right, 'pushedRight', queryResponseGroup, 2);
hid.activeClassificationGroup = queryResponseGroup;


if taskList{'eye tracking'}{'on'}
    et = qm.newObject('dotsQueryableEyeASL');
    et.inputRect = taskList{'eye tracking'}{'input window'};
    et.xyRect = taskList{'eye tracking'}{'xy window'};
    et.sampleFrequency = taskList{'eye tracking'}{'frame rate'};
    et.initialize;
    taskList{'input'}{'eye tracker'} = et;
    
    temp = et.getPhenomenonTemplate;
    inBox = dotsPhenomenon.rectangle(temp, 'xPos', 'yPos', taskList{'eye traking'}{'fixation window'}, 'in');
    outOfBox = dotsPhenomenon.rectangle(temp, 'xPos', 'yPos', taskList{'eye tracking'}{'fixation window'}, 'out');

    queryETGroup1 = 'fixation';
    queryETGroup2 = 'no fixation';
    et.addClassificationInGroupWithRank(inBox, 'goodfix', queryETGroup1, 1);
    et.addClassificationInGroupWithRank(outOfBox, 'badfix', queryETGroup2, 2);
end

%% Control:

taskTree = topsTreeNode;
taskTree.name = 'countermanding';
taskTree.iterations = taskList{'control'}{'blocks per session'};
taskTree.startFevalable = {@openScreenWindow, dm};
taskTree.finishFevalable = {@closeScreenWindow, dm};

taskCalls = topsCallList;
taskCalls.alwaysRunning = true;
taskCalls.addCall({@receiveTransactions, dm});
taskCalls.addCall({@readData, hid});
if taskList{'eye tracking'}{'on'}
    taskCalls.addCall({@readData, et});
end

taskCalls.addCall({@mayDrawNextFrame, dm});
taskList{'control'}{'task calls'} = taskCalls;

%% State Machine:
countermandingMachine = topsStateMachine;
countermandingMachine.name = 'countermanding';


% entry and exit functions
TP = {@trialPicker,taskList};
SF = {@show,fp};
HF = {@hide,fp};
PE = {@play,error};
ST = {@showTarget,taskList};
SS = {@stopSignal,taskList};
CL = {@clearScreen,taskList};
CI = {@categorizeInput, taskList, hid};
GR = {@grader,taskList};
PT = {@playTone,taskList};
SD = {@storeData,taskList};

% input functions
CFB = {@checkForBadFixation,taskList};
CFG = {@checkForGoodFixation,taskList};

% time delays
prepTime = taskList{'timing'}{'preparation'};
fixTime = taskList{'timing'}{'fixation'};
PSTime = taskList{'timing'}{'post stimulus'};
PSSDTime = taskList{'timing'}{'post SSD'};
PFBTime = taskList{'timing'}{'pre-feedback'};
playTime = taskList{'timing'}{'feedback tone'};

countermandingStates = { ...
    'name',       'entry', 'timeout',  'input',	'exit', 'next'; ...
    'intertrial',  TP,      prepTime,   CFB,     {},    'fixation'; ...
    'fixation',    SF,      fixTime,    CFB,     HF,    'stimulus'; ...
    'badfix',      PE,      1,          CFG,     {},    'badfix'; ...
    'goodfix',     {},      1,          CFB,     {},    'stimulus';...
    'stimulus',    ST,      PSTime,     CFB      {},    'stopSignal'; ...
    'stopSignal',  SS,      PSSDTime,   CFB,     CL,    'score'; ...
    'score',       CI,      PFBTime,    CFB,     GR,    'feedback';...
    'feedback',    PT,      playTime,   CFB,     {},    'storeData';...
    'storeData',   SD,      0,          CFB,     {},    '';...
    };

% add states to state machine
countermandingMachine.addMultipleStates(countermandingStates);
countermandingMachine.startFevalable = {@startTrial, taskList};
countermandingMachine.finishFevalable = {@finishTrial,taskList};
taskList{'control'}{'countermanding machine'} = countermandingMachine;

countermandingSergeant = topsSergeant;
countermandingSergeant.name = 'sergeant_bill';
countermandingSergeant.addChild(taskCalls);
countermandingSergeant.addChild(countermandingMachine);
countermandingSergeant.startFevalable = {@startTrial, taskList};

countermandingTree = taskTree.newChildNode;
countermandingTree.name = 'countermandingTask';

%% if you want to add pre and post block stuff, put it here!
%countermandingTree.finishFevalable = {@finishBlock, taskList};
countermandingTree.startFevalable = {@startBlock, taskList};
countermandingTree.iterations = taskList{'control'}{'trials per block'};
countermandingTree.addChild(countermandingSergeant);
end

%% Functions

function startBlock(taskList)
show(taskList{'graphics'}{'background texture'});
end

function startTrial(taskList)
% do something here.
end

function trialPicker(taskList)


% first, pick a target location
cointoss1 = rand(1);
if cointoss1 > taskList{'control'}{'targ location prob'}
    taskList{'trial variables'}{'targ location'} = 0; % left
else
    taskList{'trial variables'}{'targ location'} = 1; % right
end

% second, decide whether a stop signal will be presented
cointoss2 = rand(1);
if cointoss2 < taskList{'control'}{'stop signal ratio'}
    taskList{'trial variables'}{'trial type'} = 1; % stop signal
else
    taskList{'trial variables'}{'trial type'} = 0; % no stop signal
    taskList{'trial variables'}{'SSD'} = nan;

end
% third, if 2=yes, decide when

cointoss3 = rand(1);
SSDs = taskList{'control'}{'SSDs'};
stepSize = 1/length(SSDs);

for i = 1:length(SSDs)
    if cointoss3 >= (i - 1)*stepSize && cointoss3 < i*stepSize
        taskList{'trial variables'}{'SSD'} = SSDs(i);
        break;
    else 
        taskList{'trial variables'}{'SSD'} = nan;
    end
end

% hide the fixation point;
%hide(taskList{'graphics'}{'fixation point'});


% compute wait times for different states;

if taskList{'trial variables'}{'trial type'} == 0
    taskList{'timing'}{'post stimulus'} = taskList{'timing'}{'no SS duration'};
    disp('post stimulus time computed')
else
    taskList{'timing'}{'post stimulus'} = taskList{'trial variables'}{'SSD'};
    disp('post stimulus time computed')
end

if taskList{'trial variables'}{'trial type'} == 0 %no stop signal
    taskList{'timing'}{'post SSD'} = 0;
    disp('post SSD time computed')
else
    if taskList{'control'}{'fixed trial'} == 1; 
        taskList{'timing'}{'post SSD'} = taskList{'timing'}{'no SS duration'}-taskList{'trial variables'}{'SSD'};
    else
        taskList{'timing'}{'post SSD'} = taskList{'timing'}{'post SS duration'};
    end
    disp('post SSD time computed')
end


countermandingMachine=taskList{'control'}{'countermanding machine'};
countermandingMachine.editStateByName('stimulus', 'timeout',   taskList{'timing'}{'post stimulus'});
countermandingMachine.editStateByName('stopSignal', 'timeout',   taskList{'timing'}{'post SSD'});


end

function showTarget(taskList)
fp = taskList{'graphics'}{'fixation point'};
hide(fp);
if taskList{'trial variables'}{'targ location'} == 0; % left
    show(taskList{'graphics'}{'left stimulus'});
else
    show(taskList{'graphics'}{'right stimulus'});
end
end

function stopSignal(taskList)
if taskList{'trial variables'}{'trial type'} == 1; % stop signal
    show(taskList{'graphics'}{'fixation point'});
end
end

function clearScreen(taskList)
hide(taskList{'graphics'}{'fixation point'});
hide(taskList{'graphics'}{'left stimulus'});
hide(taskList{'graphics'}{'right stimulus'});
end

function categorizeInput(taskList, hid)

% inputType 0: nothing pressed
% inputType 1: right pressed
% inputType 2: left pressed
% inputType 3: both pressed
% inputType -1: something other than left/right pressed

classifyIt = cell(length(hid.trackingTimestamps),1);

for i = 1: length(hid.trackingTimestamps)
    classifyIt{i} = hid.queryNextTracked;
end

topsDataLog.logDataInGroup(classifyIt, 'query classification');


if length(classifyIt) == 0 % nothing pressed
    inputType = 0;
    disp('nothing pushed')
else % something pressed
    if any(strcmp('pushedLeft', classifyIt)) % left pushed
        disp('left pushed')
        if any(strcmp('pushedRight', classifyIt)) % right also pushed
            inputType=3;
        else % only left pushed
            inputType=2;
        end
    elseif any(strcmp('pushedRight', classifyIt)) % right pushed
        disp('right pushed')
        inputType=1;
    else % undesired button pressed
        inputType=-1;
        disp('something else pushed')
    end
end

taskList{'control'}{'input type'} = inputType;
        
end        

function grader(taskList)
inputType = taskList{'control'}{'input type'};           
loc = taskList{'trial variables'}{'targ location'};
stopSignal = taskList{'trial variables'}{'trial type'}; 

if (stopSignal && inputType==0)
% stop signal and nothing pressed
    responseType=1;
    
elseif (stopSignal && inputType~=0)
% stop signal and anything pressed
    responseType=0;
    
elseif (stopSignal==0 && loc && inputType==1)...
        ||(stopSignal==0 && loc==0 && inputType==2)
% no stop signal, stimulus right, right pressed
% no stop signal, stimulus left, left pressed
    responseType=1;
    
elseif(stopSignal==0 && loc && inputType==2) ...
        ||(stopSignal==0 && loc==0 && inputType==1)
% no stop signal, stimulus right, left pressed
% no stop signal, stimulus left, right pressed
    responseType= 0;

elseif (stopSignal==0 && inputType==0)
% no stop signal and nothing pressed
    responseType=-1;

elseif (inputType==3 || inputType==-1)
% both pressed or something else pressed
    responseType=-1;
else
    disp('all cases should have been covered');
   
end

taskList{'trial variables'}{'feedback type'} = responseType;                                 
            
% remember to do this somewhere!!!
%hid.flushdata

end

function playTone(taskList)
tm = dotsThePlayablesManager.theObject;
correct = taskList{'feedback'}{'correct'};
incorrect = taskList{'feedback'}{'incorrect'};
error = taskList{'feedback'}{'error'};

if taskList{'trial variables'}{'feedback type'} == 1
    correct.prepareToPlay;
    tm.mayPlayPlayable(correct);
elseif taskList{'trial variables'}{'feedback type'} == 0
    incorrect.prepareToPlay;
    tm.mayPlayPlayable(incorrect);  
else
    error.prepareToPlay;
    tm.mayPlayPlayable(error);
end
tm.receiveTransactions
disp('tone played')
end

function storeData(taskList)
topsDataLog.logDataInGroup(taskList{'trial variables'}{'targ location'}, 'target location');
topsDataLog.logDataInGroup(taskList{'trial variables'}{'trial type'}, 'trial type'); 
topsDataLog.logDataInGroup(taskList{'trial variables'}{'SSD'}, 'SSD');
topsDataLog.logDataInGroup(taskList{'trial variables'}{'feedback type'}, 'scoreCode')

if taskList{'trial variables'}{'feedback type'} == 1
    score = 'correct';
    
elseif taskList{'trial variables'}{'feedback type'} == 0
    score = 'incorrect';
    
else
    score = 'error';
end


topsDataLog.logDataInGroup(score, 'score');

% keyboard/gamepad
if taskList{'input'}{'usingKeyboard'}
    kb = taskList{'input'}{'keyboard'};
    topsDataLog.logDataInGroup(kb.allData, 'keyboard');
    kb.flushData;
elseif taskList{'input'}{'usingGamepad'}
    gp = taskList{'input'}{'gamepad'};
    topsDataLog.logDataInGroup(gp.allData, 'gamepad');
    gp.flushData;
end

% eyetracker
if taskList{'eye tracking'}{'on'}
    et = taskList{'input'}{'eye tracker'};
    topsDataLog.logDataInGroup(et.allData, 'eyeTrackerData');
    et.flushData;
end

DATA=topsDataLog.getSortedDataStruct
save([taskList{'control'}{'data file name'}, taskList{'control'}{'session time'}, '.mat'], 'DATA');

end

function checkForBadFixation(taskList)
if taskList{'eye tracking'}{'on'}
    et = taskList{'input'}{'eye tracker'};
    et.activateClassificationGroup = 'no fixation';
    queryAsOfTime(et);
end
end

function checkForGoodFixation(taskList)
if taskList{'eye tracking'}{'on'}
    et = taskList{'input'}{'eye tracker'};
    et.activeClassificationGroup = 'fixation';
    queryAsOfTime(et);
end
end