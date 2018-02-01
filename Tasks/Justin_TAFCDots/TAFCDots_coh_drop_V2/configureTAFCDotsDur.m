function [tree, list] = configureTAFCDotsDur(logic, isClient)
% for the within trial change-point task
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 0);

if nargin < 1 || isempty(logic)
    logic = TAFCDotsLogic();
end

if nargin < 2
    isClient = false;
end

%% Organization:
% Make a container for task data and objects, partitioned into groups.
list = topsGroupedList('TAFCDots data');

%% Important Objects:
list{'object'}{'logic'} = logic;

statusData = logic.getDataArray();
list{'logic'}{'statusData'} = statusData;

%% Constants:
% Store some constants in the list container, for use during configuration
% and while task is running
list{'constants'}{'counter'} = 1;
list{'constants'}{'alternate'} = 0;
list{'constants'}{'duration'} = 0;

list{'timing'}{'feedback'} = 0.2;
list{'timing'}{'intertrial'} = 0;

list{'graphics'}{'isClient'} = isClient;
list{'graphics'}{'white'} = [1 1 1];
list{'graphics'}{'lightgray'} = [0.65 0.65 0.65];
list{'graphics'}{'gray'} = [0.25 0.25 0.25];
list{'graphics'}{'red'} = [0.75 0.25 0.1];
list{'graphics'}{'yellow'} = [0.75 0.75 0];
list{'graphics'}{'green'} = [.25 0.75 0.1];
list{'graphics'}{'stimulus diameter'} = 10;
list{'graphics'}{'fixation diameter'} = 0.2;
list{'graphics'}{'target diameter'} = 0.22;
list{'graphics'}{'leftward'} = 180;
list{'graphics'}{'rightward'} = 0;

%% Graphics:
% Create some drawable objects. Configure them with the constants above.

% instruction messages
m = dotsDrawableText();
m.color = list{'graphics'}{'gray'};
m.fontSize = 48;
m.x = 0;
m.y = 0;

% a fixation point
fp = dotsDrawableTargets();
fp.colors = list{'graphics'}{'gray'};
fp.width = list{'graphics'}{'fixation diameter'};
fp.height = list{'graphics'}{'fixation diameter'};
list{'graphics'}{'fixation point'} = fp;

% counter
logic = list{'object'}{'logic'};
counter = dotsDrawableText();
counter.string = strcat(num2str(logic.blockTotalTrials + 1), '/', num2str(logic.trialsPerBlock));
counter.color = list{'graphics'}{'gray'};
counter.isBold = true;
counter.fontSize = 20;
counter.x = 0;
counter.y = -5.5;

% score
score = dotsDrawableText();
score.string = strcat('$', num2str(logic.score));
score.color = list{'graphics'}{'gray'};
score.isBold = true;
score.fontSize = 20;
score.x = 0;
score.y = -6;

% que point
qp = dotsDrawableTargets();
qp.colors = list{'graphics'}{'lightgray'};
qp.width = list{'graphics'}{'fixation diameter'};
qp.height = list{'graphics'}{'fixation diameter'};
list{'graphics'}{'fixation point'} = qp;

targs = dotsDrawableTargets();
targs.colors = list{'graphics'}{'gray'};
targs.width = list{'graphics'}{'target diameter'};
targs.height = list{'graphics'}{'target diameter'};
targs.xCenter = 0;
targs.yCenter = 0;
targs.isVisible = false;
list{'graphics'}{'targets'} = targs;

% a random dots stimulus
stim = dotsDrawableDynamicDotKinetogram();
stim.colors = list{'graphics'}{'white'};
stim.pixelSize = 5; % size of the dots
stim.direction = 0;
stim.density = 70;
stim.diameter = list{'graphics'}{'stimulus diameter'};
stim.isVisible = false;
list{'graphics'}{'stimulus'} = stim;

% aggregate all these drawable objects into a single ensemble
%   if isClient is true, graphics will be drawn remotely

drawables = dotsEnsembleUtilities.makeEnsemble('drawables', isClient);

qpInd = drawables.addObject(qp);
targsInd = drawables.addObject(targs);
stimInd = drawables.addObject(stim);
fpInd = drawables.addObject(fp);
counterInd = drawables.addObject(counter);
scoreInd = drawables.addObject(score);

