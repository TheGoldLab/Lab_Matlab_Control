function [taskTree, taskList]= configurePredInfTask

clear all
clear classes
% predictive inference task, written by MRN at UPENN, 2010
% this file contains script for initiating several versions of the
% predictive inference task.  The task can either be displayed numerically
% or spatially (along a line) with either high-contrast (colored) or
% isoluminant (gray) graphics.  Estimates can be made with a video gamepad
% or a keyboard.  Eyetracking is in development...

% Keep track of time using psychtoolbox, this affects timestamps in
% DATA-file
d=topsDataLog.theDataLog;
d.clockFunction = @GetSecs;


%% Organization:

% a list of things used to determine block to block changes
blockList = topsGroupedList;
blockList{'control'}{'hazard'} = [.1 .1];  % specify hazard rate for each block
blockList{'control'}{'std'} = [5 10];        % standard deviations for each block   
blockList{'order'}{'random'}= 0  ;             % 1 = randomize blocks, 0 = in order specified above 

% automatically make an array to keep track of order
if blockList{'order'}{'random'}
    blockList{'order'}{'progression'}=randperm(length(blockList{'control'}{'hazard'}));
else
    blockList{'order'}{'progression'}=1:length(blockList{'control'}{'hazard'});
end


%   the taskList is a container for prespecified variables and objects
%   partitioned into arbitrary groups
%   viewable with taskList.gui
taskList = topsGroupedList;
taskName = 'predInf';
RAND=clock;

%% Task Variables!
%   store some variables in the taskList container
%   used during configuration
%   used while task is running
%
%   Some task variables should be set by the experimenter, these variables
%   apear at the top of each section and include comments that (hopefully)
%   explain what they do.



% control variables 
taskList{'control'}{'remote'} = 1;              
taskList{'control'}{'fixed outcomes'} = 1;     % if fixed outcomes == 1, outcomes are drawn sequentially from fixed outcome array
taskList{'control'}{'fixed outcome array'} = [1 2 3 4 5 6 7 8 9];  % array of all outcomes, if they are prespecified
taskList{'control'}{'fixed outcome index'} = 1;                    % show outcomes from array starting at #
taskList{'control'}{'seed'} = RAND(6)*10e6;    % reset random seed (to clock RAND(6)*10e6 or to specified value)   
taskList{'control'}{'data file name'} = 'BLOCKTEST'; % name of data file and taskList to be saved 
taskList{'control'}{'limit alpha'} = 1;        % 1= subject is limited to 0 <= learning rate <= 1                 
taskList{'control'}{'move speed'} = 5;         % sets the increment of the "fast move" button on the gamepad 
taskList{'control'}{'max outcome'} = 300;      % sets the maximum outcome that can possibly be generated
taskList{'control'}{'trials per block'} = 3; % how many trials per block?
taskList{'control'}{'blocks per session'} = 2; % how many blocks per session?
taskList{'control'}{'max safe'} = 3;           % after a changepoint you are guarenteed "max safe" trials before another changepoint
taskList{'control'}{'coin toss'} = 0;         
rand('seed', taskList{'control'}{'seed'});     
randn('seed', taskList{'control'}{'seed'});
taskList{'control'}{'safe'} = taskList{'control'}{'max safe'}; 
taskList{'control'}{'mean'} = round(rand(1).*taskList{'control'}{'max outcome'}); 
taskList{'control'}{'outcome'} = nan;          
taskList{'control'}{'prediction'} = round(taskList{'control'}{'max outcome'}./2); 
taskList{'control'}{'std'} = nan;             
taskList{'control'}{'hazard'} = nan;         
taskList{'control'}{'good trial'} = 0;         
taskList{'control'}{'trials complete'} = 0;    
taskList{'control'}{'trials with same mean'} = 0;  
taskList{'control'}{'block list'} = blockList;        
taskList{'control'}{'block'} = 0;                  
taskList{'control'}{'task name'} = taskName;   
taskList{'control'}{'last delta'} = nan;            
taskList{'control'}{'last prediction'} = nan;  
taskList{'control'}{'last outcome'} = nan;
taskList{'control'}{'session time'} = [num2str(RAND(1)) num2str(RAND(2)) num2str(RAND(3)) num2str(RAND(4)) num2str(RAND(5))];
taskList{'control'}{'alpha reset control'} =0;



% instruction variables
taskList{'instructions'}{'instructions'} = 0 ;        % show instructions before starting task?
taskList{'instructions'}{'seconds per slide'} = [7 15 15 15 7];  % number of seconds to show each slide... can take array of length = instruction slides
taskList{'instructions'}{'instructions file name base'} = 'Titan_Attacks';
taskList{'instructions'}{'instruction slides'} = 5;
taskList{'instructions'}{'instruction file type'} = 'tiff';


% feedback variables
taskList{'feedback'}{'feedback on'} =1;                     %Turns on feedback at the end of each block
taskList{'feedback'}{'performance payout'} = 1;             % turns on performance based payment feedback
taskList{'feedback'}{'feedback text color'} =[250 90 30];   %sets color of feedback text 
taskList{'feedback'}{'text size'}=30;
taskList{'feedback'}{'total error'}= 0;                 
taskList{'feedback'}{'total amnesic error'}= 0;        
taskList{'feedback'}{'total omnicient error'}= 0;       
taskList{'feedback'}{'omni mean'} = 150;
taskList{'feedback'}{'prev mean'} = 150;                

% screen
taskList{'screen'}{'full screen'} = 1;                  % if 1 sets window to full screen... fix graphics screen scale accordingly!!!

% eye tracking
taskList{'eye tracking'}{'on'} = 0;
taskList{'eye tracking'}{'eye tracker class'}= 'dotsQueryableEyeASL';
taskList{'eye tracking'}{'input window'} = [-13.49 10.95 13.49.*2 -10.95.*2]*100;     % in x1, y1, h, w
taskList{'eye tracking'}{'xy window'} =  [-12 -10 24 20];                           % in x1, y1, h, w
taskList{'eye tracking'}{'frame rate'} = 120;
taskList{'eye tracking'}{'fixation window'} = [-4.5 -4.5 9 9];                           % in x1, y1, x2, y2

