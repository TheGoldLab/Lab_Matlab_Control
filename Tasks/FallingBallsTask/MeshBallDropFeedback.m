function MeshBallDropFeedback
clc;
clear all

sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 1);
sc.open;

rng('shuffle')
list = topsGroupedList('falling balls data');
% +++ Add some constants that define task behavior
% +++
%This is the mean of the RedBall used for the normal distribution
list{'Stimulus'}{'RedMean'} = normrnd(0, 1);
list{'Stimulus'}{'RedMeanlist'} = 0;
list{'Stimulus'}{'GreenMeanlist'} = 0;
list{'Stimulus'}{'sigma0'} = 1;
list{'Stimulus'}{'hazard'} = 0.5;
list{'Stimulus'}{'SigmaRatio'} = 0.5;

list{'learning'}{'PreviousBucketPosition'} = 0;
list{'learning'}{'alpha'} = 0;
list{'learning'}{'scoreAggregate'} = [];



global counter
counter = 0;

%% *************************
%
% GRAPHICS
%

% +++ Create and configure Drawable objects, adding
% +++   to an ensemble as we go
% +++
drawables = topsEnsemble('drawings');

ScreenSize = mglGetParam('deviceRect');
Left = ScreenSize(1);
Bottom = ScreenSize(2);
Right = ScreenSize(3);
Top = ScreenSize(4);

Mesh = 40;
ColumnUnit = (Right + abs(Left)) / Mesh;
RowUnit = (Top + abs(Bottom)) / Mesh;

list{'Position'}{'Top'} = Mesh;
list{'Position'}{'TopHalf'} = round(Mesh*0.75);
list{'Position'}{'Center'} = round(Mesh*0.50);
list{'Position'}{'BottomHalf'} = round(Mesh*0.25);
list{'Position'}{'Bottom'} = 1;

list{'Position'}{'Right'} = Mesh;
list{'Position'}{'RightHalf'} = round(Mesh*0.75);
list{'Position'}{'Center'} = round(Mesh*0.50);
list{'Position'}{'LeftHalf'} = round(Mesh*0.25);
list{'Position'}{'Left'} = 1;

% list{'Position'}{'Ground'} = ColumnUnit*10;
% list{'Position'}{'Ceiling'}= -RowUnit*10;
% list{'Position'}{'FrameWidth'} = ColumnUnit*10

%Grid is Mesh-1 x Mesh-1 

% +++ dotsDrawableLines objects: the ceiling and ground
% +++
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ceiling = dotsDrawableLines();
ceiling.xFrom     = -ColumnUnit*10;
ceiling.xTo       =  ColumnUnit*10;
ceiling.yFrom     = RowUnit*6;
ceiling.yTo       = RowUnit*6;
ceiling.pixelSize = 10;
ceiling.colors    = [0.6 0.6 0.6];
drawables.addObject(ceiling);

ground = dotsDrawableLines();
ground.xFrom     = -ColumnUnit*10;
ground.xTo       =  ColumnUnit*10;
ground.yFrom     = -RowUnit*5.5;
ground.yTo       = -RowUnit*5.5;
ground.pixelSize = 10;
ground.colors    = [0.6 0.6 0.6];
drawables.addObject(ground);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
target_g         = dotsDrawableImages();
target_g.fileNames = {'super_tube.png'};
target_g.width   = 1;
target_g.height  = 1;
target_g.x = 0; 
target_g.y = -3.3;

target_animated = dotsDrawableAnimator();
target_animated.addDrawable(target_g);
drawables.addObject(target_animated);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arrow = dotsDrawableImages();
arrow.fileNames = {'Lakitu.png'};
arrow.x = list{'Stimulus'}{'RedMean'};
arrow.y = RowUnit*7;
arrow.height = 2;
arrow.width  = 2;

arrow_animated = dotsDrawableAnimator();
arrow_animated.addDrawable(arrow);
drawables.addObject(arrow_animated);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gauss = dotsDrawableVertices();
drawables.addObject(gauss);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fall_ball_samp = dotsDrawableTargets();
fall_ball_samp.width   = 0.4;
fall_ball_samp.height  = 0.4;
fall_ball_samp.xCenter = 0;
fall_ball_samp.yCenter = 2.7;
fall_ball_samp.colors  = [0.25 0.75 0.1];