% automate the task of drawing all these objects
drawables.automateObjectMethod('draw', @mayDrawNow);

% also put dotsTheScreen into its own ensemble
screen = dotsEnsembleUtilities.makeEnsemble('screen', isClient);
screen.addObject(dotsTheScreen.theObject());

messages = dotsEnsembleUtilities.makeEnsemble('messages', isClient);
msInd = messages.addObject(m);
messages.automateObjectMethod('drawMessage', @mayDrawNow);

% automate the task of flipping screen buffers
screen.automateObjectMethod('flip', @nextFrame);

list{'graphics'}{'drawables'} = drawables;
list{'graphics'}{'messages'} = messages;
list{'graphics'}{'fixation point index'} = fpInd;
list{'graphics'}{'targets index'} = targsInd;
list{'graphics'}{'stimulus index'} = stimInd;
list{'graphics'}{'counter index'} = counterInd;
list{'graphics'}{'score index'} = scoreInd;
list{'graphics'}{'screen'} = screen;
%% cohDrop initialization

ch_values = load('scriptRunValues/ch_values.mat');
coh_high = ch_values.coh_high;
coh_low = ch_values.coh_low;
length_of_drop = ch_values.length_of_drop;
length_of_high = ch_values.length_of_high;
minT = ch_values.minT;
maxT = ch_values.maxT;
H3 = ch_values.H3;
cp_maxT = ch_values.cp_maxT;
cp_minT = ch_values.cp_minT;
cp_H3 = ch_values.cp_H3;
TAC_on = ch_values.TAC_on;

%Duration defined for every trial. Now placed in starttrial
%logic.duration = duration;
logic.minT = minT;
logic.maxT = maxT;
list{'object'}{'logic'} = logic;
list{'graphics'}{'coh_high'} = coh_high;
list{'graphics'}{'coh_low'} = coh_low;
list{'graphics'}{'length_of_drop'} = length_of_drop;
list{'graphics'}{'length_of_high'} = length_of_high;
list{'graphics'}{'H3'} = H3;
list{'graphics'}{'cp_maxT'} = cp_maxT;
list{'graphics'}{'cp_minT'} = cp_minT;
list{'graphics'}{'cp_H3'} = cp_H3;
list{'graphics'}{'TAC_on'} = TAC_on;

%% Set Trial TAC
%currently hardcoded the amount of TAC. Should place control over this in
%the script. Need to make sure this matches up with the total trial number
array_of_TAC = repelem([.5],50);
array_of_TAC = array_of_TAC(randperm(size(array_of_TAC,2)));

trial_count = 1;
list{'TAC'}{'counter'} = trial_count;
list{'TAC'}{'TAC_Array'} = array_of_TAC;

%% Outline the structure of the experiment with topsRunnable objects
%   visualize the structure with tree.gui()
%   run the experiment with tree.run()

% "tree" is the start point for the whole experiment
tree = topsTreeNode('2AFC task');
tree.iterations = 1;
tree.startFevalable = {@callObjectMethod, screen, @open};
tree.finishFevalable = {};

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

trialCalls = topsCallList('call functions');
%trialCalls.addCall({@read, ui}, 'read input');
list{'control'}{'trial calls'} = trialCalls;

% "instructions" is a branch of the tree with an instructional slide show

%instructions = topsTreeNode('instructions');
%instructions.iterations = 1;
%tree.addChild(instructions);

%viewSlides = topsConcurrentComposite('slide show');
%viewSlides.startFevalable = {@flushData, ui};
%viewSlides.finishFevalable = {@flushData, ui};
%instructions.addChild(viewSlides);

%instructionStates = topsStateMachine('instruction states');
%viewSlides.addChild(instructionStates);

%instructionCalls = topsCallList('instruction updates');
%instructionCalls.alwaysRunning = true;
%viewSlides.addChild(instructionCalls);

list{'outline'}{'tree'} = tree;
%% Control:
% Create three types of control objects:
%	- topsTreeNode organizes flow outside of trials
%	- topsConditions organizes parameter combinations before each trial
%	- topsStateMachine organizes flow within trials
%	- topsCallList organizes calls some functions during trials
%	- topsConcurrentComposite interleaves behaviors of the state machine,
%	function calls, and drawing graphics
%   .