% isoluminant graphics 
taskList{'graphics'}{'isoluminance'} = 1;               % turns on isoluminant (checkered) background
taskList{'graphics'}{'luminance difference'} = 32;     % difference between dark and light background pixels
taskList{'graphics'}{'background checker size'} = 2;    % size of checkers (in pixels)
taskList{'graphics'}{'fixation pixels'} = 1;            % size of fixation point 
% ad hoc solution for now, until we gamma correct...
taskList{'graphics'}{'dark'} = [0 0 0];
taskList{'graphics'}{'light'} = [40 40 40]       %  repmat(taskList{'graphics'}{'luminance difference'}, 1, 3);
taskList{'graphics'}{'gray'} = [28 28 28]        %[1 1 1].*floor(taskList{'graphics'}{'luminance difference'}./2);

% taskList{'graphics'}{'dark'} = [0 0 0];
% taskList{'graphics'}{'light'} = [32 32 32]       %  repmat(taskList{'graphics'}{'luminance difference'}, 1, 3);
% taskList{'graphics'}{'gray'} = [21 21 21]        %[1 1 1].*floor(taskList{'graphics'}{'luminance difference'}./2);



% text graphics
taskList{'graphics'}{'text on'} = 1;                    % do you want to show numbers?
taskList{'graphics'}{'font size'} = 68;                 % how big?
taskList{'graphics'}{'outcome text Y'} = 1.5;             % Y-axis value for center of outcome number
taskList{'graphics'}{'prediction text Y'} = -1.5;         % Y-axis value for center of prediction number
taskList{'graphics'}{'disappear'} = 1;                   % 1 = subjects only see outcome for 2 seconds.

% line graphics
taskList{'graphics'}{'lines on'} = 0;                   % do you want to show a spatial (line) representation?
taskList{'graphics'}{'screen scale'} = 30;              % scales width of total spatial representation
taskList{'graphics'}{'line width'} = 5;                 % width of prediction and outcome lines
taskList{'graphics'}{'error line width'} = 10;          % width of error line
taskList{'graphics'}{'prediction color'} = [ 0 220 50];  % color of outcome line (& number if its on)
taskList{'graphics'}{'outcome color'} = [220 50 0];      % color of prediction line (& number if its on)
taskList{'graphics'}{'line length'} = 1;                % length of prediction and outcome lines
taskList{'graphics'}{'outcome Y'} = 3;                  % y pos of bottom of outcome line
taskList{'graphics'}{'prediction Y'} = -4;              % y pos of bottom of prediction line
taskList{'graphics'}{'error Y'} = 0;                    % y pos of reference line
taskList{'graphics'}{'boundary line 1 Y'} = [2];        % y pos of reference line
taskList{'graphics'}{'boundary line 2 Y'} = [-2];       % y pos of reference line
taskList{'graphics'}{'prediction start X'} = 0;  

% timing variables
taskList{'timing'}{'trial timeout'} = 6000;   % how many seconds of inactivity before there is a trial error  
taskList{'timing'}{'intertrial'} = 0;       % delay between trials, in seconds  
taskList{'timing'}{'fine adjust delay'} = .1; % delay after each press of the "slow update" gamepad buttons

% sounds
taskList{'sounds'}{'switch sounds'}=0;
if taskList{'sounds'}{'switch sounds'}
taskList{'sounds'}{'sound switch prob'}=.1;
taskList{'sounds'}{'sound switch maxSafe'}=3;
taskList{'sounds'}{'sound switch safe'}=3;
loadSounds;
taskList{'sounds'}{'sound list'} = soundList;
taskList{'sounds'}{'number sounds'} = length(taskList{'sounds'}{'sound list'});
taskList{'sounds'}{'current sound index'} = 1;
end


if taskList{'graphics'}{'isoluminance'}       
taskList{'timing'}{'fixation duration'} = 2;  %  number of seconds you want to collect pupil data on each trial (if you are collecting it) 
else
taskList{'timing'}{'fixation duration'} = 0;  
end

    
%% Graphics:
% This section creates some graphics objects
%  based on the constants from above
%   and stores them in the taskList container

if taskList{'screen'}{'full screen'} 
    s = dotsTheScreen.theObject;
    s.displayRect = [];
end

dm = dotsTheDrawablesManager.theObject;

dm.waitFevalable={@WaitSecs, .0001};
if taskList{'control'}{'remote'}
    dm.reset('serverMode', false, 'clientMode', true);
else
    dm.reset('serverMode', false, 'clientMode', false);
end
dm.waitFevalable={@WaitSecs, .0001};


% a fixation point
fp = dm.newObject('dotsDrawableTargets'); % rAdd but, only for dm (definined above)
fp.color = taskList{'graphics'}{'gray'};
fp.dotSize = taskList{'graphics'}{'fixation pixels'};
taskList{'graphics'}{'fixation point'} = fp;

% prediction line
prediction = dm.newObject('dotsDrawableLines');
prediction.color = taskList{'graphics'}{'prediction color'};
prediction.x =  [taskList{'graphics'}{'prediction start X'}  taskList{'graphics'}{'prediction start X'} ];
prediction.y =  [taskList{'graphics'}{'prediction Y'}+taskList{'graphics'}{'line length'}...
    taskList{'graphics'}{'prediction Y'}];
prediction.width =  taskList{'graphics'}{'line width'};
prediction.isVisible = taskList{'graphics'}{'lines on'};
taskList{'graphics'}{'prediction line'}=prediction;

% outcome line
outcome = dm.newObject('dotsDrawableLines');
outcome.color = taskList{'graphics'}{'outcome color'};
outcome.x =  [-10e20 -10e20]; % initial position= off screen
outcome.y =  [taskList{'graphics'}{'outcome Y'}+taskList{'graphics'}{'line length'}...
    taskList{'graphics'}{'outcome Y'}];
