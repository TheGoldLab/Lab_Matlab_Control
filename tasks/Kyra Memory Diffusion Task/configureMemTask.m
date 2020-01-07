function [tree, list] = configureMemTask(logic, isClient)
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
list{'timing'}{'feedback'} = 1.5 ;%0.75;
list{'timing'}{'intertrial'} = 0;

list{'graphics'}{'isClient'} = isClient;
list{'graphics'}{'white'} = [1 1 1];
list{'graphics'}{'lightgray'} = [0.55 0.55 0.55];
list{'graphics'}{'darkgray'} =[.12,.12,.12];
list{'graphics'}{'lightblue'} = [0.55 0.55 0.80];
list{'graphics'}{'gray'} = [0.30 0.30 0.30];
list{'graphics'}{'red'} =   [.75 0 0];  % red on Kyra comp[0.75 0.25 0.1];
list{'graphics'}{'yellow'} = [0.75 0.75 0];
list{'graphics'}{'green'} = [.25 0.75 0.1];
list{'graphics'}{'stimulus diameter'} = 7; %10;
list{'graphics'}{'fixation diameter'} = 0.4;
list{'graphics'}{'feedback diameter'} = 0.22;
list{'graphics'}{'ISO1'} = [0.1 0.1 0.1];
list{'graphics'}{'ISO2'} = [0.50 0.50 0.50];




% EYELINK  
    list{'Eyelink'}{'SamplingFreq'} = 1000; %Before 1000!!Check actual device sampling frequency in later version
    screensize = get(0, 'MonitorPositions');
    screensize = screensize(1, [3, 4]);
    centers = screensize/2;
    list{'Eyelink'}{'Centers'} = centers;
    list{'Eyelink'}{'Invalid'} = -32768;
    
    %Setting windows for fixation:
    window_width = 0.3*screensize(1);
    window_height = 0.3*screensize(2);
    
    xbounds = [centers(1) - window_width/2, centers(1) + window_width/2];
    ybounds = [centers(2) - window_height/2, centers(2) + window_height/2];
    
    list{'Eyelink'}{'XBounds'} = xbounds;
    list{'Eyelink'}{'YBounds'} = ybounds;


%% Graphics:
% Create some drawable objects. Configure them with the constants above.


%Checker Texture

    size=1;
    mainColor=list{'graphics'}{'darkgray'};


checkTexture1 = dotsDrawableTextures();
            checkTexture1.textureMakerFevalable = {@kameshTextureMaker,...
               size,size,...
                [],[],list{'graphics'}{'ISO1'},list{'graphics'}{'ISO2'}};
            checkTexture1.isVisible=true;
            
     stable = dotsEnsembleUtilities.makeEnsemble('stable', isClient);

     stable.addObject(checkTexture1);

 list{'graphics'}{'bg'}=checkTexture1;    

% Trial counter
logic = list{'object'}{'logic'};
counter = dotsDrawableText();
counter.string = strcat(num2str(logic.blockTotalTrials + 1), '/', num2str(logic.trialsPerBlock));
counter.color = mainColor;
counter.isBold = true;
counter.fontSize = 20;
counter.x = 0;
counter.y = -10;
list{'graphics'}{'counter'}=counter;

%Center points used to indicate fixation, trial start, and correctness
    % a fixation point
    fp = dotsDrawableTargets();
    fp.colors = mainColor;
    fp.width = list{'graphics'}{'fixation diameter'};
    fp.height = list{'graphics'}{'fixation diameter'};
    fp.nSides=4;
    list{'graphics'}{'fixation point'} = fp;

%     % que point
%     qp = dotsDrawableTargets();
%     qp.colors = list{'graphics'}{'lightgray'};
%     qp.width = list{'graphics'}{'fixation diameter'};
%     qp.height = list{'graphics'}{'fixation diameter'};
%     list{'graphics'}{'fixation point'} = qp;

    feedback = dotsDrawableTargets();
    feedback.colors = list{'graphics'}{'gray'};
    feedback.width = list{'graphics'}{'feedback diameter'};
    feedback.height = list{'graphics'}{'feedback diameter'};
    feedback.xCenter = 0;
    feedback.yCenter = 0;
    feedback.isVisible = false;
    list{'graphics'}{'feedback marker'} = feedback;
    
    
    

    