%% Organize the presentation of instructions
% the instructions state machine will respond to user input commands
%states = { ...
%    'name'      'entry'         'timeout'	'exit'          'next'      'input'; ...
%    'quest_initialize' {@quest_initialize}              0           {}    'start1'  {};...
%    'start1'    {@test1}              0           {}    'next1'  {};...
%    'next1'    {@test2}              0           {}    'end1'  {};...
%    'end1'    {}              0           {}    ''  {};...
%    };
%instructionStates.addMultipleStates(states);
%instructionStates.startFevalable = {@doMessage, list, ''};
%instructionStates.finishFevalable = {@doMessage, list, ''};
%instructionStates.startFevalable = {@configStartTrial, list};
%instructionStates.finishFevalable = {@configFinishTrial, list};
% 
% % the instructions call list runs in parallel with the state machine
% instructionCalls.addCall({@read, ui}, 'input');

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
%    'inst'      {@doNextInstruction, av} 1        {}              ''; ...
    'prepare2'   {}          0       {}  'prepare1' {}; ...
    'prepare1'   {on fpInd}          0       {on, [counterInd, scoreInd]}  'pause'     {}; ...
    'pause'     {chf fpInd}   0     {}                  'pause2'   {};...
    'pause2'    {cho fpInd}   0      {}    'prepare2'  {};...
    'prepare2'   {on qpInd}      0       {}      'pause3' {}; ...
    'pause3'     {on, [counterInd, scoreInd]}              0       {}      'change-time' {@pause_trial list trialStates}
    'change-time'      {@editState, trialStates, list, logic}   0    {}    'stimulus3'     {}; ...
    'stimulus3'  {}   0       {} 'stimulus1' {@turn_on_stim list trialStates}; ...
    'stimulus1'  {@record_stim list trialStates}   1       {} 'stimulus1' {}; ...
    'stimulus0'  {}   0    {@setTimeStamp, logic}             'decision'     {}; ...
    'decision'  {}   0  {}  'moved'  {@getNextEvent_Clean logic.decisiontime_max trialStates list}; ...
    'moved'    {}         0     {@showFeedback, list} 'choice' {}; ...
    'choice'    {}	tFeed     {}              'complete' {}; ...
    'complete'  {}  0   {}       'counter'          {}; ...
    'counter'  {on, [counterInd, scoreInd]}  0   {}              'set'          {}; ... % always a good trial for now
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

function [name,data] = pause_trial(list, trialStates)

flag = 1;

 while flag 
     key_entered = mglGetKeyEvent(inf);
     if (strcmp(key_entered.charCode,' '))
         flag=0;
     end
 end
name = NaN;
data = NaN;


function [name, data] = record_stim(list, trialStates)
logic = list{'object'}{'logic'};
stimInd = list{'graphics'}{'stimulus index'};
drawables = list{'graphics'}{'drawables'};
stim = drawables.getObject(stimInd);
if (stim.isVisible == false)
    trialStates.editStateByName('stimulus1', 'next', 'stimulus0');
end

%while(stim.tind < 30)
%    disp(stim.tind);
%    stim = drawables.getObject(stimInd);
%end
%setup
function [name, data] = turn_on_stim(list, trialStates)
logic = list{'object'}{'logic'};
stimInd = list{'graphics'}{'stimulus index'};
drawables = list{'graphics'}{'drawables'};

drawables.setObjectProperty('isVisible', true, [stimInd]);
%undo
trialStates.editStateByName('stimulus1', 'next', 'stimulus1');

%drawables.automateObjectMethod('draw', @mayDrawNow);

name = NaN;
data = NaN;


function [name,data] = getNextEvent_Clean(dt, trialStates, list)
flag = 1;
logic = list{'object'}{'logic'};
%start = clock;
%timeout = logic.decisiontime_max;
logic.choice = NaN;

 while flag %&& (etime(clock, start) < timeout)
     key_entered = mglGetKeyEvent(dt);
     if (isempty(key_entered))
         logic.choice=0;
         flag=0;
     elseif (strcmp(key_entered.charCode,'f'))
         logic.choice = -1; % right
         flag = 0;
         %Place data recording here
     elseif (strcmp(key_entered.charCode,'j'))
         logic.choice = +1; % left
         flag = 0;
         %place data recording here
     end
 end