outcome.isVisible = taskList{'graphics'}{'lines on'};
outcome.width =  taskList{'graphics'}{'line width'};
taskList{'graphics'}{'outcome line'}=outcome;

% error line
errorL = dm.newObject('dotsDrawableLines');
errorL.color = taskList{'graphics'}{'gray'};
errorL.x =  [-20 -20]; % initial position= off screen
errorL.y =  [taskList{'graphics'}{'error Y'} taskList{'graphics'}{'error Y'}];
errorL.isVisible = taskList{'graphics'}{'lines on'};
errorL.width =  taskList{'graphics'}{'error line width'};
taskList{'graphics'}{'error line'}=errorL;

% boundary line 1
boundL1 = dm.newObject('dotsDrawableLines');
boundL1.color = taskList{'graphics'}{'gray'};
boundL1.x =  [-.5*taskList{'graphics'}{'screen scale'} .5*taskList{'graphics'}{'screen scale'}];
boundL1.y =  [taskList{'graphics'}{'boundary line 1 Y'} taskList{'graphics'}{'boundary line 1 Y'}];
boundL1.isVisible = taskList{'graphics'}{'lines on'};
boundL1.width = 1;
taskList{'graphics'}{'boundary line 1'}=boundL1;

% boundary line 2
boundL2= dm.newObject('dotsDrawableLines');
boundL2.color = taskList{'graphics'}{'gray'};
boundL2.x =  [-.5*taskList{'graphics'}{'screen scale'} .5*taskList{'graphics'}{'screen scale'}];
boundL2.isVisible = taskList{'graphics'}{'lines on'};
boundL2.y=[taskList{'graphics'}{'boundary line 2 Y'} taskList{'graphics'}{'boundary line 2 Y'}];
boundL2.width = 1;
taskList{'graphics'}{'boundary line 2'}=boundL2;


% outcome text, if its turned on

outcomeText = dm.newObject('dotsDrawableText');
if taskList{'graphics'}{'lines on'} ==1
    outcomeText.color = taskList{'graphics'}{'outcome color'};
else
    outcomeText.color = taskList{'graphics'}{'gray'};
end
outcomeText.x = 0;
outcomeText.y =  taskList{'graphics'}{'outcome text Y'};
outcomeText.string = 'Where will the next missile land?';
outcomeText.isVisible = taskList{'graphics'}{'text on'};
outcomeText.backgroundColor = [0 0 0 0];
taskList{'graphics'}{'outcome text'}=outcomeText;

% prediction text
predictionText = dm.newObject('dotsDrawableText');
if taskList{'graphics'}{'lines on'} ==1
    predictionText.color = taskList{'graphics'}{'prediction color'};
else
    predictionText.color = taskList{'graphics'}{'gray'};
end
predictionText.x = taskList{'graphics'}{'prediction start X'};
predictionText.y =  taskList{'graphics'}{'prediction text Y'};
predictionText.isVisible = taskList{'graphics'}{'text on'};
predictionText.backgroundColor = [0 0 0 0];
predictionText.string = sprintf('%d', round(taskList{'control'}{'max outcome'})./2);
taskList{'graphics'}{'prediction text'}=predictionText;


% Instruction image
s = dotsTheScreen.theObject;
instruct= dm.newObject('dotsDrawableImage');
instruct.fileType=taskList{'instructions'}{'instruction file type'};
taskList{'graphics'}{'instructions image'}=instruct;

% Feedback text
if taskList{'feedback'}{'feedback on'}
    feedBackText = dm.newObject('dotsDrawableText');
    feedBackText.color = taskList{'feedback'}{'feedback text color'} ;
    feedBackText.x = 0;
    feedBackText.y = 0;
    feedBackText.backgroundColor = [0 0 0 0];
    taskList{'graphics'}{'feedback text'}=feedBackText;
    
    if taskList{'feedback'}{'performance payout'}
        payoutText = dm.newObject('dotsDrawableText');
        payoutText.color = taskList{'feedback'}{'feedback text color'} ;
        payoutText.x = 0;
        payoutText.y = -2;
        payoutText.string = '';
        payoutText.backgroundColor = [0 0 0 0];
        taskList{'graphics'}{'payout text'}=payoutText;
    end
end

%% this needs to change!!!!
% GOOD = Wait until you get an open window... open drawables window... open a window then close
% it... then get windowRect for that pix box... that should tell you the
% numbher of pixels on the remote computer screen.
% an isoluminant background, if its turned on


if taskList{'graphics'}{'isoluminance'}

%     openScreenWindow(dm)
%     pixBox=dm.theScreen.windowRect
   
    tx = dm.newObject('dotsDrawableTextures');
    tx.textureMakerFevalable = {'textureMakerCheckers', ...
        taskList{'graphics'}{'background checker size'}, ...
        taskList{'graphics'}{'background checker size'}, [], [], ...
        taskList{'graphics'}{'dark'},...
        taskList{'graphics'}{'light'}};
    taskList{'graphics'}{'background texture'}=tx;    
    
    %if we're doing the fixation version, load some sounds to play
    
    pm = dotsThePlayablesManager.theObject;
    fs = pm.newObject('dotsPlayableFile');
    fs.fileName = 'Pause.wav';
    fs.intensity=1.5;
    fe = pm.newObject('dotsPlayableFile');
    fe.intensity=1;
    fe.fileName = 'Coin.wav';
    fb = pm.newObject('dotsPlayableFile');
    fb.intensity=1;
    fb.fileName = 'Pipe_Warp.wav';
    taskList{'sounds'}{'fixation start'}= fs;
    taskList{'sounds'}{'fixation end'}= fe;
    taskList{'sounds'}{'fixation break'}= fb;       
    
    % in case of a remote machine, let it sync up
    %pm.finishAllTransactions;
end