%Mouse Marker
    MM=dotsDrawableTargets();
    MM.colors= mainColor; %[.1,.1,.1]; %[.75 .0 .75];        %pink
    MM.xCenter=0;
    MM.yCenter=0;
    MM.width=.35;
    MM.height=.35;
%     MM.nSides=4;
    MM.isVisible=false;
    list{'graphics'}{'Mouse Marker'}=MM; 
    
%Anulus
    ring=dotsDrawableArcs();
    ring.colors=mainColor;
    ring.xCenter=0;
    ring.yCenter=0;
    ring.rInner=logic.targRadius-.025;
    ring.rOuter=logic.targRadius+.025;
    ring.startAngle=0;
    ring.sweepAngle=360;
    ring.nPieces=100;
    ring.isVisible=true;
    list{'graphics'}{'ring'}=ring;
    
    


%     
   drawables = dotsEnsembleUtilities.makeEnsemble('drawables', isClient);
    
    


  for i=1:max(logic.PossDots);
      dots=dotsDrawableTargets();
      dots.colors=[logic.colArray{i}];
    dots.xCenter=0;
    dots.yCenter=0;
    dots.width=.60;
    dots.height=.60;
    %dots.nSides=3;
    dots.isVisible=false;
    drawables.addObject(dots);
  end


  
%Feedback of Prediction
  feedbackP = dotsDrawableArcs();%dotsDrawableTargets();
    feedbackP.colors = list{'graphics'}{'lightgray'};
%     feedbackP.width = .9;
%     feedbackP.height = .9;
    feedbackP.xCenter = 0;
    feedbackP.yCenter = 0;
%     feedbackP.nSides=3;
%     
    feedbackP.rInner=logic.targRadius-.5;
    feedbackP.rOuter=logic.targRadius+.5;
    feedbackP.startAngle=0;
    feedbackP.sweepAngle=.5;
    feedbackP.nPieces=3;
 
    feedbackP.isVisible = false;
    list{'graphics'}{'feedback marker'} = feedbackP;
    
    %Error Marker
    error = dotsDrawableArcs();%dotsDrawableTargets();
    error.colors = list{'graphics'}{'lightgray'};
    error.xCenter=0;
    error.yCenter=0;
    error.rInner=logic.targRadius+1;
    error.rOuter=logic.targRadius+1.25;
    error.startAngle=0;
    error.sweepAngle=0;
    error.nPieces=30;
    error.isVisible=false;
    list{'graphics'}{'error marker'} = error;
    
    
    %Feedback of Prediction Guess
    GuessMarker = dotsDrawableTargets();
    GuessMarker.colors = list{'graphics'}{'lightgray'}; %[.75 .0 .75];
    GuessMarker.width = .35;
    GuessMarker.height = .35;
    GuessMarker.xCenter = 0;
    GuessMarker.yCenter = 0;
   % GuessMarker.nSides=4;
    GuessMarker.isVisible = false;
    list{'graphics'}{'GuessMarker'} = GuessMarker;

    
    
    
% aggregate all these drawable objects into a single ensemble
%   if isClient is true, graphics will be drawn remotely



% qpInd = drawables.addObject(qp);
feedbackInd = drawables.addObject(feedback);
fpInd = drawables.addObject(fp);
counterInd = drawables.addObject(counter);
MMInd=drawables.addObject(MM);
ringInd=stable.addObject(ring);
feedbackPInd=drawables.addObject(feedbackP);

GuessInd = drawables.addObject(GuessMarker);
errorInd=drawables.addObject(error);


% automate the task of drawing all these objects
drawables.automateObjectMethod('draw', @mayDrawNow);
stable.automateObjectMethod('draw', @mayDrawNow);
% also put dotsTheScreen into its own ensemble
screen = dotsEnsembleUtilities.makeEnsemble('screen', isClient);
screen.addObject(dotsTheScreen.theObject());


