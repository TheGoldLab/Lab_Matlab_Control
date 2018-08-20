function [tree, list] = FallingBallTaskPrediction(logic, isClient)
%If you are running this script and not FallingBallTaskRun then uncomment
%clear all and clc, otherwise it'll start to run extremely slow. Do not
%uncomment if you are running FallingBallTaskRun or you'll clear out the
%variables needed.

% clear all;
% clc;
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 1);
%The settings file should force any displays with resolutions bigger than 1080p to scale
%down so that the experiment looks "normal."
% dotsTheMachineConfiguration.readUserSettingsFile('/Volumes/Untitled/FallingBallsHelicopterVersion/DotsScreenSetup.xml')





if nargin < 1 || isempty(logic)
    logic = Logic();
end

if nargin < 2
    isClient = false;
end



%% *************************
%
% TASK VARIABLES
%
%   Use a topsGroupedList to make a list of task data and objects,
%   partitioned into groups.
%   Advantages:
%       - keeps them all in one place
%       - conveniently labeled groups!
%       - items can be accessed by name
%       - items can be accessed anywhere you pass the list
list = topsGroupedList('falling balls data');
list{'object'}{'logic'} = logic;
% +++ Add some constants that define task behavior
% +++
%This is the mean of the RedBall used for the normal distribution
list{'Stimulus'}{'RedMean'} = normrnd(0,logic.Sigma0);
list{'Stimulus'}{'RedBallpass'} = 0;
% Timing properties
list{'timing'}{'counter'}       = 0;
list{'timing'}{'prepare'}       = 1;
list{'timing'}{'stimulus'}      = 2;
list{'timing'}{'choice'}        = 10;
list{'timing'}{'intertrial'}    = 1;
list{'timing'}{'set time'}      = .60;
list{'timing'}{'rest time'}     = 1;

% Graphics properties
list{'graphics'}{'isClient'}          = isClient;
list{'graphics'}{'white'}             = [1 1 1];
list{'graphics'}{'gray'}              = [0.6 0.6 0.6];
list{'graphics'}{'red'}               = [1 0.25 0.1];
list{'graphics'}{'green'}             = [0.25 0.75 0.1];
list{'graphics'}{'blue'}              = [0.1 0.25 1.0];
list{'graphics'}{'brown'}             = [0.6 0.2 0.9];
list{'graphics'}{'ball diameter'}     = 0.4;
list{'graphics'}{'target diameter'}   = 0.3;
list{'graphics'}{'ceiling width'}     = 10;  % in pix
list{'graphics'}{'ground width'}      = 10;


list{'graphics'}{'left side'}         = -6;
list{'graphics'}{'right side'}        = 6;
list{'graphics'}{'bottom'}            = -3;
list{'graphics'}{'almost bottom'}     = list{'graphics'}{'bottom'}+ .3;
list{'graphics'}{'top'}               = 3;
list{'graphics'}{'almost top'}        = list{'graphics'}{'top'} -.3;

list{'graphics'}{'animation time'}    = .5;

% list{'mouse'}{'movement'}             = [];
list{'target'}{'feedback number'}     = {};
list{'trial'}{'mouse position'}       = {};
list{'mouse'}{'counter'}              = 0;
list{'mouse'}{'trial'}                = {};
list{'stimulus'}{'changepoint'}       = {};

%% *************************
%
% GRAPHICS
%

% +++ Create and configure Drawable objects, adding
% +++   to an ensemble as we go
% +++
drawables = dotsEnsembleUtilities.makeEnsemble(...
    'drawables', list{'graphics'}{'isClient'});


% texture -- due to Kamesh
% isoColor1 = [0 0 0];
% isoColor2 = [150 150 150];
% checkerH = 500;
% checkerW = 30;
% boardheight = floor((dotsTheScreen.theObject.displayPixels(4))/3.6);
% boardwidth = floor((dotsTheScreen.theObject.displayPixels(3))/1.94);
% 
% checkTexture1 = dotsDrawableTextures();
% checkTexture1.textureMakerFevalable = {@kameshTextureMaker,...
% checkerH,checkerW,boardheight,boardwidth,isoColor1,isoColor2};
% drawables.addObject(checkTexture1);

