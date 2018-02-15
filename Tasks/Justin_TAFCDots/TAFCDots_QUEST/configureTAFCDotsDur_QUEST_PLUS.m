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
%% Quest initialization
%JustinTODO: may want to set conditional if quest is used or not
%undo quest initialization
%TODO: May want to reimplement modularization below
% quest_values = load('scriptRunValues/quest_values.mat');
% tGuess = quest_values.tGuess; 
% tGuessSd = quest_values.tGuessSd; 
% pThreshold= quest_values.pThreshold;
% beta=quest_values.beta;delta=quest_values.delta;gamma=quest_values.gamma;
% grain=quest_values.grain;
% range=quest_values.range;

questData = qpParams('stimParamsDomainList',{[0:1:100]}, ...
    'psiParamsDomainList',{0:1:100, 1:.5:5, 0.5, 0:0.01:0.04});

% Then initialize using the parameters that have been set up.
questData = qpInitialize(questData);

%plotIt=quest_values.plotIt;
%q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range);
%q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.

%coh = QuestQuantile(q);
coh = qpQuery(questData);
logic.coherence = coh;
%TODO Remove
%list{'quest'}{'number_of_trials'} = quest_values.questTrials;
%list{'quest'}{'object'} =  q;
list{'quest'}{'object'} = questData;
list{'quest'}{'counter'} = 0;




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
    %'pause'     {chf fpInd} 0       {@run instructions}                  'pause2'   {};...
    'pause'     {chf fpInd} 0       {}                  'pause2'   {};...
    'pause2'    {cho fpInd}              0           {}    'prepare2'  {};...
    'prepare2'   {on qpInd}      0       {}      'change-time' {}; ...
    'change-time'      {@editState, trialStates, list, logic}   0    {}    'stimulus3'     {}; ...
    %'stimulus1'  {on stimInd}   0       {} 'stimulus0' {}; ...
    %undo for trial comparisons 2017/8/9
    'stimulus3'  {}   0       {} 'stimulus1' {@turn_on_stim list trialStates}; ...
    %'stimulus3'  {on stimInd}   0       {} 'stimulus1' {}; ...
    %undo for trial comparisons 2017/8/9
    'stimulus1'  {@record_stim list trialStates}   1       {} 'stimulus1' {}; ...
    %'stimulus1'  {}   1       {off stimInd} 'stimulus0' {}; ...
%    'stimulus2'  {@changeDirection, list} 0     {}	'change-time' {}; ...
    'stimulus0'  {}   0    {@setTimeStamp, logic}             'decision'     {}; ...
   % 'stimulus0'  {}   0    {@setTimeStamp, logic}             'decision'     {}; ... 
    %'decision'  {off stimInd}   0  {}  'moved'  {@getNextEvent_Clean logic.decisiontime_max trialStates list}; ...
    'decision'  {}   0  {}  'moved'  {@getNextEvent_Clean logic.decisiontime_max trialStates list}; ...
    'moved'    {}         0     {@showFeedback, list} 'choice' {}; ...
    'choice'    {}	tFeed     {}              'complete' {}; ...
    %'complete'  {@quest_set list trialStates}  0   {}       'counter'          {}; ... % always a good trial for now
    'complete'  {}  0   {}       'counter'          {}; ...
    %undo quest above
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
drawables.setObjectProperty( ...
    'colors', list{'graphics'}{'gray'}, [targsInd]);

% randval = rand;
% randval = 0;

logic.direction0 = round(rand)*180;

% let all the graphics set up to draw in the open window
drawables.setObjectProperty('isVisible', false);
                
%drawables.setObjectProperty( ...
%    'tind', 0, [stimInd]);

drawables.setObjectProperty( ...
    'coherence', logic.coherence, [stimInd]);

drawables.setObjectProperty( ...
    'direction', logic.direction0, [stimInd]);

drawables.setObjectProperty( ...
    'H', logic.H, [stimInd]);

drawables.setObjectProperty( ...
    'randSeed', NaN, [stimInd]);

drawables.setObjectProperty( ...
    'time_flag', 0, [stimInd]);

drawables.setObjectProperty( ...
    'tind', 0, [stimInd]);

drawables.setObjectProperty( ...
    'duration', logic.duration, [stimInd]);
%drawables.setObjectProperty(...
%    'time_max',0,[stimInd]);
                
drawables.callObjectMethod(@prepareToDrawInWindow);


function configFinishTrial(list)
% finish logic trial
logic = list{'object'}{'logic'};
logic.finishTrial;