% automate the task of flipping screen buffers
screen.automateObjectMethod('flip', @nextFrame);

list{'graphics'}{'drawables'} = drawables;
list{'graphics'}{'stable'} = stable;
list{'graphics'}{'fixation point index'} = fpInd;
list{'graphics'}{'feedback marker index'} = feedbackInd;
list{'graphics'}{'counter index'} = counterInd;
list{'graphics'}{'MM Index'}=MMInd;
list{'graphics'}{'Ring Index'}=ringInd;
list{'graphics'}{'FeedbackP Index'}=feedbackPInd;

list{'graphics'}{'Guess Index'}=GuessInd;
list{'graphics'}{'Error Index'}=errorInd;

list{'graphics'}{'screen'} = screen;

%% Input:
% Create an input source.



compMouse = dotsReadableHIDMouse();
    %m = dotsReadableHIDMouse;
   % compMouse.isExclusive = 1;
    compMouse.isAutoRead = 1;
     
    compMouse.flushData;
%     compMouse.initialize();
     
     
%     % undefine any default events
%     IDs = compMouse.getComponentIDs();
%     for ii = 1:numel(IDs)
%         compMouse.undefineEvent(IDs(ii));
%     end
%     %Define a mouse button press event
%     compMouse.defineEvent(3, 'left', 0, 0, true);
%     compMouse.defineEvent(4, 'right', 0, 0, true);
%     %store the mouse separately in case we need to use it
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
block.startFevalable = {@configureStartBlock, list};
session.addChild(block);



trial = topsConcurrentComposite('trial');
block.addChild(trial);
trial.addChild(stable);

trialStates = topsStateMachine('trial states');
trial.addChild(trialStates);




list{'outline'}{'tree'} = tree;





%% Trial
% Define states for trials with constant timing.

tFeed = list{'timing'}{'feedback'};

% define shorthand functions for showing and hiding ensemble drawables
on = @(index)drawables.setObjectProperty('isVisible', true, index);
%onStable=@(index)stable.setObjectProperty('isVisible', true, index);
off = @(index)drawables.setObjectProperty('isVisible', false, index);
%offStable = @(index)stable.setObjectProperty('isVisible', false, index);
cho = @(index)drawables.setObjectProperty('colors', [0.25 0.25 0.25], index);
chf = @(index)drawables.setObjectProperty('colors', [0.45 0.45 0.45], index);



fixedStates = { ...
    'name'      'entry'         'timeout'	'exit'          'next'      'input'; ...
    'prepare1'  {on, [fpInd counterInd]} 0 {@flushui, list}           'prepare2'     {}; ...
    'prepare2'  {@checkFix list, .2}         0       {@editState,trialStates,list}  'turn on target' {}; ... %Change time of target on depending on if is a Visual or Memory
    'turn on target' {@onDots list}    0       {}         '' {};   %prepare two had on,  qpInd in entry  *********@offDots list in exit state if not doing overlap!!!
    'delay'     {@offDots list}                   0       {@toc}    'flush' {};  %indicate should make response   **** MAKE SURE FIXATING HERE AS WELL!
    'delay eye' {@offDots list} 0       {@checkFix list, logic.durationDelay}    'flush'  {};
    'loop'      {@checkLoop,trialStates, list             } 0       {}                ''    {};...
    'flush'     {@flushui, list}     0    {@setTimeStamp, logic}             'decision'     {}; ...
    'decision'  {@MoveMarker, list}  0   {}  'show feedback'  {}; ...  %***** MAYBE PUT DELAY HERE BEFORE FEEDBACK FOR PUPIL THINGS WHEN GET THAT RUNNING                                                                           % Or maybe not if still using color to indicate reward 
    'show feedback' {@showFeedback, list} tFeed {off [feedbackPInd,GuessInd]} 'clean' {};
    'clean'         {} 0 {}    'counter' {};                                               % *** Maybe set this to ~2 seconds in order to let pupil equilibrate???? 
    'counter'  {@addCount, list}  0   {on, [counterInd]}              'set'          {}; ... % always a good trial for now
    'set'  {@setGoodTrial, logic}  0   {}              ''          {}; ...
    'exit'     {@closeTree,tree}          0           {}          ''  {}; ...
    };