% +++ dotsDrawableLines objects: the ceiling and ground
% +++
ceiling = dotsDrawableLines();
ceiling.xFrom     = -10;
ceiling.xTo       = 10;
ceiling.yFrom     = [list{'graphics'}{'top'}];
ceiling.yTo       = [list{'graphics'}{'top'}];
ceiling.pixelSize = list{'graphics'}{'ceiling width'};
ceiling.colors    = [list{'graphics'}{'gray'}];
ceiling_index     = drawables.addObject(ceiling);

ground = dotsDrawableLines();
ground.xFrom     = -10;
ground.xTo       = 10;
ground.yFrom     = [list{'graphics'}{'bottom'}];
ground.yTo       = [list{'graphics'}{'bottom'}];
ground.pixelSize = list{'graphics'}{'ground width'};
ground.colors    = [list{'graphics'}{'gray'}];
ground_index     = drawables.addObject(ground);


% +++ dotsDrawableTargets object: target for sample on the ground (_g)
% +++


% +++ dotsDrawableTargets object: mask on the ceiling 
% +++

% +++ dotsDrawableText object: Question prompt above the ceiling
% +++
question = dotsDrawableText();
question.string = 'Where will the Green Ball fall next?';
question.color  = [1 1 1];
question.fontSize = 32;
question.y      = list{'graphics'}{'top'} + 7;
question_index  = drawables.addObject(question);

blackout         = dotsDrawableTargets();
blackout.colors  = [0 0 0];
blackout.width   = 30;
blackout.height  = 30;
blackout.xCenter = 0; 
blackout.yCenter = 0;
blackout_index   = drawables.addObject(blackout);

mask = dotsDrawableImages();
mask.fileNames = {'cloud.png'};
mask.x         = 0;
mask.y         = list{'graphics'}{'top'} + 2;
mask.width     = 20;
mask.height    = 4;
mask_index     = drawables.addObject(mask);

target_g         = dotsDrawableImages();
target_g.fileNames = {'super_tube.png'};
target_g.width   = 1;
target_g.height  = 1;
target_g.x = 0; 
target_g.y = list{'graphics'}{'bottom'} + .3;
target_g_index   = drawables.addObject(target_g);



% +++ Automate the task of drawing all these objects
% +++
%   drawables.automateObjectMethod('draw', @mayDrawNow);

% The static drawFrame() takes a cell array of objects
drawables.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

% +++ Save the drawables and useful groups of indices in the list
% +++

list{'graphics'}{'drawables'}          = drawables;
list{'graphics'}{'ceiling index'}      = ceiling_index;
list{'graphics'}{'ground index'}       = ground_index;
list{'graphics'}{'mask index'}         = mask_index;
list{'graphics'}{'target index'}       = target_g_index;
list{'graphics'}{'question'}           = question_index;
list{'graphics'}{'blackout'}          = blackout_index;


% +++ Configure the screen
% +++
%  This will automate the task of flipping screen buffers
screen = dotsEnsembleUtilities.makeEnsemble(...
    'screen', list{'graphics'}{'isClient'});
screen.automateObjectMethod('flip', @nextFrame);
screen.addObject(dotsTheScreen.theObject());
list{'graphics'}{'screen'} = screen;

%% *************************
%
% INPUT
%

% +++ Create an input source.
% +++
% First, try to find a mouse.  If there's no mouse, use the keyboard.
gp = dotsReadableHIDMouse();
if gp.isAvailable
    % use the gamepad
    ui = gp;
    
    % define movements, which must be held down
    %   map x-axis -1 to left and +1 to right
    isX = strcmp({gp.components.name}, 'x');
    xAxis = gp.components(isX);
    uiMap.left.ID = xAxis.ID;
    uiMap.right.ID = xAxis.ID;
    gp.setComponentCalibration(xAxis.ID, [], [], [-5 +5]);
    
    % undefine any default events
    IDs = gp.getComponentIDs();
    for ii = 1:numel(IDs)
        gp.undefineEvent(IDs(ii));
    end
    
    % define events, which fire once even if held down
    %   any non-zero x-axis position is a 'moved' event
    %   pressing the primary button is a 'commit' event
    gp.defineEvent(xAxis.ID, 'move', 0, 0, true);
    isButtonOne = [gp.components.ID] == gp.buttonIDs(1);
    buttonOne = gp.components(isButtonOne);
    gp.defineEvent(buttonOne.ID, 'commit', buttonOne.CalibrationMax);
    isButtonThree = [gp.components.ID] == gp.buttonIDs(3);
    buttonThree = gp.components(isButtonThree);
    gp.defineEvent(buttonThree.ID, 'break', buttonThree.CalibrationMax);
    
    