% set text font size
dm.setScreenTextSetting('TextSize', taskList{'graphics'}{'font size'});

% add drawable task objects to one graphics group:
dm.addObjectToGroup(fp, taskName, 7);
dm.addObjectToGroup(outcome, taskName, 6);
dm.addObjectToGroup(prediction, taskName, 5);
dm.addObjectToGroup(predictionText, taskName, 4);
dm.addObjectToGroup(outcomeText, taskName, 3);
dm.addObjectToGroup(errorL, taskName, 2);
if taskList{'graphics'}{'isoluminance'}
    dm.addObjectToGroup(tx, taskName, 1);
end
dm.addObjectToGroup(boundL1, taskName, 8);
dm.addObjectToGroup(boundL2, taskName, 9);
dm.activateGroup(taskName);

% add feedback graphics to a different group:
if taskList{'feedback'}{'feedback on'}
    dm.addObjectToGroup(feedBackText, 'feedback', 2);
    if taskList{'feedback'}{'performance payout'}
        dm.addObjectToGroup(payoutText, 'feedback', 3);
    end
    
%     if taskList{'graphics'}{'isoluminance'}
%         dm.addObjectToGroup(tx, 'feedback', 1);
%     end
end

% add instructions graphics to a different group:
dm.addObjectToGroup(instruct, 'instructions', 1);





%% Input:
%   create an input object, a gamepad
%   configure it to classify inputs as needed for this task
%   store it in the taskList container
qm = dotsTheQueryablesManager.theObject;
gp = qm.newObject('dotsQueryableHIDGamepad');
taskList{'input'}{'gamepad'} = gp;

if gp.isAvailable
    % identify axes movement phenomenons
    % and button press phenomenons
    %   see gp.phenomenons.gui
    left = gp.phenomenons{'axes'}{'min_X'};
    right = gp.phenomenons{'axes'}{'max_X'};
    anyAxis = gp.phenomenons{'axes'}{'any_axis'};
    
    pressed  = gp.phenomenons{'pressed'}{'pressed_button_1'};
    leftFine = gp.phenomenons{'pressed'}{'pressed_button_5'};
    rightFine= gp.phenomenons{'pressed'}{'pressed_button_6'};
    viewInstruct  = gp.phenomenons{'pressed'}{'pressed_button_3'};
    
    
    input=gp; % set input to gamepad

else
    % fallback on the keyboard
    % see mexHIDUsage.gui for string -> key code
    kb = qm.newObject('dotsQueryableHIDKeyboard');
    kb.keysOfInterest = {'KeyboardF', 'KeyboardJ', 'KeyboardG', ...
        'KeyboardH', 'KeyboardSpacebar', 'KeyboardI'};
    kb.initialize;

    % identify key press phenomenons
    %   see kb.phenomenons.gui
    left = kb.phenomenons{'pressed'}{'pressed_KeyboardF'};
    right = kb.phenomenons{'pressed'}{'pressed_KeyboardJ'};
    leftFine= kb.phenomenons{'pressed'}{'pressed_KeyboardG'};
    rightFine= kb.phenomenons{'pressed'}{'pressed_KeyboardH'};
    pressed=kb.phenomenons{'pressed'}{'pressed_KeyboardSpacebar'};
    taskList{'input'}{'keyboard'} = kb;
    viewInstruct= kb.phenomenons{'pressed'}{'pressed_KeyboardI'};
      
    input=kb;  %else set input to keyboard
end

gp.unavailableOutput = 'no input device';
taskList{'input'}{'using this'} = input;

% classify phenomenons to produce arbitrary results
%   each result will match a state name, below
input.addClassificationInGroupWithRank(left, 'leftFast', taskName, 2);
input.addClassificationInGroupWithRank(right, 'rightFast', taskName, 3);
input.addClassificationInGroupWithRank(leftFine, 'leftward', taskName, 4);
input.addClassificationInGroupWithRank(rightFine, 'rightward', taskName, 5);

if taskList{'eye tracking'}{'on'}
    input.addClassificationInGroupWithRank(pressed, 'lookHere', taskName, 6);
else    
    input.addClassificationInGroupWithRank(pressed, 'outcome', taskName, 6);
end

input.addClassificationInGroupWithRank(viewInstruct, 'viewInstruct', taskName, 7);
input.activeClassificationGroup = taskName;
    

if taskList{'eye tracking'}{'on'}
% make eye tracker object
et = qm.newObject('dotsQueryableEyeASL');
et.inputRect = taskList{'eye tracking'}{'input window'};       % set window of possible inputs
et.xyRect = taskList{'eye tracking'}{'xy window'};             % and a window you want those inputs mapped onto
et.sampleFrequency = taskList{'eye tracking'}{'frame rate'};   % set the framerate of the camera
et.initialize;
if ~(et.openEyeTracker)
   problem= 'eye tracker is unavailable'
end

temp = et.getPhenomenonTemplate;
inBox = dotsPhenomenon.rectangle(temp, 'xPos', 'yPos', taskList{'eye tracking'}{'fixation window'}, 'in'); % looking at numbers
outBox = dotsPhenomenon.rectangle(temp, 'xPos', 'yPos', taskList{'eye tracking'}{'fixation window'}, 'out');% looking away

et.addClassificationInGroupWithRank(inBox, 'outcome', 'innie', 1);
et.addClassificationInGroupWithRank(outBox, 'badFix', 'outie', 1)

taskList{'input'}{'eye tracker'}=et;
end


%% Control:
% create three types of control objects:
%       - topsBlockTree organizes flow outside of trials
%       - topsStatelist organizes flow within trials
%       - topsFunctionLoop organizes moment-to-moment, concurrent behaviors
%       within trials
%   connect these to each other
%   store them in the taskList container

% the trunk of the tree, branches are added below
taskTree = topsTreeNode;
taskTree.name = taskName;
taskTree.iterations = taskList{'control'}{'blocks per session'};
taskTree.startFevalable = {@openScreenWindow, dm};
taskTree.finishFevalable = {@closeScreenWindow, dm};
taskList{'control'}{'task tree'} = taskTree;



