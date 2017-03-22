function [tree, list] = configureODRtask(logic, isClient)
% for the within trial change-point task
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 1);

if nargin < 1 || isempty(logic)
    logic = ODRLogic();
end

if nargin < 2
    isClient = false;
end



%% Organization:
% Make a container for task data and objects, partitioned into groups.
list = topsGroupedList('ODR data');

%% Important Objects:
list{'object'}{'logic'} = logic;

statusData = logic.getDataArray();
list{'logic'}{'statusData'} = statusData;

list{'screen'}{'actual screen'}=sc;
%% Constants:
% Store some constants in the list container, for use during configuration
% and while task is running
list{'constants'}{'counter'} = 1;
list{'constants'}{'alternate'} = 0;
list{'constants'}{'duration'} = 0;

%TIMING ASPECTS
list{'timing'}{'feedback'} = 0.75;
list{'timing'}{'intertrial'} = 0;

list{'graphics'}{'isClient'} = isClient;
list{'graphics'}{'white'} = [1 1 1];
list{'graphics'}{'lightgray'} = [0.65 0.65 0.65];
list{'graphics'}{'lightblue'} = [0.55 0.55 0.80];
list{'graphics'}{'gray'} = [0.25 0.25 0.25];
list{'graphics'}{'red'} = [0.75 0.25 0.1];
list{'graphics'}{'yellow'} = [0.75 0.75 0];
list{'graphics'}{'green'} = [.25 0.75 0.1];
list{'graphics'}{'stimulus diameter'} = 10;
list{'graphics'}{'fixation diameter'} = 0.2;
list{'graphics'}{'feedback diameter'} = 0.22;
list{'graphics'}{'leftward'} = 180;             %***Consider changing here
list{'graphics'}{'rightward'} = 0;

%% Graphics:
% Create some drawable objects. Configure them with the constants above.


% Trial counter
logic = list{'object'}{'logic'};
counter = dotsDrawableText();
counter.string = strcat(num2str(logic.blockTotalTrials + 1), '/', num2str(logic.trialsPerBlock));
counter.color = list{'graphics'}{'gray'};
counter.isBold = true;
counter.fontSize = 20;
counter.x = 0;
counter.y = -9;

%Center points used to indicate fixation, trial start, and correctness
    % a fixation point
    fp = dotsDrawableTargets();
    fp.colors = list{'graphics'}{'gray'};
    fp.width = list{'graphics'}{'fixation diameter'};
    fp.height = list{'graphics'}{'fixation diameter'};
    list{'graphics'}{'fixation point'} = fp;

    % que point
    qp = dotsDrawableTargets();
    qp.colors = list{'graphics'}{'lightgray'};
    qp.width = list{'graphics'}{'fixation diameter'};
    qp.height = list{'graphics'}{'fixation diameter'};
    list{'graphics'}{'fixation point'} = qp;

    feedback = dotsDrawableTargets();
    feedback.colors = list{'graphics'}{'gray'};
    feedback.width = list{'graphics'}{'feedback diameter'};
    feedback.height = list{'graphics'}{'feedback diameter'};
    feedback.xCenter = 0;
    feedback.yCenter = 0;
    feedback.isVisible = false;
    list{'graphics'}{'feedback marker'} = feedback;
    
    
    
%Target stimulus 
    target=dotsDrawableVertices();
    target.colors=[.05,.05,.05];        %Dark grey dot
    target.x=5;
    target.y=0;
    target.pixelSize=10;
    target.isVisible=false;
    list{'graphics'}{'target'}=target; 
    
%Mouse Marker
    MM=dotsDrawableVertices();
    MM.colors=[.75 .0 .75];        %Dark grey dot
    MM.x=0;
    MM.y=5;
    MM.pixelSize=10;
    target.isVisible=true;
    list{'graphics'}{'Mouse Marker'}=MM; 

    


% aggregate all these drawable objects into a single ensemble
%   if isClient is true, graphics will be drawn remotely

drawables = dotsEnsembleUtilities.makeEnsemble('drawables', isClient);

qpInd = drawables.addObject(qp);
feedbackInd = drawables.addObject(feedback);
targInd=drawables.addObject(target);
fpInd = drawables.addObject(fp);
counterInd = drawables.addObject(counter);
MMInd=drawables.addObject(MM);


% automate the task of drawing all these objects
drawables.automateObjectMethod('draw', @mayDrawNow);

% also put dotsTheScreen into its own ensemble
screen = dotsEnsembleUtilities.makeEnsemble('screen', isClient);
screen.addObject(dotsTheScreen.theObject());