else
    % fallback on keyboard inputs
    kb = dotsReadableHIDKeyboard();
    ui = kb;
    
    % define movements, which must be held down
    %   map f-key -1 to left and j-key +1 to right
    isF  = strcmp({kb.components.name}, 'KeyboardF');
    isJ  = strcmp({kb.components.name}, 'KeyboardJ');
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
    kb.defineEvent(fKey.ID, 'move', 0, 0, true);
    kb.defineEvent(jKey.ID, 'move', 0, 0, true);
    isSpaceBar = strcmp({kb.components.name}, 'KeyboardSpacebar');
    spaceBar = kb.components(isSpaceBar);
    kb.defineEvent(spaceBar.ID, 'commit', spaceBar.CalibrationMax);
   
end
list{'input'}{'controller'}     = ui;
list{'input'}{'mapping'}        = uiMap;
list{'input'}{'startTime'}      = 0;    % TD: the time when positionBall() is called fo the first time on a given trial
list{'input'}{'repeatInterval'} = 0.05;
list{'input'}{'lastMoveTime'}   = 0;


%Containers for trial data
list{'input'}{'target'} = [];
list{'input'}{'sample'} = [];
list{'input'}{'mean'} = []; 




list{'Stimulus'}{'GreenBallpass'} = 0;
list{'Stimulus'}{'GreenBall'}   = 0;
list{'target'}{'commit'}      = 0;

%% *************************
%
% CONTROL
%

% +++ topsTreeNode organizes flow outside of trials
% +++
%   This is the trunk of the tree, branches are added below
tree = topsTreeNode('falling balls task');
tree.iterations      = 1;
tree.startFevalable  = {@startTree,  list};
tree.finishFevalable = {@finishTree, list};



    
% +++ topsCallList organizes calls to groups of functions during trials
% +++
%   A batch of function calls that apply to all the trial types below
%   start- and finishFevalable get called once per trial
%   addCall() accepts fevalables to be called repeatedly during a trial
trialCalls = topsCallList('call functions');
trialCalls.addCall({@read, ui}, 'read input');
list{'control'}{'trial calls'} = trialCalls;

% +++ topsStateMachine organizes flow within trials
% +++

% +++ fixedMachine does the simple stuff on each trial
fixedMachine = topsStateMachine('fixed states');

% define useful variables, including 
%   anonymous functions for showing and hiding ensemble drawables
on      = @(index)drawables.setObjectProperty('isVisible', true,  index);
off     = @(index)drawables.setObjectProperty('isVisible', false, index);
Fpos    = {@positionBall, list};
quest   = list{'graphics'}{'question'};
tSet    = list{'timing'}{'set time'};
tAni    = list{'graphics'}{'animation time'};
tIT     = list{'timing'}{'intertrial'};
tChoice = list{'timing'}{'choice'};
blackbox = list{'graphics'}{'blackout'};

%Pposition is called when Probe Trials start. It's purpose is to just make the
%question appear above. Pset is there just so the balls don't hang in the
%air after user input like they would on an observation trial.
fixedStates = { ...
    'name'      'entry'    'input' 'timeout' 'exit'  'next'; ...
    'Being'     {} {}      0        {off blackbox}  'prepare';...
    'prepare'   {}   {@test, list}       0       {}      'position'; ...
    'Pposition' {}    {}     0       {}     'position';...
    'position'  {}           Fpos    tChoice       {}              'set'; ...
    'Pset'      {@Set_cue, list} {}      tSet-tSet    {}   'animate';...
    'set'       {@Set_cue, list} {}       tSet-tSet        {}   'animate';...   
    'animate'   {@startAnimation, list}      {}       tAni      {}      'finish'; ...
    'finish'    {@finishTrial, list}           {}         tIT      {}       ''; ...
    
    };
fixedMachine.addMultipleStates(fixedStates);
fixedMachine.startFevalable  = {@startTrial,  list};
fixedMachine.finishFevalable = {@finishTrial, list};
list{'control'}{'fixed time machine'} = fixedMachine;

% +++ topsConcurrentComposite interleaves behaviors of the state machine,
% +++	function calls, and drawing graphics
% +++
fixedConcurrents = topsConcurrentComposite('run() concurrently:');
fixedConcurrents.addChild(trialCalls);
fixedConcurrents.addChild(fixedMachine);
fixedConcurrents.addChild(drawables);