trialStates.addMultipleStates(fixedStates);
trialStates.startFevalable = {@configStartTrial, list};
trialStates.finishFevalable = {@configFinishTrial, list};
list{'control'}{'trial states'} = trialStates;


trial.addChild(drawables);
trial.addChild(screen);


%% Custom Behaviors:
% Define functions to handle some of the unique details of this task.


function editState(trialStates, list)
%Controls the timing and order of events in a trial:
logic = list{'object'}{'logic'};

%Control how long targets are on for
trialStates.editStateByName('turn on target', 'timeout', logic.durationTarget);

%Control the delay period
trialStates.editStateByName('delay', 'timeout', logic.durationDelay);

%Determine whether or not to sample and get a guess from the subject      

    if logic.useMouse==1
        trialStates.editStateByName('turn on target', 'next', 'delay');
    else
        trialStates.editStateByName('turn on target', 'next', 'delay eye'); 
    end
   
    
%    Determine if showing at same time or not
    if logic.tempDelay
        trialStates.editStateByName('delay eye', 'next', 'loop'); 
        trialStates.editStateByName('delay', 'next', 'loop');
        
    end
    

function checkLoop(trialStates, list)
%Controls the timing and order of events in a trial:
logic = list{'object'}{'logic'};


if logic.currentdot<logic.ndots
        trialStates.editStateByName('loop', 'next', 'turn on target');
else
            trialStates.editStateByName('loop', 'next', 'flush');

end
logic.currentdot=logic.currentdot+1;

    
    


function addCount(list)
%Add a number to the trial number counter   
logic= list{'object'}{'logic'};
drawables = list{'graphics'}{'drawables'};
counterInd = list{'graphics'}{'counter index'};
drawables.setObjectProperty('string', strcat(num2str(logic.blockTotalTrials + 1), '/',...
    num2str(logic.trialsPerBlock)), counterInd);

function onDots(list)
%turn on target dot if its not a sample trial
logic= list{'object'}{'logic'};
drawables = list{'graphics'}{'drawables'};
if logic.tempDelay && logic.currentdot<logic.ndots;
target=logic.currentdot;
    drawables.setObjectProperty('isVisible', true, [1:target]);
elseif logic.currentdot==logic.ndots;
        drawables.setObjectProperty('isVisible', true, [logic.ndots]);
else
    target=[1:logic.ndots];
    drawables.setObjectProperty('isVisible', true, target);
end
toc

 


function offDots(list)
%Turn off all the target blue dotsS
logic= list{'object'}{'logic'};
drawables = list{'graphics'}{'drawables'};

toc
if logic.tempDelay && logic.currentdot<logic.ndots;
target=logic.currentdot;
    drawables.setObjectProperty('isVisible', false, [1:target]);
elseif logic.currentdot==logic.ndots;
        drawables.setObjectProperty('isVisible', false, [logic.ndots]);
else
    target=[1:logic.ndots];
    drawables.setObjectProperty('isVisible', false, target);
end




function checkFix(list,fixtime)
    %disp('Checking Fix')
    %Import values