quest_count = list{'quest'}{'counter'};
quest_count = quest_count + 1;
list{'quest'}{'counter'} = quest_count;
if (quest_count == 50)
    questData = list{'quest'}{'object'};
    %Find out QUEST+'s estimate of the stimulus parameters, obtained
    % on the gridded parameter domain.
    psiParamsIndex = qpListMaxArg(questData.posterior);
    psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
    fprintf('Max posterior QUEST+ parameters: %0.1f, %0.1f, %0.1f, %0.2f\n', ...
        psiParamsQuest(1),psiParamsQuest(2),psiParamsQuest(3),psiParamsQuest(4));

    % Find aximum likelihood fit.  Use psiParams from QUEST+ as the starting
    % parameter for the search, and impose as parameter bounds the range
    % provided to QUEST+.
    psiParamsFit = qpFit(questData.trialData,questData.qpPF,psiParamsQuest,questData.nOutcomes,...
        'lowerBounds', [0 1 0.5 0],'upperBounds',[100 5 0.5 0.04]);
    fprintf('Maximum likelihood fit parameters: %0.1f, %0.1f, %0.1f, %0.2f\n', ...
        psiParamsFit(1),psiParamsFit(2),psiParamsFit(3),psiParamsFit(4));

    % Little unit test that this routine still does what it used to.
    %psiParamsCheck = [-197856 20000 5000 0];
    %assert(all(psiParamsCheck == round(10000*psiParamsFit)),'No longer get same ML estimate for this case');

    % Plot of trial locations with maximum likelihood fit
    figure; clf; hold on
    stimCounts = qpCounts(qpData(questData.trialData),questData.nOutcomes);
    stim = [stimCounts.stim];
    stimFine = linspace(0,100,100)';
    plotProportionsFit = qpPFWeibull(stimFine,psiParamsFit);
    for cc = 1:length(stimCounts)
        nTrials(cc) = sum(stimCounts(cc).outcomeCounts);
        pCorrect(cc) = stimCounts(cc).outcomeCounts(2)/nTrials(cc);
    end
    for cc = 1:length(stimCounts)
        h = scatter(stim(cc),pCorrect(cc),100,'o','MarkerEdgeColor',[0 0 1],'MarkerFaceColor',[0 0 1],...
            'MarkerFaceAlpha',nTrials(cc)/max(nTrials),'MarkerEdgeAlpha',nTrials(cc)/max(nTrials));
    end
    plot(stimFine,plotProportionsFit(:,2),'-','Color',[1.0 0.2 0.0],'LineWidth',3);
    xlabel('Stimulus Value');
    ylabel('Proportion Correct');
    xlim([00 100]); ylim([0 1]);
    title({'Estimate Weibull threshold, slope, and lapse', ''});
    drawnow;
    %save value here to disect out 65% later!
end

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
disp('works?');
disp(logic.choice);

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
%to make all wrong
% drawables.setObjectProperty( ...
%          'colors', list{'graphics'}{'red'}, targsInd);
% logic.correct=0;
%to make all right
% drawables.setObjectProperty( ...
%          'colors', list{'graphics'}{'green'}, targsInd);
% logic.correct=1;

%for QUEST
questData = list{'quest'}{'object'};
coh = logic.coherence;

%q=QuestUpdate(q,logic.coherence,logic.correct);

if (logic.correct == 0)
    outcome = 1;
elseif (logic.correct== 1)
    outcome = 2;
end

questData = qpUpdate(questData,coh,outcome);
%coh = max(QuestQuantile(q),3);
%coh = QuestMode(q);
coh = qpQuery(questData);
disp(coh);
if coh>100
    coh=100;
end
logic.coherence = coh;
%list{'quest'}{'object'} = q;
list{'quest'}{'object'} = questData;
list{'object'}{'logic'} = logic;


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
% drawables = list{'graphics'}{'drawables'};
% drawables.setObjectProperty('string', strcat(num2str(logic.blockTotalTrials + 1), '/',...
% num2str(logic.trialsPerBlock)), counterInd);
% drawables.setObjectProperty('string', strcat('$', num2str(logic.score)), scoreInd);



function editState(trialStates, list, logic)
logic = list{'object'}{'logic'};
%trialStates.editStateByName('stimulus1', 'timeout', logic.duration * 2);
%undo for trial comparisons 2017/8/9
trialStates.editStateByName('stimulus1', 'timeout', 0);

%set coherence to level specified by quest, will remove once quest trials
%are finished in the next funciton
function quest_set(list, trialStates)

q = list{'quest'}{'object'};
logic = list{'object'}{'logic'};

%Kira code to stop Quest
logic.oldcoherence=[logic.oldcoherence, logic.coherence];
avgCoh = mean(logic.oldcoherence);
if logic.coherence<=.5+avgCoh && logic.coherence>=avgCoh-.5
    logic.timessame=logic.timessame+1;
    logic.perrcorr=mean(logic.PercentCorrData);
else
    logic.timessame=0; 
    logic.perrcorrList=[];
    logic.oldcoherence=[];
end


q=QuestUpdate(q,logic.coherence,logic.correct);
coh = max(QuestQuantile(q),3);
if coh>100
    coh=100;
end
logic.coherence = coh;
list{'quest'}{'object'} = q;
list{'object'}{'logic'} = logic;

if logic.timessame>=20 && logic.perrcorr<.70 && logic.perrcorr>.60
    tree=list{'outline'}{'tree'};
    session= list{'outline'}{'session'}; 
    block= list{'outline'}{'block'};
    block.finish;
    session.finsih;
    tree.finish;
end





%logic sets coherence when state machine begins each trial, thus only
%change logic.coherence at the end of the trial to show an effect here