%logic.choice = +1;



%Justin TODO: Need to figure out what dependency necessitates these
%existing
name = NaN;
data = NaN;
list{'object'}{'logic'} = logic;
%Justin#4: Thought this was actually doing something. Turns out it has no
%effect on timeout, function return does
%trialStates.editStateByName('decision','timeout',0);
%setup
function configStartTrial(list)
% start Logic trial
logic = list{'object'}{'logic'};
logic.startTrial;

% clear data from the last trial
%ui = list{'input'}{'controller'};
%ui.flushData();
list{'control'}{'current choice'} = 'none';

% reset the appearance of targets and cursor
%   use the drawables ensemble, to allow remote behavior
drawables = list{'graphics'}{'drawables'};
targsInd = list{'graphics'}{'targets index'};
stimInd = list{'graphics'}{'stimulus index'};
coh_high = list{'graphics'}{'coh_high'};
coh_low = list{'graphics'}{'coh_low'};
length_of_drop = list{'graphics'}{'length_of_drop'};
length_of_high = list{'graphics'}{'length_of_high'};
H3 = list{'graphics'}{'H3'};
minT = logic.minT;
maxT = logic.maxT; 
cp_maxT = list{'graphics'}{'cp_maxT'};
cp_minT = list{'graphics'}{'cp_minT'};
cp_H3 = list{'graphics'}{'cp_H3'};
trial_count = list{'TAC'}{'counter'};
array_of_TAC = list{'TAC'}{'TAC_Array'};
drawables.setObjectProperty( ...
    'colors', list{'graphics'}{'gray'}, [targsInd]);
high_tind_end = 0;


%define the duration for this trial
duration = min(minT + exprnd(H3),maxT);
while (duration == maxT)
    duration = min(minT + exprnd(H3),maxT);
end

duration = duration + length_of_drop + length_of_high;
logic.duration = duration;

%uncomment to bring back uniform trial counter
%TAC = array_of_TAC(trial_count);
list{'TAC'}{'counter'} = trial_count + 1;

%25 chance of having a high coherence trial
is_high_trial_G = 0;
if (rand < .25)
    is_high_trial_G = 1;
end

TAC_on = list{'graphics'}{'TAC_on'};
if TAC_on
    %50 chance of no mandatory changepoint
    if (rand < .5)
        TAC = min(cp_minT + exprnd(cp_H3),cp_maxT);
        while (TAC == cp_maxT)
            TAC = min(cp_minT + exprnd(cp_H3),cp_maxT);
        end
    else
        TAC = 0;
    end
else
    %remove set Trial change points
    TAC = 0;

%computed in prepareDotsDrawable
%logic.direction0 = round(rand)*180;

% let all the graphics set up to draw in the open window
drawables.setObjectProperty('isVisible', false);

drawables.setObjectProperty( ...
    'length_of_drop', length_of_drop, [stimInd]);

drawables.setObjectProperty( ...
    'length_of_high', length_of_high, [stimInd]);

drawables.setObjectProperty( ...
    'high_tind_end', high_tind_end, [stimInd]);

drawables.setObjectProperty( ...
    'duration', duration, [stimInd]);

drawables.setObjectProperty( ...
    'coherence', logic.coherence, [stimInd]);

% drawables.setObjectProperty( ...
%     'direction', logic.direction0, [stimInd]);

drawables.setObjectProperty( ...
    'H', logic.H, [stimInd]);

drawables.setObjectProperty( ...
    'randSeed', NaN, [stimInd]);

drawables.setObjectProperty( ...
    'time_flag', 0, [stimInd]);

drawables.setObjectProperty( ...
    'tind', 0, [stimInd]);

drawables.setObjectProperty( ...
    'coh_high', coh_high, [stimInd]);

drawables.setObjectProperty( ...
    'coh_low', coh_low, [stimInd]);

drawables.setObjectProperty( ...
    'TAC', TAC, [stimInd]);
drawables.setObjectProperty( ...
    'is_high_trial_G', is_high_trial_G, [stimInd]);
          
drawables.callObjectMethod(@prepareToDrawInWindow);

%windowFrameRate = drawables.getObjectProperty('windowFrameRate',[stimInd]);