logic= list{'object'}{'logic'};

    fs = list{'Eyelink'}{'SamplingFreq'};
    invalid = list{'Eyelink'}{'Invalid'};
    xbounds = list{'Eyelink'}{'XBounds'};
    ybounds = list{'Eyelink'}{'YBounds'};
    
    fixms = fixtime*fs; %Getting number of fixated milliseconds needed
    if logic.useMouse==2
    %Initializing the structure that temporarily holds eyelink sample data
    
    done = 0;
    while ~done
    start_time = GetSecs;
    eyestruct = Eyelink( 'NewestFloatSample');
    end_time = GetSecs;
    if end_time-start_time < .003 
        done = 1;
    end
    end
    

    fixed = 0;
    brokenfix=0;
    
        if fixtime<1
        logic.matlabTimeStamp=start_time;
        logic.eyelinkTimeStamp=eyestruct.time;

        else
            logic.matlabTSDelay=start_time;
            logic.eyelinkTSDelay=eyestruct.time;
            
        end
        
         while fixed == 0
        %Ensuring eyestruct does not get prohibitively large. 
        %After 30 seconds it will clear and restart. This may cause longer
        %than normal fixation time required in the case that a subject
        %begins fixating close to this 30 second mark. 
        if length(eyestruct) > 30000
            eyestruct = Eyelink( 'NewestFloatSample');
        end
        
        %Adding new samples to eyestruct
        newsample = Eyelink( 'NewestFloatSample');
        if newsample.time ~= eyestruct(end).time %Making sure we don't get redundant samples
            eyestruct(end+1) = newsample;
        end

        
        whicheye = ~(eyestruct(end).gx == invalid); %logical index of correct eye
        
        if sum(whicheye) < 1
            whicheye = 1:2 < 2; %Defaults to collecting from left eye if both have bad data
        end
        
        xcell = {eyestruct.gx};
        ycell = {eyestruct.gy};
        
        time = [eyestruct.time];
        xgaze = cellfun(@(x) x(whicheye), xcell);
        ygaze = cellfun(@(x) x(whicheye), ycell);
        
        %cleaning up signal to let us tolerate blinks
        if any(xgaze > 0) && any(ygaze > 0)
            xgaze(xgaze < 0) = [];
            ygaze(ygaze < 0) = [];
            time(xgaze < 0) = []; %Applying same deletion to time vector
        end
        
        %Program cannot collect data as fast as Eyelink provides, so it's
        %necessary to check times for samples to get a good approximation
        %for how long a subject is fixating
        endtime = time(end);
        start_idx = find((time <= endtime - fixms), 1, 'last');
        
        if ~isempty(start_idx)
            lengthreq = length(start_idx:length(xgaze));
        else
            lengthreq = Inf;
        end
        
        if length(xgaze) >= lengthreq;
            if all(xgaze(start_idx :end)  >= xbounds(1) & ... 
                    xgaze(start_idx :end) <= xbounds(2)) && ...
                    all(ygaze(start_idx :end) >= ybounds(1) & ...
                    ygaze(start_idx :end) <= ybounds(2))
                
                fixed = 1;
                eyestruct = [];
            else
                if fixtime<1
                    brokenfix=1;
                else
                    logic.delayFixBreak=1;
                end
            end
        end
        
         end
%         disp('Fixated') 
        if fixtime<1
        logic.brokenFixes=[logic.brokenFixes,brokenfix];
        end
    end
    
    



function MoveMarker(list)
%Move the mouse until it is out of the target radius, indicating choice
compMouse=list{'input'}{'mouse'};
counter=list{'graphics'}{'counter'};
bg=list{'graphics'}{'bg'};
logic = list{'object'}{'logic'};
MM=list{'graphics'}{'Mouse Marker'};
s=list{'screen'}{'actual screen'};
fp=list{'graphics'}{'fixation point'};
ring=list{'graphics'}{'ring'};

compMouse.flushData;
scaleFac = s.pixelsPerDegree;


if logic.useMouse==1
mXprev = compMouse.x/scaleFac;
mYprev = compMouse.y/scaleFac;
sensitivityFac =   0.7*0.9; %.6*0.9; -- might want to lower this for motor error
else
     eyestruct = Eyelink( 'NewestFloatSample');
    mXprev= ((eyestruct.gx(1)/2048)*46.9491) - 23.4746;
    mYprev=-((eyestruct.gy(1)/1152)*26.4089) - 13.2044;
    sensitivityFac =   1; %.6*0.9; -- might want to lower this for motor error
end

MM.xCenter=0;
MM.yCenter=0;
MM.isVisible=true;

if logic.isDemo==1 && logic.currentBlock~=2;  %If we are just demoing
    %pick target, as ok, good, or great range
    logic.demoTarget=logic.distMean+logic.distSTD*logic.demoResponseList(logic.demoPointIndex);
    logic.demoPointIndex=logic.demoPointIndex+1;
end

