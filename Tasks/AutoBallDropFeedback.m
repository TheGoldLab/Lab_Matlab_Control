function AutoBallDropFeedback
clc;
clear all

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

% +++ dotsDrawableLines objects: the ceiling and ground
% +++
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ceiling = dotsDrawableLines();
ceiling.xFrom     = -10;
ceiling.xTo       = 10;
ceiling.yFrom     = 3;
ceiling.yTo       = 3;
ceiling.pixelSize = 10;
ceiling.colors    = [0.6 0.6 0.6];
drawables.addObject(ceiling);

ground = dotsDrawableLines();
ground.xFrom     = -10;
ground.xTo       = 10;
ground.yFrom     = -3;
ground.yTo       = -3;
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
arrow.y = 4.1;
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

starget = dotsDrawableTargets();
starget.isSmooth = false;
starget.xCenter = 6;
starget.yCenter = 6;
starget.width = 2;
starget.height = 2;
starget.colors = [1 0 0];
starget.nSides = 4;
drawables.addObject(starget);

htarget = dotsDrawableTargets();
htarget.isSmooth = false;
htarget.xCenter = 3;
htarget.yCenter = 6;
htarget.width = 2;
htarget.height = 2;
htarget.colors = [0 1 0];
htarget.nSides = 4;
drawables.addObject(htarget);

rtarget = dotsDrawableTargets();
rtarget.isSmooth = false;
rtarget.xCenter = 0;
rtarget.yCenter = 6;
rtarget.width = 2;
rtarget.height = 2;
rtarget.colors = [0 0 1];
rtarget.nSides = 4;
drawables.addObject(rtarget);

ptarget = dotsDrawableTargets();
ptarget.isSmooth = false;
ptarget.xCenter = -4;
ptarget.yCenter = 6;
ptarget.width = 2;
ptarget.height = 2;
ptarget.colors = [0.5 0.5 0.5];
ptarget.nSides = 4;
drawables.addObject(ptarget);

stext = dotsDrawableText();
stext.string = strcat('sigma 0 value:', num2str(list{'Stimulus'}{'sigma0'}));
stext.fontSize = 30;
stext.x = 6.5;
stext.y = 7;
drawables.addObject(stext);

htext = dotsDrawableText();
htext.string = strcat('hazard rate:', num2str(list{'Stimulus'}{'hazard'}));
htext.fontSize = 30;
htext.x = 3;
htext.y = 7;
drawables.addObject(htext);

rtext = dotsDrawableText();
rtext.string = strcat('Sigma Ratio:', num2str(list{'Stimulus'}{'SigmaRatio'})); 
rtext.fontSize = 30;
rtext.x = -1;
rtext.y = 7;
drawables.addObject(rtext);

ptext = dotsDrawableText();
ptext.string = 'Pause';
ptext.fontSize = 30;
ptext.x = -4;
ptext.y = 7;
drawables.addObject(ptext);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

learning = dotsDrawableText();
learning.fontSize = 30;
learning.x = 0;
learning.y = -5;
drawables.addObject(learning);

LearningLine = dotsDrawableLines;
LearningLine.xFrom = -0.5;
LearningLine.xTo = 5.5;
LearningLine.yFrom = -7;
LearningLine.yTo = -7;
LearningLine.pixelSize = 5;
drawables.addObject(LearningLine)

LearningPlus = dotsDrawableTargets;
LearningPlus.xCenter = 5.5;
LearningPlus.yCenter = -7;
LearningPlus.width = .6;
LearningPlus.height = .6;
LearningPlus.colors = [1 1 1];
LearningPlus.nSides = 10;
LearningPlus.isSmooth = true;
drawables.addObject(LearningPlus);

LearningMinus = dotsDrawableTargets;
LearningMinus.xCenter = -0.5;
LearningMinus.yCenter = -7;
LearningMinus.width = .6;
LearningMinus.height = .6;
LearningMinus.colors = [1 1 1];
LearningMinus.nSides = 10;
LearningMinus.isSmooth = true;
drawables.addObject(LearningMinus);

LearningBox = dotsDrawableTargets;
LearningBox.xCenter = list{'learning'}{'alpha'} * 5;
LearningBox.yCenter = -7;
LearningBox.width = .5;
LearningBox.height = .5;
LearningBox.colors = [0 0 1];
LearningBox.nSides = 10;
LearningBox.isSmooth = true;
drawables.addObject(LearningBox);

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
tree.finishFevalable = {@finishTree};
    


% askInput = {@getStateInput};