% automate the task of flipping screen buffers
screen.automateObjectMethod('flip', @nextFrame);

list{'graphics'}{'drawables'} = drawables;
list{'graphics'}{'fixation point index'} = fpInd;
list{'graphics'}{'feedback marker index'} = feedbackInd;
list{'graphics'}{'target index'}= targInd;
list{'graphics'}{'counter index'} = counterInd;
list{'graphics'}{'MM Index'}=MMInd;

list{'graphics'}{'screen'} = screen;

%% Input:
% Create an input source.
% keyboard inputs
keyOpt.PrimaryUsageName = 'Keyboard';
kb = dotsReadableHIDKeyboard(keyOpt);
ui = kb;

% define movements, which must be held down
%   map f-key -1 to left and j-key +1 to right
isF = strcmp({kb.components.name}, 'KeyboardF');
isJ = strcmp({kb.components.name}, 'KeyboardJ');

fKey = kb.components(isF);
jKey = kb.components(isJ);

uiMap.left.ID = fKey.ID;
uiMap.right.ID = jKey.ID;
kb.setComponentCalibration(fKey.ID, [], [], [0 -1]);
kb.setComponentCalibration(jKey.ID, [], [], [0 +1]);

% undefine any default events
IDs = kb.getComponentIDs();
for ii = 1:numel(IDs)
    kb.undefineEvent(IDs(ii));
end

% define events, which fire once even if held down
%   pressing f or j is a 'moved' event
%   pressing space bar is a 'commit' event
kb.defineEvent(fKey.ID, 'moveccw', 0, 0, true);
kb.defineEvent(jKey.ID, 'movecw', 0, 0, true);
isSpaceBar = strcmp({kb.components.name}, 'KeyboardSpacebar');
spaceBar = kb.components(isSpaceBar);
kb.defineEvent(spaceBar.ID, 'commit', spaceBar.CalibrationMax);

isEsc = strcmp({kb.components.name}, 'KeyboardEscape');
EscKey = kb.components(isEsc);
kb.defineEvent(EscKey.ID, 'exit', 0, 0, true);

list{'input'}{'controller'} = ui;
list{'input'}{'mapping'} = uiMap;


compMouse = dotsReadableHIDMouse();
    %m = dotsReadableHIDMouse;
    compMouse.isExclusive = 0;
    compMouse.isAutoRead = 1;
     
    compMouse.flushData;
    compMouse.initialize();
     
     
    % undefine any default events
    IDs = compMouse.getComponentIDs();
    for ii = 1:numel(IDs)
        compMouse.undefineEvent(IDs(ii));
    end
    %Define a mouse button press event
    compMouse.defineEvent(3, 'left', 0, 0, true);
    compMouse.defineEvent(4, 'right', 0, 0, true);
    %store the mouse separately in case we need to use it
    list{'input'}{'mouse'} = compMouse;

%% Outline the structure of the experiment with topsRunnable objects
%   visualize the structure with tree.gui()
%   run the experiment with tree.run()

% "tree" is the start point for the whole experiment
tree = topsTreeNode('ODR task');
tree.iterations = 1;
tree.startFevalable = {@callObjectMethod, screen, @open};
tree.finishFevalable = {@wrapUp, list};

% "session" is a branch of the tree with the task itself
session = topsTreeNode('session');
session.iterations = logic.nBlocks;
session.startFevalable = {@startSession, logic};
tree.addChild(session);

block = topsTreeNode('block');
block.iterations = logic.trialsPerBlock;
block.startFevalable = {@startBlock, logic};
session.addChild(block);

trial = topsConcurrentComposite('trial');
block.addChild(trial);

trialStates = topsStateMachine('trial states');
trial.addChild(trialStates);


viewSlides = topsConcurrentComposite('slide show');
viewSlides.startFevalable = {@flushData, ui};
viewSlides.finishFevalable = {@flushData, ui};

trialCalls = topsCallList('call functions');
trialCalls.addCall({@read, ui}, 'read input');


instructionStates = topsStateMachine('instruction states');
viewSlides.addChild(instructionStates);

instructionCalls = topsCallList('instruction updates');
instructionCalls.alwaysRunning = true;
viewSlides.addChild(instructionCalls);

list{'outline'}{'tree'} = tree;





%% Organize the presentation of instructions
% the instructions state machine will respond to user input commands
states = { ...
    'name'      'next'      'timeout'	'entry'     'input'; ...
    'showSlide' ''          logic.decisiontime_max    {}          {@getNextEvent ui}; ...
     'rightFine' 'showSlide' 0           {}	{}; ...
     'leftFine'  'showSlide' 0           {} {}; ...
    'commit'     ''          0           {}          {}; ...
    };