ballAnimator_samp = dotsDrawableAnimator();
ballAnimator_samp.addDrawable(fall_ball_samp);
drawables.addObject(ballAnimator_samp);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lines = dotsDrawableLines();
lines.xFrom = [linspace(Left,Right,Mesh) linspace(Left,Left,Mesh)];
lines.xTo = [linspace(Left,Right,Mesh) linspace(Right,Right,Mesh)];
lines.yFrom = [linspace(Bottom,Bottom,Mesh) linspace(Bottom,Top,Mesh)];
lines.yTo = [linspace(Top,Top,Mesh) linspace(Bottom,Top,Mesh)];
drawables.addObject(lines)

Column = lines.xTo(1:Mesh);
Row = lines.yTo((Mesh+1):end);

SigmaColumn = list{'Position'}{'RightHalf'};
SigmaHeight = 2;
SigmaEndX = SigmaColumn+SigmaHeight;
SigmaRow = list{'Position'}{'TopHalf'};
SigmaWidth = 2;
SigmaEndY = SigmaRow+SigmaWidth;
SigmaX = [Column(SigmaColumn) Column(SigmaColumn) Column(SigmaEndX) Column(SigmaEndX)];
SigmaY = [Row(SigmaRow) Row(SigmaEndY) Row(SigmaRow) Row(SigmaEndY)];

SigmaButton = dotsDrawableVertices;
SigmaButton.x = SigmaX;
SigmaButton.y = SigmaY;
SigmaButton.colors = [1 0 0];
SigmaButton.primitive = 7;
drawables.addObject(SigmaButton);

HazardColumn = list{'Position'}{'RightHalf'}-5;
HazardHeight = 2;
HazardEndX = HazardColumn+HazardHeight;
HazardRow = list{'Position'}{'TopHalf'};
HazardWidth = 2;
HazardEndY = HazardRow+HazardWidth;
HazardX = [Column(HazardColumn) Column(HazardColumn) Column(HazardEndX) Column(HazardEndX)];
HazardY = [Row(HazardRow) Row(HazardEndY) Row(HazardRow) Row(HazardEndY)];

HazardButton = dotsDrawableVertices;
HazardButton.x = HazardX;
HazardButton.y = HazardY;
HazardButton.colors = [1 0 0];
HazardButton.primitive = 7;
drawables.addObject(HazardButton);

RatioColumn = list{'Position'}{'RightHalf'}-10;
RatioHeight = 2;
RatioEndX = RatioColumn+RatioHeight;
RatioRow = list{'Position'}{'TopHalf'};
RatioWidth = 2;
RatioEndY = RatioRow+RatioWidth;
RatioX = [Column(RatioColumn) Column(RatioColumn) Column(RatioEndX) Column(RatioEndX)];
RatioY = [Row(RatioRow) Row(RatioEndY) Row(RatioRow) Row(RatioEndY)];

RatioButton = dotsDrawableVertices;
RatioButton.x = RatioX;
RatioButton.y = RatioY;
RatioButton.colors = [1 0 0];
RatioButton.primitive = 7;
drawables.addObject(RatioButton);

PauseColumn = list{'Position'}{'RightHalf'}-15;
PauseHeight = 2;
PauseEndX = PauseColumn+PauseHeight;
PauseRow = list{'Position'}{'TopHalf'};
PauseWidth = 2;
PauseEndY = PauseRow+PauseWidth;
PauseX = [Column(PauseColumn) Column(PauseColumn) Column(PauseEndX) Column(PauseEndX)];
PauseY = [Row(PauseRow) Row(PauseEndY) Row(PauseRow) Row(PauseEndY)];

PauseButton = dotsDrawableVertices;
PauseButton.x = PauseX;
PauseButton.y = PauseY;
PauseButton.colors = [1 0 0];
PauseButton.primitive = 7;
drawables.addObject(PauseButton);

FinishColumn = list{'Position'}{'RightHalf'}-20;
FinishHeight = 2;
FinishEndX = FinishColumn+FinishHeight;
FinishRow = list{'Position'}{'TopHalf'};
FinishWidth = 2;
FinishEndY = FinishRow+FinishWidth;
FinishX = [Column(FinishColumn) Column(FinishColumn) Column(FinishEndX) Column(FinishEndX)];
FinishY = [Row(FinishRow) Row(FinishEndY) Row(FinishRow) Row(FinishEndY)];