% add a branch to the tree trunk to launch a Fixed Time trial
Trials = tree.newChildNode('Trials');
Trials.iterations = logic.nTrials;

% fixedTree.addChild(fixedConcurrents);
Trials.addChild(fixedConcurrents);
%% *************************
%
% RUN IT!
%
tree.run
% g = topsDataLog.gui();

%% *************************
%
% CUSTOM BEHAVIORS
%
% Define functions to handle some of the unique details of this task.

% ++++++++
% FUNCTION: startTree
%
function startTree(list)
if true
    % Open the screen
    theScreen = list{'graphics'}{'screen'};
    theScreen.callObjectMethod(@open);

    drawables = list{'graphics'}{'drawables'};


    mask_index = list{'graphics'}{'mask index'};
    question_index = list{'graphics'}{'question'};
    drawables.setObjectProperty('isVisible',false,mask_index);
    drawables.setObjectProperty('isVisible',false,question_index);

    
end


% ++++++++
% FUNCTION: Probe
% Determines if the next trial should be a probe trial
function next_state_ = test(list)

%Import Logic properties
logic = list{'object'}{'logic'};
drawables = list{'graphics'}{'drawables'};
mask_index = list{'graphics'}{'mask index'};
question_index = list{'graphics'}{'question'};
%Import counter container
list{'timing'}{'counter'} = list{'timing'}{'counter'} + 1;
stim_counter = list{'timing'}{'counter'};

%How observation trials are created
if stim_counter <= logic.observation;
    list{'input'}{'target'} = [list{'input'}{'target'}, 99];
    next_state_ = 'set';
else    
    drawables.setObjectProperty('isVisible',true, mask_index);
    drawables.setObjectProperty('isVisible', true, question_index);
    next_state_ = 'Pposition';
end

% ++++++++
% FUNCTION: startTrial
%
function startTrial(list) 
    % clear data from the last trial
    ui = list{'input'}{'controller'};
    ui.flushData();
    list{'control'}{'current choice'} = 'none';
    drawables = list{'graphics'}{'drawables'};
    
    % prepare to draw -- show static balls, hide falling balls
    gTI = list{'graphics'}{'target index'};  
    drawables.setObjectProperty('isVisible', true, gTI);
    
    
    ground   = list{'graphics'}{'ground index'}; 
    ceiling  = list{'graphics'}{'ceiling index'};
    drawables.setObjectProperty('isVisible', true, [ground ceiling]);

    
list{'mouse'}{'counter'} = list{'mouse'}{'counter'} + 1;
list{'mouse'}{'trial'} = {};



%Import logic for hazard rate
logic = list{'object'}{'logic'};
Hazard = logic.H;
%Number used to compare to Hazard and see if RedBall_position will change
B = unifrnd(0,1); % unifrnd is returns random numbers generated from the continuous uniform distributions with lower and upper endpoints specified by input 1 and 2  


%Seeing if the RedBall_mean will change or remain the same
RedBall_position = list{'Stimulus'}{'RedMean'};
if  B <= Hazard;
    RedBall_position = normrnd(0,logic.Sigma0);
    list{'stimulus'}{'changepoint'} = [list{'stimulus'}{'changepoint'}, 1];

else
    list{'stimulus'}{'changepoint'} = [list{'stimulus'}{'changepoint'}, 0];

end
%Indicates start of trial for mouse movement
list{'Stimulus'}{'RedMean'} = RedBall_position;

stim_counter = list{'timing'}{'counter'};

% flyingSlideShow = dotsDrawableAnimator();
% % flyingSlideShow.isAggregateDraw = false;
% flyingSlideShow.addDrawable(arrow);
% xTimes = [0 RedBall_position];
% xPoints = [0 RedBall_position];
% xInterpolated = true;
% flyingSlideShow.addMember('x', xTimes, xPoints, xInterpolated);
% flyingSlideShow.setMemberCompletionStyle('x', 'stop');
% 
% drawables.addObject(flyingSlideShow);
% drawables.callObjectMethod(@prepareToDrawInWindow);
if stim_counter <= (logic.observation - 1);
gTI       = list{'graphics'}{'target index'};
drawables.setObjectProperty('isVisible', false, gTI);

arrow = dotsDrawableImages();
arrow.fileNames = {'Lakitu.png'};
arrow.x = list{'Stimulus'}{'RedMean'};
arrow.y = 4.1;
arrow.height = 2;
arrow.width  = 2;
arrow_cue = drawables.addObject(arrow);
list{'stimulus'}{'down arrow'} = arrow_cue;
end
 