% +++ fixedMachine does the simple stuff on each trial
fixedMachine = topsStateMachine('fixed states');
trialCalls = topsCallList('call functions');
trialCalls.addCall({@update, list, compMouse, MouseDot, starget, stext, htarget, htext, rtarget, rtext, ptarget, fixedMachine, LearningPlus, LearningMinus, LearningBox}, 'update');
 
 fixedStates = { ...
    'name'      'entry'    'next' 'timeout' 'exit'  'input'; ...
    'position'  {@startTrial, starget, htarget, rtarget, LearningPlus, LearningMinus, FeedbackLine}           'set'     1         {}  {}; ...
    'set'       {@Set_cue, list, gauss} 'animate'       0        {}                  {};...   
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
tree.run

% ++++++++
% FUNCTION: startTree
%
function startTree()

sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 1);
sc.open


% ++++++++
% FUNCTION: startTrial
%
function startTrial(starget, htarget, rtarget, LearningPlus, LearningMinus, FeedbackLine) 
global counter
counter = counter + 1;

starget.colors = [1 0 0];
htarget.colors = [0 1 0];
rtarget.colors = [0 0 1];
LearningPlus.colors = [1 1 1];
LearningMinus.colors = [1 1 1];

FeedbackLine.xTo = 0;
FeedbackLine.xFrom = 0;

% ++++++++
% FUNCTION: Set_cue
%    
function Set_cue(list, gauss)

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
gauss.x = -10:.1:10;
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

function update(list, compMouse, MouseDot, starget, stext, htarget, htext, rtarget, rtext, ptarget, fixedMachine, LearningPlus, LearningMinus, LearningBox)
sigma_change = list{'Stimulus'}{'sigma0'};
hazard = list{'Stimulus'}{'hazard'};
SigmaRatio = list{'Stimulus'}{'SigmaRatio'};
alpha = list{'learning'}{'alpha'};

compMouse.read();
[name] = compMouse.getNextEvent();
MouseDot.x = compMouse.x;
MouseDot.y = compMouse.y;

%Expands or shrinks parameters
if (4.5<=MouseDot.x) && (MouseDot.x<= 6.5) && (4.5<=MouseDot.y) && (MouseDot.y<=6.5)
        if strcmp(name, 'smaller')
            sigma_change = sigma_change - .1;
            starget.colors = [1 1 1];
            stext.string = strcat('sigma 0 value: ', num2str(sigma_change));
        elseif strcmp(name,'bigger')
             sigma_change = sigma_change +.1;
             starget.colors = [1 0 1];
             stext.string = strcat('sigma 0 value: ', num2str(sigma_change));
        end
end
if (2.5<=MouseDot.x) && (MouseDot.x<= 4.5) && (4.5<=MouseDot.y) && (MouseDot.y<=6.5)
        if strcmp(name, 'smaller')
            hazard = hazard - .1;
            htarget.colors = [1 1 1];
            htext.string = strcat('hazard rate:', num2str(hazard));
        elseif strcmp(name,'bigger')
            hazard = hazard +.1;
            htarget.colors = [1 0 1];
            htext.string = strcat('hazard rate:', num2str(hazard));
        end
end

if (-1<=MouseDot.x) && (MouseDot.x <=1.5) && (4.5<=MouseDot.y) && (MouseDot.y<=6.5)
        if strcmp(name, 'smaller')
            SigmaRatio = 0.5;
            rtarget.colors = [1 1 1];
            rtext.string = strcat('Sigma Ratio:', num2str(SigmaRatio));
        elseif strcmp(name,'bigger')
            SigmaRatio = 2.0;
            rtarget.colors = [1 0 1];
            rtext.string = strcat('Sigma Ratio:', num2str(SigmaRatio));
        end
end

if (-5 <=MouseDot.x) && (MouseDot.x <=-3.5) && (4.5<=MouseDot.y) && (MouseDot.y<=6.5)

    if strcmp(name, 'smaller')
        ptarget.colors = [1 0 1];
        fixedMachine.editStateByName('pause', 'next', 'set');
        fixedMachine.editStateByName('set','next','animate');
    
    elseif strcmp(name,'bigger')
        ptarget.colors = [1 1 1];
        fixedMachine.editStateByName('position','next','pause');
        pause.name = 'pause';
        pause.next = 'pause';
        fixedMachine.addState(pause);
    end
end

if (4.5 <=MouseDot.x) && (MouseDot.x <=6.5) && (-8<=MouseDot.y) && (MouseDot.y<=-6)
    if strcmp(name,'bigger')
        alpha = alpha + .1;
        if alpha >= 1
            alpha = 1;
            LearningBox.xCenter = 5;
        else
            LearningBox.xCenter = LearningBox.xCenter + 0.5;
        end
        LearningPlus.colors = [.5 .9 .2];
    end
end

if (-1 <=MouseDot.x) && (MouseDot.x <=1) && (-8<=MouseDot.y) && (MouseDot.y<=-6)
    if strcmp(name,'bigger')
        alpha = alpha - .1;
        if alpha <= 0
            alpha = 0;
            LearningBox.xCenter = 0;
        else
            LearningBox.xCenter = LearningBox.xCenter - 0.5;
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
function finishTree()
dotsTheScreen.closeWindow;