instructionStates.addMultipleStates(states);
% instructionStates.startFevalable = {@doMessage, list, ''};
% instructionStates.finishFevalable = {@doMessage, list, ''};

% the instructions call list runs in parallel with the state machine
instructionCalls.addCall({@read, ui}, 'input');



%% Trial
% Define states for trials with constant timing.

tFeed = list{'timing'}{'feedback'};

% define shorthand functions for showing and hiding ensemble drawables
on = @(index)drawables.setObjectProperty('isVisible', true, index);
off = @(index)drawables.setObjectProperty('isVisible', false, index);
cho = @(index)drawables.setObjectProperty('colors', [0.25 0.25 0.25], index);
chf = @(index)drawables.setObjectProperty('colors', [0.45 0.45 0.45], index);

fixedStates = { ...
    'name'      'entry'         'timeout'	'exit'          'next'      'input'; ...
    'prepare1'  {on, [fpInd counterInd]} 0 {}           'pause'     {}; ...
    'pause'     {chf, fpInd}         0      {@run viewSlides} 'pause2'    {};...     %Testing replacing instructions with viewSlides 
    'pause2'    {cho, fpInd}         1       {@flushui, list}    'prepare2'  {};...
    'prepare2'  {on,  qpInd}         0       {@editState,trialStates,list,logic}  'turn on target' {}; ... %Change time of target on depending on if is a Visual or Memory
    'turn on target' {on,targInd}    0       {off, targInd}         'delay' {};  
    'delay'     {}                   0       {chf fpInd}    'flush' {};  %indicate should make response
    'flush'     {@flushui, list}     0    {@setTimeStamp, logic}             'decision'     {}; ...
    'display mouse' {on, MMInd}      0      {}          'decision'  {} ;
    'decision'  {@MoveMarker, list}  0   {}  'show feedback'  {}; ...
    'show feedback' {@showFeedback, list} tFeed {} 'counter' {};
    'counter'  {on, [counterInd]}  0   {}              'set'          {}; ... % always a good trial for now
    'set'  {@setGoodTrial, logic}  0   {}              ''          {}; ...
    'exit'     {@closeTree,tree}          0           {}          ''  {}; ...
    };


trialStates.addMultipleStates(fixedStates);
trialStates.startFevalable = {@configStartTrial, list};
trialStates.finishFevalable = {@configFinishTrial, list};
list{'control'}{'trial states'} = trialStates;

trial.addChild(trialCalls);
trial.addChild(drawables);
trial.addChild(screen);


%% Custom Behaviors:
% Define functions to handle some of the unique details of this task.


function editState(trialStates, list, logic)
logic = list{'object'}{'logic'};
trialStates.editStateByName('turn on target', 'timeout', logic.durationTarget);
trialStates.editStateByName('delay', 'timeout', logic.durationDelay);


function MoveMarker(list)
compMouse=list{'input'}{'mouse'};
logic = list{'object'}{'logic'};
MMind=list{'graphics'}{'Mouse Marker'};
s=list{'screen'}{'actual screen'};
qp=list{'graphics'}{'fixation point'};
target=list{'graphics'}{'target'}; 
compMouse.flushData;
scaleFac = 68.3944;
mXprev = compMouse.x/scaleFac;
mYprev = compMouse.y/scaleFac;
sensitivityFac =   0.6*0.9; %1.5*0.9; -- might want to lower this for motor error
theta = pi/2;
state = [];
MMind.x=0;
MMind.y=5;


while(isempty(state))
        compMouse.read();
        state = compMouse.getNextEvent();
        mXcurr = compMouse.x/scaleFac; mYcurr = -compMouse.y/scaleFac;
        dTheta = sensitivityFac*[mXcurr-mXprev mYcurr-mYprev]*...
                [-MMind.y MMind.x]'/(logic.targRadius^2);
        if(theta + dTheta >= (0) && ...
            theta + dTheta <= (2*pi))
                theta = theta + dTheta;
        elseif theta + dTheta < (0)
                theta = 2*pi+(theta + dTheta);
        else
                theta =(theta + dTheta)-2*pi;
        end
                     
                    %update the dot location
        MMind.x = logic.targRadius*cos(theta);
        MMind.y = logic.targRadius*sin(theta);
       

        MMind.draw; qp.draw;
        
        
                     
        s.nextFrame();
        mXprev = mXcurr;
        mYprev = mYcurr;
end
logic.guessAngle=theta*180/pi;



function flushui(list)
ui = list{'input'}{'controller'};
compMouse=list{'input'}{'mouse'};
ui.flushData;
compMouse.flushData;
list{'control'}{'current choice'} = 'none';