% ++++++++
% FUNCTION: Set_cue
%    
function Set_cue(list)

drawables = list{'graphics'}{'drawables'};
logic = list{'object'}{'logic'};
stim_counter = list{'timing'}{'counter'};
%Pulls a random number from a distribution and is used for the Red Balls X
%location
rng('shuffle')
distribM = list{'Stimulus'}{'RedMean'};

%Pulls a random number from a distribution and is used for the Green Balls X
%location
sample_sigma = logic.R * logic.Sigma0;
%If distribs falls outside the bounds of user input, resample position
distribS = normrnd(distribM,sample_sigma);
    while distribS > 6 || distribS < -6
        distribS = normrnd(distribM,sample_sigma);
    end
    
%This creates the gauss curve based off the RedBall mean
if stim_counter <= logic.observation;
v = dotsDrawableVertices();
v.colors = [1 .5 .25];
v.indices = [];
v.x = [-10:.1:10];
%The scaling of the gauss curve in relation to Sigma0 is in "units" of 15. Anything else and the
%curve will exceed or fall below the ceiling.
v.y = normpdf(v.x,distribM,sample_sigma);
v.z = 0;
v.isSmooth = true;
v.pixelSize = 5;
v.translation = [0 -3 0];
v.scaling = [1 15*sample_sigma 0];
v.rotation = [0 0 0];
v.primitive = 1;
v_cue = drawables.addObject(v);
list{'Stimulus'}{'Curve'} = v_cue;
end

list{'Stimulus'}{'RedBallpass'} = distribM;

% 
% %Create Green Ball/sample ball
fall_ball_samp = dotsDrawableTargets();
fall_ball_samp.width   = list{'graphics'}{'ball diameter'};
fall_ball_samp.height  = list{'graphics'}{'ball diameter'};
fall_ball_samp.xCenter = distribS;
fall_ball_samp.yCenter = list{'graphics'}{'almost top'};
fall_ball_samp.colors  = list{'graphics'}{'green'};
fall_ball_samp_cue = drawables.addObject(fall_ball_samp);
list{'Stimulus'}{'GreenBallpass'} = distribS;
list{'Stimulus'}{'GreenBall'} = distribS;
list{'Stimulus'}{'fall ball samp cue'} = fall_ball_samp_cue;

% %Add the fallings balls X positions to a list for saving
list{'input'}{'sample'} = [list{'input'}{'sample'}, distribS];
list{'input'}{'mean'}   = [list{'input'}{'mean'}, distribM];

% ++++++++
% FUNCTION: startAnimation
%
function startAnimation(list)
if true
    
logic     = list{'object'}{'logic'};    
drawables = list{'graphics'}{'drawables'};
fall_ball_samp_cue = list{'Stimulus'}{'fall ball samp cue'};
drawables.setObjectProperty('isVisible', false, [fall_ball_samp_cue]);



fall_ball_samp_ani = dotsDrawableTargets();
fall_ball_samp_ani.width   = list{'graphics'}{'ball diameter'};
fall_ball_samp_ani.height  = list{'graphics'}{'ball diameter'};
fall_ball_samp_ani.xCenter = list{'Stimulus'}{'GreenBallpass'};
fall_ball_samp_ani.yCenter = list{'graphics'}{'top'};
fall_ball_samp_ani.colors  = list{'graphics'}{'green'};

% Creates the falling ball animation for the Red Ball
ballAnimator_samp = dotsDrawableAnimator();
ballAnimator_samp.addDrawable(fall_ball_samp_ani);
ballAnimator_samp.addMember('yCenter', [0 list{'graphics'}{'animation time'}], ...
    [list{'graphics'}{'almost top'} list{'graphics'}{'almost bottom'}], true);
ballAnimator_samp.setMemberCompletionStyle('yCenter', 'stop');
samp_fall= drawables.addObject(ballAnimator_samp);


%Put the falling balls in a list so that it can be used to turn them off at
%the end of each trial.
list{'graphics'}{'sample index'} = samp_fall;           


drawables.callObjectMethod(@prepareToDrawInWindow);

%let the balls fall. It takes just a tad bit longer than 1 second for the balls
%to completely fall. This is better to be set longer than 1 second
%otherwise the balls will almost reach the bottom, the tone will play and
%they will slightly jerk down to their final position afterwards.
drawables.run(list{'graphics'}{'animation time'} + .1);

end