% a batch of function calls that apply to all the trial types below
taskCalls = topsCallList;
taskCalls.alwaysRunning = true;
%taskCalls.addCall({@finishAllTransactions, dm});
taskCalls.addCall({@readData, input});
taskCalls.addCall({@mayDrawNextFrame, dm});
taskList{'control'}{'task calls'} = taskCalls;


% save the taskList loaded for a given session:
save([taskList{'control'}{'data file name'}, taskList{'control'}{'session time'},'taskList.mat'], 'taskList');


%% predictive inference task
predInfMachine = topsStateMachine;
predInf = 'predictive inference';
predInfMachine.name = predInf;

trialTime = taskList{'timing'}{'trial timeout'};
pred      = taskList{'graphics'}{'prediction line'};
out       = taskList{'graphics'}{'outcome line'};
predT     = taskList{'graphics'}{'prediction text'};
outT      = taskList{'graphics'}{'outcome text'};
fixDur    = taskList{'timing'}{'fixation duration'};

if taskList{'eye tracking'}{'on'}
    CQ = {@queryAsOfTime, et};
    taskCalls.addCall({@readData, et});
else
    CQ= {};   
end



if taskList{'graphics'}{'isoluminance'}
    %taskCalls.addCall({@readData, pm});
    IN = {@makeInnieActive, taskList} 
    SS = {@soundPlay, taskList, 'fixation start'};
    SE = {@soundPlay, taskList, 'fixation end'} ;
    SB = {@soundPlay, taskList, 'fixation break'};
    OU = {@makeOutieActive, taskList};
else
    IN = {}; 
    SS = {};
    SE = {};
    SB = {};
    OU = {};
end


VI = {@viewInstructions, taskList};
LP = {@leftPush, taskList};
RP = {@rightPush, taskList};
LF = {@leftFastPush, taskList};
RF = {@rightFastPush, taskList};
GO = {@genOutcome, taskList};
SO = {@showOutcome, taskList};
SP = {@showPrediction, taskList};
SD = {@storeData, taskList};
IT = {@incTrial, taskList};
BT = {@badTrial, taskList};
QG = {@queryAsOfTime, input};  

predInfStates = { ...
    'name',     'entry',    'timeout',	'input',    'exit',     'next'; ...    
    'predict',    SP,       trialTime,  QG,         {},         'outcome';...
    'leftward',   LP,       0,          {},         {},         'predict';...
    'rightward',  RP,       0,          {},         {},         'predict';...      
    'leftFast',   LF,       0,          {},         {},         'predict';...
    'rightFast',  RF,       0,          {},         {},         'predict';...
    'payAttent',  SB,       0,          {},         {},         'lookHere';...
    'lookHere',   IN,       fixDur.*3,  CQ,         {},         'payAttent';...    
    'outcome',    GO,       0,          {},         SO,         'fixation';...
    'fixation',   OU,       fixDur,     CQ,         {},         'goodFix';...
    'goodFix',    IT,       0,          {},         {},         'storeData';...
    'badFix',     BT,       fixDur,     {},         {},         'storeData';...
    'viewInstruct',VI,      0,          {},         {},         'predict';...
    'no gamepad', {},       0,          {},         {@hide,fp}, 'outcome';...
    'storeData',  SD,       0,          {},         {},         'endTrial';...
    'endTrial',   {},       0,          {},         SE,         '';...
    };

% printGo = @(states)disp(sprintf('%s -> %s', states(1).name, states(2).name));
% predInfMachine.transitionFevalable = {printGo};

predInfMachine.addMultipleStates(predInfStates);
taskList{'control'}{'predictive inference machine'} = predInfMachine;

%% add the sergeant to interleave taskCalls and statelist



predInfSergeant = topsConcurrentComposite;
predInfSergeant.name = predInf;
predInfSergeant.addChild(taskCalls);
predInfSergeant.addChild(predInfMachine);
predInfSergeant.startFevalable = {@runTrial, taskList, predInfMachine};

% add a group to the loop object
% taskLoop.addFunctionToGroupWithRank({@step, predInfMachine}, predInf, 5);
% taskLoop.mergeGroupsIntoGroup({taskName, predInf}, predInf);

% add a branch to the tree trunk
predInfTree = topsTreeNode;
predInfTree.name = predInf;
predInfTree.startFevalable = {@resetTaskList, taskList};
predInfTree.iterations = taskList{'control'}{'trials per block'};
predInfTree.finishFevalable = {@feedback, taskList};
taskTree.addChild(predInfTree);
predInfTree.addChild(predInfSergeant);


%% Custom Behaviors:
% define behaviors that are unique to this task
%   the control objects above use these
%   the smaller and fewer of these, the better

function runTrial(taskList, stateMachine)
% how much of this could move into the statelist?
% clear out the game pad
gp = taskList{'input'}{'gamepad'};
if taskList{'control'}{'safe'} > 0
    taskList{'control'}{'safe'}=taskList{'control'}{'safe'}-1;
    taskList{'control'}{'coin toss'}=0;
else
    taskList{'control'}{'coin toss'} = rand(1)< taskList{'control'}{'hazard'};
    if taskList{'control'}{'coin toss'}
        taskList{'control'}{'mean'} = rand(1).*taskList{'control'}{'max outcome'};
        taskList{'control'}{'safe'} = taskList{'control'}{'max safe'};
    end
end

% choose outcome
    % either grab it from a prespecified array, or generate it on the fly.
if taskList{'control'}{'fixed outcomes'}
    array = taskList{'control'}{'fixed outcome array'};
    taskList{'control'}{'outcome'} = array(taskList{'control'}{'fixed outcome index'});
    taskList{'control'}{'fixed outcome index'}=taskList{'control'}{'fixed outcome index'}+1;