FinishButton = dotsDrawableVertices;
FinishButton.x = FinishX;
FinishButton.y = FinishY;
FinishButton.colors = [.75 .5 .2];
FinishButton.primitive = 7;
drawables.addObject(FinishButton);

stext = dotsDrawableText();
stext.string = strcat('sigma 0 value:', num2str(list{'Stimulus'}{'sigma0'}));
stext.fontSize = 20;
stext.x = SigmaButton.x(1);
stext.y = SigmaButton.y(4)+RowUnit;
drawables.addObject(stext);

htext = dotsDrawableText();
htext.string = strcat('hazard rate:', num2str(list{'Stimulus'}{'hazard'}));
htext.fontSize = 20;
htext.x = HazardButton.x(1);
htext.y = HazardButton.y(4)+RowUnit;
drawables.addObject(htext);

rtext = dotsDrawableText();
rtext.string = strcat('Sigma Ratio:', num2str(list{'Stimulus'}{'SigmaRatio'})); 
rtext.fontSize = 20;
rtext.x = RatioButton.x(1);
rtext.y = RatioButton.y(4)+RowUnit;
drawables.addObject(rtext);

ptext = dotsDrawableText();
ptext.string = 'Pause';
ptext.fontSize = 20;
ptext.x = PauseButton.x(1);
ptext.y = PauseButton.y(4)+RowUnit;
drawables.addObject(ptext);

ftext = dotsDrawableText();
ftext.string = 'Exit';
ftext.fontSize = 20;
ftext.x = FinishButton.x(1);
ftext.y = FinishButton.y(4)+RowUnit;
drawables.addObject(ftext);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



LearningMinusColumn = 19;
LearningMinusHeight = 1;
LearningMinusEndX = LearningMinusColumn+LearningMinusHeight;
LearningMinusRow = 5;
LearningMinusWidth = 1;
LearningMinusEndY = LearningMinusRow+LearningMinusWidth;
LearningMinusX = [Column(LearningMinusColumn) Column(LearningMinusColumn) Column(LearningMinusEndX) Column(LearningMinusEndX)];
LearningMinusY = [Row(LearningMinusRow) Row(LearningMinusEndY) Row(LearningMinusRow) Row(LearningMinusEndY)];

LearningMinus = dotsDrawableVertices;
LearningMinus.x = LearningMinusX;
LearningMinus.y = LearningMinusY;
LearningMinus.colors = [1 1 1];
LearningMinus.primitive = 7;
drawables.addObject(LearningMinus);

LearningPlusColumn = 29;
LearningPlusHeight = 1;
LearningPlusEndX = LearningPlusColumn+LearningPlusHeight;
LearningPlusRow = 5;
LearningPlusWidth = 1;
LearningPlusEndY = LearningPlusRow+LearningPlusWidth;
LearningPlusX = [Column(LearningPlusColumn) Column(LearningPlusColumn) Column(LearningPlusEndX) Column(LearningPlusEndX)];
LearningPlusY = [Row(LearningPlusRow) Row(LearningPlusEndY) Row(LearningPlusRow) Row(LearningPlusEndY)];

LearningPlus = dotsDrawableVertices;
LearningPlus.x = LearningPlusX;
LearningPlus.y = LearningPlusY;
LearningPlus.colors = [1 1 1];
LearningPlus.primitive = 7;
drawables.addObject(LearningPlus);

LearningLine = dotsDrawableLines;
LearningLine.xFrom = LearningMinus.x(1);
LearningLine.xTo = LearningPlus.x(1);
LearningLine.yFrom = LearningMinus.y(1);
LearningLine.yTo = LearningMinus.y(1);
LearningLine.pixelSize = 3;
drawables.addObject(LearningLine)

LearningBox = dotsDrawableTargets;
LearningBox.xCenter = LearningMinus.x(1);
LearningBox.yCenter = LearningMinus.y(1);
LearningBox.width = .5;
LearningBox.height = .5;
LearningBox.colors = [0 0 1];
LearningBox.nSides = 10;
LearningBox.isSmooth = true;
drawables.addObject(LearningBox);

learning = dotsDrawableText();
learning.fontSize = 30;
learning.x = LearningPlus.x(1);
learning.y = LearningPlus.y(1)+2;
drawables.addObject(learning);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FeedbackLine = dotsDrawableLines();
FeedbackLine.yTo = -2;
FeedbackLine.yFrom = -2;
FeedbackLine.xTo = 0;
FeedbackLine.xFrom = 0;
FeedbackLine.pixelSize = 10;
FeedbackLine.colors = [.80 .10 .20];
drawables.addObject(FeedbackLine);