%Move the mouse
while sqrt((MM.xCenter)^2+(MM.yCenter)^2)<logic.targRadius;
    if logic.isDemo==1 && logic.currentBlock~=2;  %If we are just demoing
        dx=1/4*cos(deg2rad(logic.demoTarget));
        dy=1/4*sin(deg2rad(logic.demoTarget));
        pause(.025);
        
    else
        if logic.useMouse==1
        compMouse.read();
        mXcurr = compMouse.x/scaleFac; mYcurr = -compMouse.y/scaleFac;
        else
            eyestruct = Eyelink( 'NewestFloatSample');
           mXcurr= ((eyestruct.gx(1)/2048)*46.9491) - 23.4746;
           mYcurr=-((eyestruct.gy(1)/1152)*26.4089) - 13.2044;
        end
        dx =sensitivityFac*(mXcurr-mXprev);
        dy=sensitivityFac*(mYcurr-mYprev);
    end
        MM.xCenter=MM.xCenter+dx;
        MM.yCenter=MM.yCenter+dy;
       
   %if logic.iso==1     
        bg.draw;
   %end
        fp.draw; ring.draw; MM.draw; counter.draw; 
        

        
                     
        s.nextFrame();
        if logic.isDemo~=1 || logic.currentBlock==2
        mXprev = mXcurr;
        mYprev = mYcurr;
        end
 MM.isVisible=false;
end

%if logic.iso==1
 bg.draw;
%end

%Store the guess
if MM.xCenter>=0 && MM.yCenter>=0
    logic.guessAngle=atand(MM.yCenter/MM.xCenter);
elseif MM.xCenter>=0 && MM.yCenter<0
    logic.guessAngle=360+atand(MM.yCenter/MM.xCenter);
else 
    logic.guessAngle=180+atand(MM.yCenter/MM.xCenter);
end




function flushui(list)

compMouse=list{'input'}{'mouse'};

compMouse.flushData;
list{'control'}{'current choice'} = 'none';

function configureStartBlock(list)
logic = list{'object'}{'logic'};
stable=list{'graphics'}{'stable'};
logic.startBlock();
stable.callObjectMethod(@prepareToDrawInWindow);
disp('I prepared to draw');



function configStartTrial(list)
% start Logic trial
logic = list{'object'}{'logic'};
logic.startTrial;

% clear data from the last trial

compMouse=list{'input'}{'mouse'};

compMouse.flushData;
list{'control'}{'current choice'} = 'none';

% reset the appearance of targets and cursor
%   use the drawables ensemble, to allow remote behavior
drawables = list{'graphics'}{'drawables'};
feedbackInd = list{'graphics'}{'feedback marker index'};
fpInd = list{'graphics'}{'fixation point index'};
feedbackPInd = list{'graphics'}{'FeedbackP Index'};
errorInd=list{'graphics'}{'Error Index'};

MMInd=list{'graphics'}{'MM Index'};
drawables.setObjectProperty( ...
    'colors', list{'graphics'}{'darkgray'}, [feedbackInd,fpInd,feedbackPInd,errorInd]);
drawables.setObjectProperty( ...
    'colors', logic.colArray{logic.targOfInt}, [MMInd]);



%Make the set of dots have the right values

ndots=logic.ndots;
samples=logic.TrueSamples;
       
        for i=1:ndots %nCoherentDots  
                drawables.setObjectProperty('xCenter',logic.targRadius*cos(samples(i)*pi/180), i);   
                drawables.setObjectProperty('yCenter',logic.targRadius*sin(samples(i)*pi/180), i);


        end





% let all the graphics set up to draw in the open window
drawables.setObjectProperty('isVisible', false);
                
        

   
%     end
%Set the non-targetdots if applicable


    

trialStates=list{'control'}{'trial states'};
%See if self timed or not

    trialStates.editStateByName('prepare1', 'timeout', logic.ITI);

drawables.callObjectMethod(@prepareToDrawInWindow); %PROBLEM IS HERE
    %want blue dots in separate ensamble than 

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