% ++++++++
% FUNCTION: PositionBall
%

function next_state_ = positionBall(list)


if true

    % Get ui object
    ui = list{'input'}{'controller'};


    
    %% TD: retrieve input data
    % Is an event happening?
    [lastName, lastID, names, IDs] = ui.getHappeningEvent();
    
    % when a key was pressed once distinctly 
    if isempty(lastName)
        % Did an event happen and finish?
        [name, data] = ui.getNextEvent();


    else
        name = [];
        data = [];
        % check for move
        if any(strcmp(names, 'move'))       
                name = 'move';
                data = ui.state(IDs(find(strcmp(names, 'move'),1,'last')),:);                
        end
            
        if any(strcmp(names, 'commit'))
            name = 'commit';
            data = ui.state(IDs(find(strcmp(names, 'commit'),1,'last')),:);
        end
        if any(strcmp(names, 'break'))
            name = 'break';
            data = ui.state(IDs(find(strcmp(names,'break'),1,'last')),:);
        end
    end
    
    %% TD: act according to the retrieved data (, or lack thereof) 
    % default back to this state
    next_state_ = 'position';

        % move or commit
        drawables = list{'graphics'}{'drawables'};            
        gTI       = list{'graphics'}{'target index'};
        uiMap     = list{'input'}{'mapping'}; 
        % move it!
        if strcmp(name, 'move')

            left_side  = list{'graphics'}{'left side'};
            right_side = list{'graphics'}{'right side'};
            
            %Gets the current position of the target index
            current_position = drawables.getObjectProperty('x', gTI);          
            
                    
            %Adds the current trials mouse movement to be added to a
            %growing cell array at the end of the Trial
            list{'mouse'}{'trial'} = [list{'mouse'}{'trial'},current_position];
            
            %Gets the current mouse position
            new_position = ui.getValue(uiMap.left.ID);
            
            if new_position < left_side
                new_position = left_side;
            end
            if new_position > right_side
                new_position = right_side;
            end
            if new_position ~= current_position
                drawables.setObjectProperty('x', new_position, gTI);
            end
        
        % commit!
        elseif strcmp(name,'break')
            error('oh boy')
           
        elseif strcmp(name, 'commit')
            
                logic = list{'object'}{'logic'};
                stim_counter = list{'timing'}{'counter'};
            % gets x-value of the target ball when they commit            
            commit_position = drawables.getObjectProperty('x', gTI);
            
            % adds commit position to growing list            
            list{'input'}{'target'} = [list{'input'}{'target'}, commit_position];
            list{'target'}{'commit'} = commit_position;


            if stim_counter <= logic.observation
                next_state_ = 'set';
            else
                next_state_ = 'Pset';
            end
            
                
        end
        
end

% ++++++++
% FUNCTION: finishTrial
%
function finishTrial(list)

  
% hide the balls
    drawables = list{'graphics'}{'drawables'};
    logic = list{'object'}{'logic'};
    
    arrow_cue = list{'stimulus'}{'down arrow'};
    samp_fall = list{'graphics'}{'sample index'};    
    fall_ball_samp_cue= list{'Stimulus'}{'fall ball samp cue'};
    v_cue = list{'Stimulus'}{'Curve'};
    drawables.removeObject([samp_fall fall_ball_samp_cue arrow_cue v_cue]);
    
     
    %creates the growing cell array with col 1 being trial number and col 2
    %being mouse position for that individual trial.
    stim_counter = list{'mouse'}{'counter'};                
    mouse_trial = list{'mouse'}{'trial'};
    
    order = list{'trial'}{'mouse position'};
    order{stim_counter,1} = stim_counter;
    order{stim_counter, 2} = mouse_trial;
    list{'trial'}{'mouse position'} = order;
    
%stim_counter starts at 0 and observation starts at 1. Add 1 to observation so it lines up.    
if stim_counter >= logic.observation + 1    
    commit_position = list{'target'}{'commit'};
    distribS = list{'Stimulus'}{'GreenBall'};
    feedback_number = distribS + commit_position;

%Store the feedback number into a growing list
list{'target'}{'feedback number'} = [list{'target'}{'feedback number'}, feedback_number];
end

% Wait out the intertrial interval
%     pause(list{'timing'}{'intertrial'});


% ++++++++
% FUNCTION: finishTree
%
function finishTree(list)
if true
    % Close the screen    
    theScreen = list{'graphics'}{'screen'};
    theScreen.callObjectMethod(@close);
end