ScoreCard = dotsDrawableText();
ScoreCard.x = 5;
drawables.addObject(ScoreCard);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MouseDot = dotsDrawableVertices();
MouseDot.pixelSize = 10;
MouseDot.isSmooth = true;
drawables.addObject(MouseDot);

compMouse = dotsReadableHIDMouse();
compMouse.isExclusive = false;
xAxis = compMouse.components(1);
compMouse.setComponentCalibration(xAxis.ID, [], [], [-5 5]);    
yAxis = compMouse.components(2);
compMouse.setComponentCalibration(yAxis.ID, [], [], [5 -5]);
click = compMouse.components(3);
click2 = compMouse.components(4);
compMouse.defineEvent(click.ID,'bigger',1,1,false)
compMouse.defineEvent(click2.ID,'smaller',1,1,false)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The static drawFrame() takes a cell array of objects
drawables.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

% +++ Save the drawables and useful groups of indices in the list
% +++
list{'graphics'}{'drawables'}          = drawables;

%% *************************
%
% CONTROL
%

% +++ topsTreeNode organizes flow outside of trials
% +++
%   This is the trunk of the tree, branches are added below
tree = topsTreeNode('falling balls task');
tree.iterations      = 1;
tree.startFevalable  = {@startTree};
tree.finishFevalable = {@finishTree, sc};
    


% askInput = {@getStateInput};

% +++ fixedMachine does the simple stuff on each trial
fixedMachine = topsStateMachine('fixed states');
trialCalls = topsCallList('call functions');
trialCalls.addCall({@update, list, ColumnUnit, compMouse, MouseDot, SigmaButton, stext, HazardButton, htext, RatioButton, rtext,...
    PauseButton, FinishButton,fixedMachine, LearningPlus, LearningMinus, LearningBox}, 'update');
 
 fixedStates = { ...
    'name'      'entry'    'next' 'timeout' 'exit'  'input'; ...
    'position'  {@startTrial, SigmaButton, HazardButton, RatioButton, LearningPlus, LearningMinus, FeedbackLine}           'set'     1         {}  {}; ...
    'set'       {@Set_cue, list, gauss,ColumnUnit} 'animate'       0        {}                  {};...   
    'animate'   {@startAnimation, list, arrow_animated, target_animated, learning, ballAnimator_samp}      'error'       2      {} {}; ... 
    'error'     {@errorbar, list, FeedbackLine, ScoreCard} '' 1 {} {}; ...
     };
fixedMachine.addMultipleStates(fixedStates);
% fixedMachine.startFevalable  = {@startTrial,  list, arrow};
% fixedMachine.finishFevalable = {@finishTrial};


fixedConcurrents = topsConcurrentComposite('run() concurrently:');
fixedConcurrents.addChild(fixedMachine);
fixedConcurrents.addChild(drawables);
fixedConcurrents.addChild(trialCalls);


Trials = tree.newChildNode('Trials');
Trials.iterations = 5;
Trials.addChild(fixedConcurrents);


%% *************************
%
% RUN IT!
%
tree.run;
tree.gui();

% ++++++++
% FUNCTION: startTree
%
function startTree()

% ++++++++
% FUNCTION: startTrial
%
function startTrial(SigmaButton, HazardButton, RatioButton, LearningPlus, LearningMinus, FeedbackLine) 
global counter
counter = counter + 1;

SigmaButton.colors = [1 0 0];
HazardButton.colors = [0 1 0];
RatioButton.colors = [0 0 1];
LearningPlus.colors = [1 1 1];
LearningMinus.colors = [1 1 1];

FeedbackLine.xTo = 0;
FeedbackLine.xFrom = 0;

% ++++++++
% FUNCTION: Set_cue
%    
function Set_cue(list, gauss, ColumnUnit)

hazard = list{'Stimulus'}{'hazard'};
RedMean_position = list{'Stimulus'}{'RedMean'};
sigma0 = list{'Stimulus'}{'sigma0'};

B = rand(1); 
if  B <= hazard;
    RedMean_position = normrnd(0,sigma0);
end