function configStartTrial(list)
% start Logic trial
logic = list{'object'}{'logic'};
logic.startTrial;

% clear data from the last trial
ui = list{'input'}{'controller'};
compMouse=list{'input'}{'mouse'};
ui.flushData;
compMouse.flushData;
list{'control'}{'current choice'} = 'none';

% reset the appearance of targets and cursor
%   use the drawables ensemble, to allow remote behavior
drawables = list{'graphics'}{'drawables'};
feedbackInd = list{'graphics'}{'feedback marker index'};
targInd = list{'graphics'}{'target index'};
MMInd=list{'graphics'}{'MM Index'};
drawables.setObjectProperty( ...
    'colors', list{'graphics'}{'gray'}, [feedbackInd]);

%Pick location of target from normal dist with mean of logic.distMean and
%SD of logic.distSTD
logic.targetAngle = logic.distSTD*randn+logic.distMean;  
if logic.targetAngle<0
    logic.targetAngle=360+logic.targetAngle;
elseif logic.targetAngle>360
    logic.targetAngle=mod(logic.targetAngle,360);
end


% let all the graphics set up to draw in the open window
drawables.setObjectProperty('isVisible', false);
                
%Set the location of the target to the chosen location
drawables.setObjectProperty( ...
    'x', logic.targRadius*cos(logic.targetAngle*pi/180), [targInd]);

drawables.setObjectProperty( ...
    'y', logic.targRadius*sin(logic.targetAngle*pi/180), [targInd]);

%Set location of the response indicator mouse to 90 degrees
drawables.setObjectProperty( ...
    'x', 0, [MMInd]);

drawables.setObjectProperty( ...
    'y', logic.targRadius, [MMInd]);


                
drawables.callObjectMethod(@prepareToDrawInWindow);

function configFinishTrial(list)
% finish logic trial
logic = list{'object'}{'logic'};
logic.finishTrial;

% % print out the block and trial #
% disp(sprintf('block %d/%d, trial %d/%d',...
%     logic.currentBlock, logic.nBlocks,...
%     logic.blockTotalTrials, logic.trialsPerBlock));

%%% DATA RECORDING -- this takes up a lot of time %%%

tt = logic.blockTotalTrials;
bb = logic.currentBlock;
statusData = list{'logic'}{'statusData'};
statusData(tt,bb) = logic.getStatus();
list{'logic'}{'statusData'} = statusData;

% [dataPath, dataName, dataExt] = fileparts(logic.dataFileName);
% if isempty(dataPath)
%     dataPath = dotsTheMachineConfiguration.getDefaultValue('dataPath');
% end
% dataFullFile = fullfile(dataPath, dataName);
% save(dataFullFile, 'statusData')

% write new tops flow-of-control data to disk
%topsDataLog.writeDataFile();


%%% END %%%


% only need to wait our the intertrial interval
pause(list{'timing'}{'intertrial'});


function showFeedback(list)
logic = list{'object'}{'logic'};
% hide the fixation point and cursor
drawables = list{'graphics'}{'drawables'};
fpInd = list{'graphics'}{'fixation point index'};
feedbackInd = list{'graphics'}{'feedback marker index'};
targInd = list{'graphics'}{'target index'};
counterInd = list{'graphics'}{'counter index'};
logic.setDetection();
drawables.setObjectProperty('isVisible', false, [fpInd]);
drawables.setObjectProperty('isVisible', true, [feedbackInd]);

ui = list{'input'}{'controller'};

logic.keyhistory = ui.history;



target = drawables.getObject(targInd);

targetstrct = obj2struct(target);

logic.targetstrct = targetstrct;

%Designated correct if less than 5 degrees off
if abs(logic.guessAngle-logic.targetAngle)<10   %
    drawables.setObjectProperty( ...
        'colors', list{'graphics'}{'green'}, feedbackInd);
    logic.correct = 1;
else
    drawables.setObjectProperty( ...
        'colors', list{'graphics'}{'red'}, feedbackInd);
    logic.correct = 0;

end


%Add a number to the trial number counter    
drawables = list{'graphics'}{'drawables'};
drawables.setObjectProperty('string', strcat(num2str(logic.blockTotalTrials + 1), '/',...
    num2str(logic.trialsPerBlock)), counterInd);




function wrapUp(list)
uiMap = list{'input'}{'mapping'};
if strcmp(uiMap, 'mouse')
    ui = list{'input'}{'controller'};
    ui.isExclusive = false;
    ui.initialize;
end

screen = list{'graphics'}{'screen'};
screen.callObjectMethod(@close);