else    
    goodOut=0;
    while ~goodOut
        taskList{'control'}{'outcome'} = round(normrnd(taskList{'control'}{'mean'},...
            taskList{'control'}{'std'}));
        goodOut= taskList{'control'}{'outcome'} >= 0 & taskList{'control'}{'outcome'} <= taskList{'control'}{'max outcome'};
    end
end


if taskList{'sounds'}{'switch sounds'}    
    if taskList{'sounds'}{'sound switch safe'} > 0
        taskList{'sounds'}{'sound switch safe'} =taskList{'sounds'}{'sound switch safe'} -1;
        soundCha=0;
    else
        soundCha = rand(1)< taskList{'sounds'}{'sound switch prob'};
        if soundCha
            oldSound= taskList{'sounds'}{'current sound index'};
            vals=randperm(taskList{'sounds'}{'number sounds'});
            if vals(1)~=oldSound
            taskList{'sounds'}{'current sound index'}=vals(1);
            else
            taskList{'sounds'}{'current sound index'}=vals(2);    
            end
            soundList= taskList{'sounds'}{'sound list'};
            fs=taskList{'sounds'}{'fixation start'};
            fs.fileName=soundList{vals(1)};
            fs.intensity=4;    
            taskList{'sounds'}{'sound switch safe'}=taskList{'sounds'}{'sound switch maxSafe'};
        end
    end
end

 
    
% tell the loop to run until this state machine is done
trialTime = taskList{'timing'}{'trial timeout'};
WaitSecs(taskList{'timing'}{'intertrial'});

function leftPush(taskList)
if taskList{'control'}{'limit alpha'}
    minMark=min([taskList{'control'}{'last prediction'} taskList{'control'}{'last outcome'}]);
    if ~isfinite(minMark);
        minMark=0;
    end
    taskList{'control'}{'prediction'}=max([taskList{'control'}{'prediction'}-1, minMark]);
else
    taskList{'control'}{'prediction'}=taskList{'control'}{'prediction'}-1;
end
predText=taskList{'graphics'}{'prediction text'};
predText.string = sprintf('%d', taskList{'control'}{'prediction'});
aa=taskList{'graphics'}{'prediction line'};
pos = feval(@positionFromValue, taskList{'control'}{'prediction'}, taskList);
aa.x=[pos pos];
WaitSecs(taskList{'timing'}{'fine adjust delay'});

function leftFastPush(taskList)
if taskList{'control'}{'limit alpha'}
    minMark=min([taskList{'control'}{'last prediction'} taskList{'control'}{'last outcome'}]);
    if ~isfinite(minMark);
        minMark=0;
    end
    taskList{'control'}{'prediction'}=max([round(taskList{'control'}{'prediction'}-...
        taskList{'control'}{'move speed'}), minMark]);
else
   taskList{'control'}{'prediction'} = round(taskList{'control'}{'prediction'}-taskList{'control'}{'move speed'});
end
predText=taskList{'graphics'}{'prediction text'};
predText.string = sprintf('%d', taskList{'control'}{'prediction'});
aa=taskList{'graphics'}{'prediction line'};
pos = feval(@positionFromValue, taskList{'control'}{'prediction'}, taskList);
aa.x=[pos pos];

function rightPush(taskList)
if taskList{'control'}{'limit alpha'}
    maxMark = max([taskList{'control'}{'last prediction'} taskList{'control'}{'last outcome'}]);
    if ~isfinite(maxMark)
        maxMark=taskList{'control'}{'max outcome'};
    end
    taskList{'control'}{'prediction'} = min([taskList{'control'}{'prediction'}+1, maxMark]);    
else    
    taskList{'control'}{'prediction'} = taskList{'control'}{'prediction'}+1;
end
predText=taskList{'graphics'}{'prediction text'}; 
predText.string = sprintf('%d', taskList{'control'}{'prediction'});
aa=taskList{'graphics'}{'prediction line'};
pos = feval(@positionFromValue, taskList{'control'}{'prediction'}, taskList);
aa.x=[pos pos];
WaitSecs(taskList{'timing'}{'fine adjust delay'});

function rightFastPush(taskList)
if taskList{'control'}{'limit alpha'}
    maxMark = max([taskList{'control'}{'last prediction'} taskList{'control'}{'last outcome'}]);
    if ~isfinite(maxMark)
        maxMark=taskList{'control'}{'max outcome'};
    end
    taskList{'control'}{'prediction'} = min([taskList{'control'}{'prediction'}+...
    taskList{'control'}{'move speed'}, maxMark]);   
else    
    taskList{'control'}{'prediction'} = taskList{'control'}{'prediction'}+taskList{'control'}{'move speed'};
end
predText=taskList{'graphics'}{'prediction text'}; 
predText.string = sprintf('%d', taskList{'control'}{'prediction'});
aa=taskList{'graphics'}{'prediction line'};
pos = feval(@positionFromValue, taskList{'control'}{'prediction'}, taskList);
aa.x=[pos pos];

function genOutcome(taskList)
hide(taskList{'graphics'}{'outcome line'});
dm = dotsTheDrawablesManager.theObject;
dm.mayDrawNextFrame;
tc=topsConcurrent;
tc.runBriefly;

%dm.receiveTransactions;
WaitSecs(.2);
pos=feval(@positionFromValue, taskList{'control'}{'outcome'}, taskList);
bb=taskList{'graphics'}{'outcome line'};
bb.x=[pos pos];
outText=taskList{'graphics'}{'outcome text'};
outText.string=sprintf('%d', taskList{'control'}{'outcome'});
EL=taskList{'graphics'}{'error line'};
OL=taskList{'graphics'}{'prediction line'};
EL.x=[bb.x(1) OL.x(1)];
if taskList{'graphics'}{'lines on'}
show(taskList{'graphics'}{'outcome line'})
show(taskList{'graphics'}{'error line'})
end
if taskList{'graphics'}{'isoluminance'}
    feval(@soundPlay, taskList, 'fixation start');