function showFeedback(list)
logic = list{'object'}{'logic'};
% hide the fixation point and cursor
drawables = list{'graphics'}{'drawables'};
fpInd = list{'graphics'}{'fixation point index'};
feedbackInd = list{'graphics'}{'feedback marker index'};
feedbackPInd = list{'graphics'}{'FeedbackP Index'};
errorInd=list{'graphics'}{'Error Index'};
GuessInd=list{'graphics'}{'Guess Index'};
counterInd = list{'graphics'}{'counter index'};
logic.setDetection();
% drawables.setObjectProperty('isVisible', false, [fpInd]);

if logic.targOfInt==6
    feedback=logic.TrueMean;
else
    feedback=logic.TrueSamples(logic.targOfInt);
end
        Errormarkers=[feedbackPInd,errorInd,fpInd];
      drawables.setObjectProperty('isVisible', true, [errorInd]);
      drawables.setObjectProperty('isVisible', true, [feedbackPInd]);




drawables.setObjectProperty('startAngle',feedback-.25, [feedbackPInd]);



    drawables.setObjectProperty('xCenter',cos(logic.guessAngle*pi/180)*logic.targRadius, [GuessInd]);
    drawables.setObjectProperty('yCenter', sin(logic.guessAngle*pi/180)*logic.targRadius, [GuessInd]);
    drawables.setObjectProperty('isVisible', true, [GuessInd]);


  drawables.setObjectProperty('startAngle', feedback, [errorInd]); 

  drawables.setObjectProperty('sweepAngle', rad2deg(angdiff(deg2rad(feedback),deg2rad(logic.guessAngle))), [errorInd]); 
 

%Old color system
Great=15;
Good=30;


if abs(logic.guessAngle-feedback)<Great  || 360-abs(logic.guessAngle-feedback)<Great %
    drawables.setObjectProperty( ...
        'colors', list{'graphics'}{'green'}, Errormarkers);
    logic.correct = 1;
    
elseif abs(logic.guessAngle-feedback)<Good  || 360-abs(logic.guessAngle-feedback)<Good %
    drawables.setObjectProperty( ...
        'colors', list{'graphics'}{'yellow'},Errormarkers);
    logic.correct = .5;
    
    
else
    drawables.setObjectProperty( ...
        'colors', list{'graphics'}{'red'}, Errormarkers);
    logic.correct = 0;

end



%Add a number to the trial number counter    
drawables = list{'graphics'}{'drawables'};
drawables.setObjectProperty('string', strcat(num2str(logic.blockTotalTrials + 1), '/',...
    num2str(logic.trialsPerBlock)), counterInd);




function wrapUp(list)
mglClose
logic = list{'object'}{'logic'};


cd '/Users/joshuagold/Psychophysics/Data/KyraODRTask';
holding=load(fullfile('/Users/joshuagold/Psychophysics/Data/KyraODRTask', logic.dataFileName));
SCORE=ScorerMattRaw(holding.statusData);
disp(' ');

disp('If this is day 1: Pay the subject:');
disp(SCORE);
disp('If this is day 2, Pay the subject:');
disp(SCORE*1.5); 

if logic.useMouse==2
    Eyelink('StopRecording');
    if logic.savePupil==1
    Eyelink('Command','set_idle_mode');
    WaitSecs(0.5);
    Priority();
    Eyelink('CloseFile');
    EDFfilename=logic.EDFfilename;
    try
        fprintf('Receiving data file ''%s''\n', EDFfilename );
        status=Eyelink('ReceiveFile', EDFfilename);
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(EDFfilename, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', EDFfilename, pwd );
        end
    catch rdf
        fprintf('Problem receiving data file ''%s''\n', EDFfilename );
        rdf;
    end
    edfdata = edfmex(EDFfilename,'.edf');
    edfSave=['EyeData' logic.dataFileName(13:end)];
    dataPath='/Users/joshuagold/Psychophysics/Data/KyraODRTask/';
    save([ dataPath edfSave  '_EDF' '.mat'], 'edfdata')
    Eyelink('Shutdown');
    end

end
screen = list{'graphics'}{'screen'};
screen.callObjectMethod(@close);