list{'Stimulus'}{'RedMean'} = RedMean_position;
list{'Stimulus'}{'RedMeanlist'} = [list{'Stimulus'}{'RedMeanlist'}, RedMean_position];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
distribM = list{'Stimulus'}{'RedMean'};
SigmaRatio = list{'Stimulus'}{'SigmaRatio'};
sigma0 = list{'Stimulus'}{'sigma0'};

sample_sigma = SigmaRatio * sigma0;
distribS = normrnd(distribM,sample_sigma);


%This creates the gauss curve based off the RedBall mean
gauss.colors = [1 .5 .25];
gauss.x = (-ColumnUnit*10):.1:(ColumnUnit*10);
gauss.y = normpdf(gauss.x,distribM,sigma0);
gauss.isSmooth = true;
gauss.pixelSize = 5;
gauss.translation = [0 -3 0];
gauss.scaling = [1 15*sigma0 0];
gauss.primitive = 1;


list{'Stimulus'}{'GreenMean'} = distribS;
list{'Stimulus'}{'GreenMeanlist'} = [list{'Stimulus'}{'GreenMeanlist'}, distribS]; %#ok<NASGU>

% ++++++++
% FUNCTION: startAnimation
%
function startAnimation(list, arrow_animated, target_animated, learning, ballAnimator_samp)  

global counter

distribS = list{'Stimulus'}{'GreenMean'};
distribM = list{'Stimulus'}{'RedMean'};
drawables = list{'graphics'}{'drawables'};

previousRed = list{'Stimulus'}{'RedMeanlist'};
previousGreen = list{'Stimulus'}{'GreenMeanlist'};

PreviousBucketPosition = list{'learning'}{'PreviousBucketPosition'};
alpha = list{'learning'}{'alpha'};

arrow_animated.addMember('x', [0 .5], [previousRed(counter) distribM], true);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PredictionError = previousGreen(counter) - PreviousBucketPosition;
BucketPosition =  PreviousBucketPosition + alpha * PredictionError;

target_animated.addMember('x', [0 .5], [PreviousBucketPosition BucketPosition], true);
learning.string = strcat(num2str(BucketPosition),'=',num2str(PreviousBucketPosition),'+', num2str(alpha),'*',num2str(PredictionError));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ballAnimator_samp.addMember('yCenter', [1 1.5], ...
    [2.7 -2.7], true);
ballAnimator_samp.addMember('xCenter', [0 1 1.5], ...
    [100 distribS distribS], false);

drawables.callObjectMethod(@prepareToDrawInWindow)

list{'learning'}{'FeedbackLine'} = PredictionError;
list{'learning'}{'PreviousBucketPosition'} = BucketPosition; %#ok<NASGU>

function errorbar(list, FeedbackLine, ScoreCard)

global counter
distribS = list{'Stimulus'}{'GreenMean'};

FeedbackLine.xFrom = distribS;
FeedbackLine.xTo = list{'learning'}{'PreviousBucketPosition'};
score = abs(FeedbackLine.xTo - FeedbackLine.xFrom);
list{'learning'}{'scoreAggregate'} = [list{'learning'}{'scoreAggregate'},score];
currenttotal = sum(list{'learning'}{'scoreAggregate'});

if counter >= 4
ScoreCard.string = strcat('current score:',num2str(currenttotal));
end

% +++++++++
% FUNCTION: Update mouse
%

function update(list,...
    ColumnUnit, compMouse, MouseDot, SigmaButton, stext, HazardButton, htext, RatioButton, rtext,...
    PauseButton,FinishButton, fixedMachine, LearningPlus, LearningMinus, LearningBox)
sigma_change = list{'Stimulus'}{'sigma0'};
hazard = list{'Stimulus'}{'hazard'};
SigmaRatio = list{'Stimulus'}{'SigmaRatio'};
alpha = list{'learning'}{'alpha'};

compMouse.read();
[name] = compMouse.getNextEvent();
MouseDot.x = compMouse.x;
MouseDot.y = compMouse.y;

%Expands or shrinks parameters


if (SigmaButton.x(1)<=MouseDot.x) && (MouseDot.x<= SigmaButton.x(3)) && (SigmaButton.y(1)<=MouseDot.y) && (MouseDot.y<=SigmaButton.y(2))
        if strcmp(name, 'smaller')
            sigma_change = sigma_change - .1;
            SigmaButton.colors = [1 1 1];
            stext.string = strcat('sigma 0 value: ', num2str(sigma_change));
        elseif strcmp(name,'bigger')
             sigma_change = sigma_change +.1;
             SigmaButton.colors = [1 0 1];
             stext.string = strcat('sigma 0 value: ', num2str(sigma_change));
        end