end




function showOutcome(taskList)
if taskList{'graphics'}{'lines on'}
    show(taskList{'graphics'}{'outcome line'});
    show(taskList{'graphics'}{'error line'});
end
if taskList{'graphics'}{'text on'}
    show(taskList{'graphics'}{'outcome text'});
end
dm = dotsTheDrawablesManager.theObject;
dm.mayDrawNextFrame;
%dm.receiveTransactions;

function showPrediction(taskList)
dm = dotsTheDrawablesManager.theObject;
dm.mayDrawNextFrame;
%dm.receiveTransactions;
if taskList{'graphics'}{'lines on'}
    show(taskList{'graphics'}{'prediction line'});
end
if taskList{'graphics'}{'text on'}
     show(taskList{'graphics'}{'prediction text'});
end

function storeData(taskList)

% log useful taskList data
topsDataLog.logDataInGroup(taskList{'control'}{'prediction'}, 'prediction');
topsDataLog.logDataInGroup(taskList{'control'}{'outcome'}, 'outcome');
topsDataLog.logDataInGroup(taskList{'control'}{'safe'}, 'safe');
topsDataLog.logDataInGroup(taskList{'control'}{'mean'}, 'mean');
topsDataLog.logDataInGroup(taskList{'control'}{'trials complete'}, 'trials complete');
topsDataLog.logDataInGroup(taskList{'control'}{'std'}, 'std');
topsDataLog.logDataInGroup(taskList{'control'}{'hazard'}, 'hazard');
topsDataLog.logDataInGroup(taskList{'control'}{'good trial'}, 'good trial');
topsDataLog.logDataInGroup(taskList{'control'}{'coin toss'}, 'new mean');


if taskList{'sounds'}{'switch sounds'}
fs=taskList{'sounds'}{'fixation start'}
topsDataLog.logDataInGroup(taskList{'sounds'}{'current sound index'}, 'sound index');
topsDataLog.logDataInGroup(fs.fileName, 'fixation sound file');
end



% log gamepad data
gp=taskList{'input'}{'gamepad'};
topsDataLog.logDataInGroup(gp.allData, 'gamepadData');
gp.flushData;

if taskList{'eye tracking'}{'on'}
et=taskList{'input'}{'eye tracker'};
topsDataLog.logDataInGroup(et.allData, 'eyeTrackerData');
et.flushData;
end


% compute data to be stored (from the taskList)
Update = taskList{'control'}{'prediction'}-taskList{'control'}{'last prediction'};
Delta  = taskList{'control'}{'outcome'}-taskList{'control'}{'prediction'};
Alpha  = Update/taskList{'control'}{'last delta'};
if taskList{'control'}{'coin toss'}==1 | taskList{'control'}{'trials complete'}==1
    taskList{'control'}{'trials with same mean'} = 1;
else
    taskList{'control'}{'trials with same mean'} = taskList{'control'}{'trials with same mean'}+1;
end

% compute feedback data

if ~isfinite(taskList{'control'}{'last outcome'})
    taskList{'feedback'}{'prev mean'}=.5*taskList{'control'}{'max outcome'};
    taskList{'control'}{'last outcome'}=.5*taskList{'control'}{'max outcome'};
    taskList{'feedback'}{'omni mean'} =.5*taskList{'control'}{'max outcome'};
end
    
taskList{'feedback'}{'total error'}=taskList{'feedback'}{'total error'}+abs(Delta);
omniDelta=taskList{'control'}{'outcome'}-taskList{'feedback'}{'omni mean'};
taskList{'feedback'}{'omni mean'}= taskList{'feedback'}{'omni mean'} + omniDelta.*(1/taskList{'control'}{'trials with same mean'});


taskList{'feedback'}{'total omnicient error'}= taskList{'feedback'}{'total omnicient error'}+abs(omniDelta);
amneDelta=taskList{'control'}{'outcome'}-taskList{'control'}{'last outcome'};
taskList{'feedback'}{'total amnesic error'}= taskList{'feedback'}{'total amnesic error'}+abs(amneDelta);

% log computed data
topsDataLog.logDataInGroup(Update, 'update');
topsDataLog.logDataInGroup(Delta, 'prediction error');
topsDataLog.logDataInGroup(Alpha, 'learning rate');
topsDataLog.logDataInGroup(taskList{'control'}{'trials with same mean'}, 'trial within mean');    

% reset value of most recent prediction in taskList
taskList{'control'}{'last prediction'} = taskList{'control'}{'prediction'};
taskList{'control'}{'last outcome'} = taskList{'control'}{'outcome'};
taskList{'feedback'}{'prev mean'}=taskList{'control'}{'mean'};
taskList{'control'}{'last delta'}=Delta;


%% THIS IS UNTESTED... BUT IT SHOULD LOOK SOMETHING LIKE THIS!
if taskList{'control'}{'alpha reset control'}
    dm=dotsTheDrawablesManager.theObject;
    WaitSecs(.2)
    half=floor((taskList{'control'}{'prediction'}+...
        taskList{'control'}{'outcome'})./2)
    taskList{'control'}{'prediction'}=half;
    pos=feval(@positionFromValue, half, taskList);
    pp=taskList{'graphics'}{'prediction line'};
    pp.x=[pos pos];
    predText=taskList{'graphics'}{'prediction text'};
    predText.string=num2str(half);
    dm.mayDrawNextFrame;
    %dm.receiveTransactions;
end




% moved data saving to happen during block feeback.
% % save data file
% DATA=topsDataLog.getSortedDataStruct;
% save([taskList{'control'}{'data file name'}, taskList{'control'}{'session time'}, '.mat'], 'DATA');

function incTrial(taskList)
taskList{'control'}{'good trial'}=1;
taskList{'control'}{'trials complete'}=taskList{'control'}{'trials complete'}+1;
                
function badTrial(taskList)
taskList{'control'}{'goodTrial'}=0;
feval(@soundPlay, taskList, 'fixation break')           