function configFinishTrial(list)
% finish logic trial
logic = list{'object'}{'logic'};
logic.finishTrial;

% print out the block and trial #
disp(sprintf('block %d/%d, trial %d/%d',...
    logic.currentBlock, logic.nBlocks,...
    logic.blockTotalTrials, logic.trialsPerBlock));

%%% DATA RECORDING -- this takes up a lot of time %%%

tt = logic.blockTotalTrials;
bb = logic.currentBlock;
statusData = list{'logic'}{'statusData'};
statusData(tt,bb) = logic.getStatus();
list{'logic'}{'statusData'} = statusData;

[dataPath, dataName, dataExt] = fileparts(logic.dataFileName);
if isempty(dataPath)
    dataPath = dotsTheMachineConfiguration.getDefaultValue('dataPath');
end
dataFullFile = fullfile(dataPath, dataName);
save(dataFullFile, 'statusData')

% write new tops flow-of-control data to disk
%topsDataLog.writeDataFile();


%%% END %%%


% only need to wait our the intertrial interval
pause(list{'timing'}{'intertrial'});


%At the end of every decision in the tree, this function records the
%direction and coherence at every time point (directionvc, coherencevc),
%records if correct choice was made, and sets color of dot for feedback

%tldr: add or adjust post decision options here

function showFeedback(list)
logic = list{'object'}{'logic'};
% hide the fixation point and cursor
drawables = list{'graphics'}{'drawables'};
fpInd = list{'graphics'}{'fixation point index'};
targsInd = list{'graphics'}{'targets index'};
stimInd = list{'graphics'}{'stimulus index'};
counterInd = list{'graphics'}{'counter index'};
scoreInd = list{'graphics'}{'score index'};
logic.setDetection();
drawables.setObjectProperty('isVisible', false, [fpInd]);
drawables.setObjectProperty('isVisible', true, [targsInd]);

if logic.choice == -1 %left choice
    list{'control'}{'current choice'} = 'leftward';
elseif logic.choice == 1 %right choice
    list{'control'}{'current choice'} = 'rightward';
end
 
stim = drawables.getObject(stimInd);

logic.directionvc = stim.directionvc(1:stim.tind);
logic.coherencevc = stim.coherencevc(1:stim.tind);

stimstrct = obj2struct(stim);

logic.stimstrct = stimstrct;

%Record accuracy of choice and change color of dot accordingly
if logic.choice == -1 && stim.direction == 180
    drawables.setObjectProperty( ...
        'colors', list{'graphics'}{'green'}, targsInd);
     logic.correct = 1;
elseif logic.choice == 1 && stim.direction == 0
     drawables.setObjectProperty( ...
         'colors', list{'graphics'}{'green'}, targsInd);
     logic.correct = 1;
elseif logic.choice == 0 %timeout
     drawables.setObjectProperty( ...
         'colors', list{'graphics'}{'yellow'}, targsInd);
     logic.correct = 0;
else %wrong choice
     drawables.setObjectProperty( ...
         'colors', list{'graphics'}{'red'}, targsInd);
 logic.correct = 0;
end

%Computes and records logic.ReactionTimeData and logic.PercentCorrData
logic.computeBehaviorParameters();

%JUSTIN TODO: Score is calculated below. When should it be utilized?
%if logic.correct == 1
%     logic.score = logic.score + 0.1;
%elseif logic.correct == 0
%     logic.score = logic.score - 0.1;
%     if logic.score < 0
%         logic.score = 0;
%     end
% end
%     
drawables = list{'graphics'}{'drawables'};
%TODO we set to +2 because logic doesn't update block total trial in time
%for it to be displayed accurately for the next trial (would be behind a
%trial count by 1)
drawables.setObjectProperty('string', strcat(num2str(logic.blockTotalTrials + 2), '/',...
num2str(logic.trialsPerBlock)), counterInd);
%drawables.setObjectProperty('string', strcat('$', num2str(logic.score)), scoreInd);



function editState(trialStates, list, logic)
logic = list{'object'}{'logic'};
%trialStates.editStateByName('stimulus1', 'timeout', logic.duration * 2);
%undo for trial comparisons 2017/8/9
trialStates.editStateByName('stimulus1', 'timeout', 0);

%set coherence to level specified by quest, will remove once quest trials
%are finished in the next funciton