end
if (HazardButton.x(1)<=MouseDot.x) && (MouseDot.x<= HazardButton.x(3)) && (HazardButton.y(1)<=MouseDot.y) && (MouseDot.y<=HazardButton.y(2))
        if strcmp(name, 'smaller')
            hazard = hazard - .1;
            HazardButton.colors = [1 1 1];
            htext.string = strcat('hazard rate:', num2str(hazard));
        elseif strcmp(name,'bigger')
            hazard = hazard +.1;
            HazardButton.colors = [1 0 1];
            htext.string = strcat('hazard rate:', num2str(hazard));
        end
end

if (RatioButton.x(1)<=MouseDot.x) && (MouseDot.x <=RatioButton.x(3)) && (RatioButton.y(1)<=MouseDot.y) && (MouseDot.y<=RatioButton.y(2))
        if strcmp(name, 'smaller')
            SigmaRatio = 0.5;
            RatioButton.colors = [1 1 1];
            rtext.string = strcat('Sigma Ratio:', num2str(SigmaRatio));
        elseif strcmp(name,'bigger')
            SigmaRatio = 2.0;
            RatioButton.colors = [1 0 1];
            rtext.string = strcat('Sigma Ratio:', num2str(SigmaRatio));
        end
end

if (PauseButton.x(1) <=MouseDot.x) && (MouseDot.x <=PauseButton.x(3)) && (PauseButton.y(1)<=MouseDot.y) && (MouseDot.y<=PauseButton.y(2))

    if strcmp(name, 'smaller')
        PauseButton.colors = [1 0 1];
        fixedMachine.editStateByName('pause', 'next', 'set');
        fixedMachine.editStateByName('set','next','animate');
    
    elseif strcmp(name,'bigger')
        PauseButton.colors = [1 1 1];
        fixedMachine.editStateByName('position','next','pause');
        pause.name = 'pause';
        pause.next = 'pause';
        fixedMachine.addState(pause);
    end
end

if (FinishButton.x(1) <=MouseDot.x) && (MouseDot.x <=FinishButton.x(3)) && (FinishButton.y(1)<=MouseDot.y) && (MouseDot.y<=FinishButton.y(2))
    
    if strcmp(name,'bigger')
        FinishButton.colors = [1 1 1];
        fixedMachine.editStateByName('error','next','finish');
        finish.name = 'finish';
        finish.next = '';
        finish.exit = IntentionalCrash;
        fixedMachine.addState(finish);
    end
end

if (LearningPlus.x(1) <=MouseDot.x) && (MouseDot.x <=LearningPlus.x(3)) && (LearningPlus.y(1)<=MouseDot.y) && (MouseDot.y<=LearningPlus.y(2))
    if strcmp(name,'bigger')
        alpha = alpha + .1;
        if alpha >= 1
            alpha = 1;
            LearningBox.xCenter = LearningPlus.x(3);
        else
            LearningBox.xCenter = (LearningBox.xCenter) + ColumnUnit;
            if LearningBox.xCenter >= LearningPlus.x(3)
                LearningBox.xCenter = LearningPlus.x(3);
            end
        end
        LearningPlus.colors = [.5 .9 .2];
    end
end

if (LearningMinus.x(1) <=MouseDot.x) && (MouseDot.x <=LearningMinus.x(3)) && (LearningMinus.y(1)<=MouseDot.y) && (MouseDot.y<=LearningMinus.y(2))
    if strcmp(name,'bigger')
        alpha = alpha - .1;
        if alpha <= 0
            alpha = 0;
            LearningBox.xCenter = LearningMinus.x(1);
        else
            LearningBox.xCenter = (LearningBox.xCenter) - ColumnUnit;
            if LearningBox.xCenter <= LearningMinus.x(1)
                LearningBox.xCenter = LearningMinus.x(1);
            end
        end
        LearningMinus.colors = [.5 .9 .2];
        
    end
end
list{'Stimulus'}{'sigma0'} = sigma_change;
list{'Stimulus'}{'hazard'} = hazard;
list{'Stimulus'}{'SigmaRatio'} = SigmaRatio;
list{'learning'}{'alpha'} = alpha; %#ok<NASGU>

% ++++++++
% FUNCTION: finishTree
%
function finishTree(sc)
sc.close;