function pos=positionFromValue(value, taskList)
pos = value/taskList{'control'}{'max outcome'}.*taskList{'graphics'}{'screen scale'}...
    - .5*taskList{'graphics'}{'screen scale'}; 

function resetTaskList(taskList)
% ask the block tree what block this is
taskTree = taskList{'control'}{'task tree'};
taskList{'control'}{'block'} = taskTree.iterationCount;
% show instructions if its the first block
if taskList{'control'}{'block'}==1
    feval(@viewInstructions, taskList);
end

taskList{'control'}{'mean'} = round(rand(1).*taskList{'control'}{'max outcome'});
taskList{'control'}{'last prediction'} = nan;
taskList{'control'}{'last outcome'} = nan;
taskList{'control'}{'trials with same mean'} = 0;
taskList{'control'}{'trials complete'} = 0;
outcome = taskList{'graphics'}{'outcome line'};
outcome.x =  [-10e20 -10e20];
outcomeText=taskList{'graphics'}{'outcome text'};
outcomeText.string = 'Where will the next missile land?';
blockList=taskList{'control'}{'block list'};
blcOrder=blockList{'order'}{'progression'};
newBlock=blcOrder(taskList{'control'}{'block'});
stdVals=blockList{'control'}{'std'};
hazVals=blockList{'control'}{'hazard'};
taskList{'control'}{'std'} = stdVals(newBlock);
taskList{'control'}{'hazard'} = hazVals(newBlock);
hide(taskList{'graphics'}{'error line'});
WaitSecs(.5);

function feedback(taskList)

% save data file
DATA=topsDataLog.getSortedDataStruct;
save([taskList{'control'}{'data file name'}, taskList{'control'}{'session time'}, '.mat'], 'DATA');


avErr= taskList{'feedback'}{'total error'}/ (taskList{'control'}{'trials complete'}*taskList{'control'}{'block'});

if taskList{'feedback'}{'performance payout'}
    
avOmnErr=taskList{'feedback'}{'total omnicient error'}/ (taskList{'control'}{'trials complete'}*taskList{'control'}{'block'});
avAmnErr=taskList{'feedback'}{'total amnesic error'}/ (taskList{'control'}{'trials complete'}*taskList{'control'}{'block'});

gold=avOmnErr.*(2/3)+avAmnErr./3;
silver=avOmnErr./3+avAmnErr.*2./3;
bronze=avAmnErr;

payoutText = taskList{'graphics'}{'payout text'};
payoutText.string = sprintf('gold ($15) < %.1f, silver ($12) < %.1f, bronze ($10) < %.1f', gold, silver, bronze);
disp(payoutText.string);

topsDataLog.logDataInGroup(payoutText.string, 'payout scale');


end

feedBackText        = taskList{'graphics'}{'feedback text'};
feedBackText.string = sprintf('your avg error was %.1f !', avErr);
disp(feedBackText.string);
dm = dotsTheDrawablesManager.theObject;

dm.setScreenTextSetting('TextSize', taskList{'feedback'}{'text size'});
%dm.finishAllTransactions;
dm.activateGroup('feedback');
dm.mayDrawNextFrame;


%dm.receiveTransactions;
topsDataLog.logDataInGroup(feedBackText.string, 'subject performance');


if taskList{'feedback'}{'performance payout'}
    WaitSecs(10);
else
    WaitSecs(4);
end

dm.closeScreenWindow;
dm.activateGroup('predInf');
dm.openScreenWindow;
dm.setScreenTextSetting('TextSize', taskList{'graphics'}{'font size'});










function viewInstructions(taskList)
if taskList{'instructions'}{'instructions'}==1
    instruct=taskList{'graphics'}{'instructions image'};
    dm = dotsTheDrawablesManager.theObject;
    dm.activateGroup('instructions');
    i=1;
    show(taskList{'graphics'}{'instructions image'})
    while i <= taskList{'instructions'}{'instruction slides'}
        instruct.fileName=   [taskList{'instructions'}{'instructions file name base'} num2str(i)...
            '.' taskList{'instructions'}{'instruction file type'}];
        dm.mayDrawNextFrame;
        %dm.receiveTransactions;
        
        
        if length(taskList{'instructions'}{'seconds per slide'}) == taskList{'instructions'}{'instruction slides'}
            slideTimes=taskList{'instructions'}{'seconds per slide'};
            WaitSecs(slideTimes(i));
        else
            WaitSecs(taskList{'instructions'}{'seconds per slide'});
        end
        
        
        i = i+1;
    end
    hide(taskList{'graphics'}{'instructions image'})
    dm.mayDrawNextFrame;
    %dm.receiveTransactions;
    dm.activateGroup('predInf');
end

function makeInnieActive(taskList)
        et=taskList{'input'}{'eye tracker'};
        et.activeClassificationGroup = 'innie';       
              
function makeOutieActive(taskList)
        if taskList{'eye tracking'}{'on'}
        et=taskList{'input'}{'eye tracker'};
        et.activeClassificationGroup = 'outie';           
        end      
        if taskList{'graphics'}{'disappear'}
        hide(taskList{'graphics'}{'prediction text'});
        dm = dotsTheDrawablesManager.theObject;
        dm.mayDrawNextFrame;
        %dm.receiveTransactions; 
        end
        
function soundPlay(taskList, soundName)
pm = dotsThePlayablesManager.theObject;
sound=taskList{'sounds'}{soundName};
sound.prepareToPlay;
pm.mayPlayPlayable(sound);
%pm.finishAllTransactions;

   fs=taskList{'sounds'}{'fixation start'};
   fs.intensity=1.5;   
    
if strmatch(soundName, 'fixation end')& taskList{'graphics'}{'disappear'}
    hide(taskList{'graphics'}{'outcome text'});
    dm = dotsTheDrawablesManager.theObject;
    dm.mayDrawNextFrame;
    
    %dm.receiveTransactions;
  
   
end

    
    
    
