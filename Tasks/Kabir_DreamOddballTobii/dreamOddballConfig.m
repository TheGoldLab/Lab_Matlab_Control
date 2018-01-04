%% DreamTask: Oddball Version
function [maintask, list] = dreamOddballConfig(distractor_on, adaptive_on, opposite_input_on)
%% Housekeeping
%Setting up the screen
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 2); %change display index to 0 for debug. 1 for full screen. Use >1 for external monitors.

%Call GetSecs just to load up the Mex files for getting time, so no delays
%later
GetSecs;

%% Setting up a list structure
list = topsGroupedList;

%Oddball Task Parameters
if nargin < 1
    distractor_on = 0;
    adaptive_on = 0;
    opposite_input_on = 0;
elseif nargin < 2
    adaptive_on = 0;
    opposite_input_on = 0;
elseif nargin < 3
    opposite_input_on = 0;
end

list{'Input'}{'OppositeOn'} = opposite_input_on;
list{'Distractor'}{'On'} = distractor_on;

trials = 300; %trial number
interval = 2; %intertrial interval
standardf = 500; %standard frequency
oddf = 700; %oddball frequency
p_odd = 0.25; %probability of oddball freq

list{'Stimulus'}{'StandardFreq'} = standardf;
list{'Stimulus'}{'OddFreq'} = oddf;
list{'Stimulus'}{'ProbabilityOdd'} = p_odd;

%Subject ID
subj_id = input('Subject ID: ','s');

%Sound player
    player = dotsPlayableNote();
    player.duration = 0.5; %sound duration in seconds
    player.intensity = 0.7;
    player.ampenv = tukeywin(player.sampleFrequency*player.duration)';

    list{'Stimulus'}{'Player'} = player;

%INPUT PARAMETERS
    reactionwindow = 1; %Intertrial interval MUST be larger than this number for task to be robust
    responsepattern = [4 4 4]; %Pattern is right trigger-pull 3 times

    list{'Input'}{'ReactionWindow'} = reactionwindow;
    list{'Input'}{'ResponsePattern'} = responsepattern; 
    
    %Calculating 'effort' to respond
    Rvec = responsepattern;
    Rvec(Rvec == 2) = 1;
    Rvec(Rvec == 4) = 2; %Changing 4s and 2s to 1s and 2s for easy tabulation

    mix = tabulate(Rvec); %Getting how many lefts vs. rights
    total = sum(mix(:,2)); %Total buttons required to be pressed
    lefts = mix(1,2); %Lefts required to press
    
    %Calculating number of left/right sequences possible to generate with
    %this proportion of left/rights
    listperms = factorial(total)/(factorial(total - lefts)*factorial(lefts));

    %Getting effort as a combo of sequence length/complexity
    effort = (log2(listperms)+ 1)*total;
    
    list{'Input'}{'Effort'} = effort;
    
% EYE TRACKER
    list{'Eye'}{'Left'} = [];
    list{'Eye'}{'Right'} = [];
    list{'Eye'}{'Time'} = [];
    list{'Eye'}{'RawTime'} = [];
    list{'Eye'}{'SynchState'} = [];
    
    list{'Eye'}{'Fixtime'} = interval*60; %fixation time in terms of sample number
    
% DISTRACTOR
% adds distraction tones throughout task
    distractplayer = dotsPlayableNote();
    distractplayer.duration = 0.5;
    distractplayer.noise = 0;
    distractprobability = 0.15;
    list{'Distractor'}{'Player'} = distractplayer;
    list{'Distractor'}{'Probability'} = distractprobability;
    list{'Distractor'}{'Playtimes'} = []; 
    
    distractor = topsCallList();
    distractor.addCall({@distractfunc, list}, 'Play distractor sounds');
    
%QUEST OBJECT
    % Creating Quest structure
    tGuess = 200; %Guess at the appropriate difference between frequencies
    tGuessSd = 50; %Standard deviation in guesses permitted
    
    pThreshold = 0.70; %How successful do you want a subject to be?
    
    %Misc parameters that I actually don't understand yet
    beta = 3;
    delta = 0.01;
    gamma = 0.5;

    q = QuestCreate(tGuess, tGuessSd, pThreshold, beta, delta, gamma, [0.5], 10000); %Quest object created
    %NOTE: The 'range' value (last argument) was set arbitrarily. It may
    %not be enough if the trial number is higher than 300. 
    
    list{'Quest'}{'Object'} = q;
    

%Data Storage
list{'Stimulus'}{'Counter'} = 0;
list{'Stimulus'}{'Playtimes'} = zeros(1,trials); %Store sound player timestamps 
list{'Stimulus'}{'Playfreqs'} = zeros(1,trials); %Store frequencies played

list{'Input'}{'Choices'} = zeros(1,trials); %Storing if subject pressed the buttons required
list{'Input'}{'Corrects'} = ones(1,trials)*-1; %Storing correctness of answers. Initialized to 33 so we know if there was no input during a trial with 33.
list{'Timestamps'}{'Response'} = zeros(1,trials); %Storing subject response timestamp
%% Input
gp = dotsReadableHIDGamepad(); %Set up gamepad object
if gp.isAvailable
    % use the gamepad if connected
    ui = gp;
   
    % define movements, which must be held down
    %   map x-axis -1 to left and +1 to right
    isLeft = [gp.components.ID] == 7;
    isA = [gp.components.ID] == 3;
    isRight = [gp.components.ID] == 8;
    
    Left = gp.components(isLeft);
    A = gp.components(isA);
    Right = gp.components(isRight);
    
    gp.setComponentCalibration(Left.ID, [], [], [0 +2]);
    gp.setComponentCalibration(A.ID, [], [], [0 +3]);
    gp.setComponentCalibration(Right.ID, [], [], [0 +4]);
    
    % undefine any default events
    IDs = gp.getComponentIDs();
    for ii = 1:numel(IDs)
        gp.undefineEvent(IDs(ii));
    end
    
    %Define values for button presses
    gp.defineEvent(Left.ID, 'left', 0, 0, true);
    gp.defineEvent(A.ID, 'continue', 0, 0, true);
    gp.defineEvent(Right.ID, 'right', 0, 0, true);

else

   kb = dotsReadableHIDKeyboard(); %Use keyboard as last resort
    
    % define movements, which must be held down
    %   Left = +2, Up = +3, Right = +4
    isLeft = strcmp({kb.components.name}, 'KeyboardF');
    isA = strcmp({kb.components.name}, 'KeyboardW');
    isRight = strcmp({kb.components.name}, 'KeyboardJ');

    LeftKey = kb.components(isLeft);
    UpKey = kb.components(isA);
    RightKey = kb.components(isRight);
    
    kb.setComponentCalibration(LeftKey.ID, [], [], [0 +2]);
    kb.setComponentCalibration(UpKey.ID, [], [], [0 +3]);
    kb.setComponentCalibration(RightKey.ID, [], [], [0 +4]);
    
    % undefine any default events
    IDs = kb.getComponentIDs();
    for ii = 1:numel(IDs)
        kb.undefineEvent(IDs(ii));
    end
    
    % define events, which fire once even if held down
    % pressing w a d keys is a 'choice' event
    kb.defineEvent(LeftKey.ID, 'left',  0, 0, true);
    kb.defineEvent(UpKey.ID, 'up',  0, 0, true);
    kb.defineEvent(RightKey.ID, 'right',  0, 0, true);
    
ui = kb;

end

    %Making sure the UI is running on the same clock as everything else!
    %Using Operating System Time as absolute clock, from PsychToolbox
    ui.clockFunction = @GetSecs;

    %Storing ui in a List bin to access from functions!
    ui.isAutoRead = 1;
    list{'Input'}{'Controller'} = ui;

%% Graphics:
% Create some drawable objects. Configure them with the constants above.

list{'graphics'}{'gray'} = [0.25 0.25 0.25];
list{'graphics'}{'fixation diameter'} = 0.4;

    % instruction messages
    m = dotsDrawableText();
    m.color = list{'graphics'}{'gray'};
    m.fontSize = 48;
    m.x = 0;
    m.y = 0;

    % texture -- due to Kamesh
    isoColor1 = [30 30 30];
    isoColor2 = [40 40 40];
    checkerH = 10;
    checkerW = 10;

    checkTexture1 = dotsDrawableTextures();
    checkTexture1.textureMakerFevalable = {@kameshTextureMaker,...
    checkerH,checkerW,[],[],isoColor1,isoColor2};

    % a fixation point
    fp = dotsDrawableTargets();
    fp.isVisible = true;
    fp.colors = list{'graphics'}{'gray'};
    fp.width = list{'graphics'}{'fixation diameter'};
    fp.height = list{'graphics'}{'fixation diameter'};
    list{'graphics'}{'fixation point'} = fp;
    
    %Text prompts
    readyprompt = dotsDrawableText();
    readyprompt.string = 'Ready?';
    readyprompt.fontSize = 42;
    readyprompt.typefaceName = 'Calibri';
    readyprompt.isVisible = false;
    
    buttonprompt = dotsDrawableText();
    buttonprompt.string = 'press the A button to get started';
    buttonprompt.fontSize = 24;
    buttonprompt.typefaceName = 'Calibri';
    buttonprompt.y = -2;
    buttonprompt.isVisible = false;

    %Graphical ensemble
    ensemble = dotsEnsembleUtilities.makeEnsemble('Fixation Point', false);
    texture = ensemble.addObject(checkTexture1);
    ready = ensemble.addObject(readyprompt);
    button = ensemble.addObject(buttonprompt);
    dot = ensemble.addObject(fp);
    
    list{'Graphics'}{'Ensemble'} = ensemble;
    list{'Graphics'}{'Dot Index'} = dot;
    
    % tell the ensembles how to draw a frame of graphics
    %   the static drawFrame() takes a cell array of objects
    ensemble.automateObjectMethod(...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

%SCREEN

    % also put dotsTheScreen into its own ensemble
    screen = dotsEnsembleUtilities.makeEnsemble('screen', false);
    screen.addObject(dotsTheScreen.theObject());

    % automate the task of flipping screen buffers
    screen.automateObjectMethod('flip', @nextFrame);
      
%% Constant Calls
% Read User Interface constant call
readui = topsCallList();
readui.addCall({@read, ui}, 'Read the UI');

% Read eyetracker data constant call
readgaze = topsCallList();
readgaze.addCall({@gazelog, list}, 'Read gaze');

%% Runnables

if adaptive_on == 1
    checkfunc = @(x) checkquest(x);
    stimulusfunc = @(x) queststim(x); 
else
    checkfunc = @(x) checkinput(x); %Can also be checkquest(x) if adaptive difficulty = 1
    stimulusfunc = @(x) playstim(x); %Can also be queststim(x) if adaptive difficulty = 1
end

%STATE MACHINE
Machine = topsStateMachine();
stimList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'CheckReady', {}, {@checkFixation list}, {}, 0, 'CheckReady';
                 'Stimulus', {stimulusfunc list}, {}, {}, interval, 'Exit';
                 'Exit', {checkfunc list}, {}, {}, 0, ''};
             
Machine.addMultipleStates(stimList);

contask = topsConcurrentComposite();
contask.addChild(ensemble);
contask.addChild(readui);
contask.addChild(readgaze);
contask.addChild(Machine);

if distractor_on == 1
    contask.addChild(distractor)
end

maintask = topsTreeNode();
maintask.iterations = trials;
maintask.addChild(contask);
end

%% Accessory Functions
function checkquest(list)
    %import important list objects
    counter = list{'Stimulus'}{'Counter'};
    reactionwindow = list{'Input'}{'ReactionWindow'};
    pattern = list{'Input'}{'ResponsePattern'}; 
    ui = list{'Input'}{'Controller'};
    playtimes = list{'Stimulus'}{'Playtimes'};
    
    %Important objects pertinent to quest updating
    q = list{'Quest'}{'Object'};
    opposite_input_on = list{'Input'}{'OppositeOn'};
    freqlist = list{'Stimulus'}{'Playfreqs'};
    oddf = list{'Stimulus'}{'OddFreq'};
    standardf = list{'Stimulus'}{'StandardFreq'};
    
    %get current (playtime) and (playtime + reactionwindow)
    playtime = playtimes(counter);
    stoptime = playtime + reactionwindow;
    
    %Get all ui.history rows between these times(inclusive)
    history = ui.history(ui.history(:,3) >= playtime & ui.history(:,3) <= stoptime, :);
    
    %get only rows where there are presses
    history = history(history(:,2) > 1, :);
    
    %patternmatch in for loop
    width = length(pattern); %width of pattern expected, in samples
    isPattern = 0;
       
    %Check if the second column contains a matching pattern
    responsetime = -1; %Initialize responsetime as nonsense for nonresponse trials
    loc_vals = history(:,2);
    for i = 1:length(loc_vals)-(width-1)
            loc_idx = i : i+(width-1);
            grouping = loc_vals(loc_idx)';
            isPattern = all(grouping == pattern);
            
            if isPattern
                responsetime = history(loc_idx(end),3); %Getting time of last button press in pattern
                break %then exiting loop
            end
    end
    
    %Checking correct
    if opposite_input_on == 1
        checkfreq = standardf; %If opposite input is on, subjects must press button for standard frequency
    else
        checkfreq = oddf;
    end
    
    
    if isPattern && freqlist(counter) == checkfreq %If they pressed button, was it a good press?
        correct = 1;
    elseif ~isPattern && freqlist(counter) ~= checkfreq %Did they avoid pressing for the right reasons?
        correct = 1;
    else
        correct = 0;
    end
    
    
    %QUEST UPDATER
        % Getting actual difference between oddf and standardf
        diff = oddf - standardf;
    
        %Update QUEST object with latest response (the 'correct' variable)
        q = QuestUpdate(q, diff, correct);
        list{'Quest'}{'Object'} = q;
    
    %Storing user input and timestamps
    choices = list{'Input'}{'Choices'};
    choices(counter) = isPattern;
    list{'Input'}{'Choices'} = choices;
    
    corrects = list{'Input'}{'Corrects'};
    corrects(counter) = correct;
    list{'Input'}{'Corrects'} = corrects;
    
    responsetimes = list{'Timestamps'}{'Response'};
    responsetimes(counter)= responsetime;
    list{'Timestamps'}{'Response'} = responsetimes;  
end

function checkinput(list)
    %import important list objects
    counter = list{'Stimulus'}{'Counter'};
    reactionwindow = list{'Input'}{'ReactionWindow'};
    pattern = list{'Input'}{'ResponsePattern'}; 
    ui = list{'Input'}{'Controller'};
    playtimes = list{'Stimulus'}{'Playtimes'};
    
    %To check correct
    opposite_input_on = list{'Input'}{'OppositeOn'};
    freqlist = list{'Stimulus'}{'Playfreqs'};
    oddf = list{'Stimulus'}{'OddFreq'};
    standardf = list{'Stimulus'}{'StandardFreq'};
    
    %get current (playtime) and (playtime + reactionwindow)
    playtime = playtimes(counter);
    stoptime = playtime + reactionwindow;
    
    %Get all ui.history rows between these times(inclusive)
    history = ui.history(ui.history(:,3) >= playtime & ui.history(:,3) <= stoptime, :);
    
    %get only rows where there are presses
    history = history(history(:,2) > 1, :);
    
    %patternmatch in for loop
    width = length(pattern); %width of pattern expected, in samples
    isPattern = 0;
       
    %Check if the second column contains a matching pattern
    responsetime = -1; %Initialize responsetime as nonsense for nonresponse trials
    loc_vals = history(:,2);
    
    for i = 1:length(loc_vals)-(width-1)
            loc_idx = i : i+(width-1);
            grouping = loc_vals(loc_idx)';
            isPattern = all(grouping == pattern);
            
            if isPattern
                responsetime = history(loc_idx(end),3); %Getting time of last button press in pattern
                break %then exiting loop
            end
    end
    
    %Checking correct
    if opposite_input_on == 1
        checkfreq = standardf; %If opposite input is on, subjects must press button for standard frequency
    else
        checkfreq = oddf;
    end
    
    if isPattern && freqlist(counter) == checkfreq %If they pressed button, was it a good press?
        correct = 1;
    elseif ~isPattern && freqlist(counter) ~= checkfreq %Did they avoid pressing for the right reasons?
        correct = 1;
    else
        correct = 0;
    end
    
    %Storing user input and timestamps
    choices = list{'Input'}{'Choices'};
    choices(counter) = isPattern;
    list{'Input'}{'Choices'} = choices;
    
    corrects = list{'Input'}{'Corrects'};
    corrects(counter) = correct;
    list{'Input'}{'Corrects'} = corrects;
    
    responsetimes = list{'Timestamps'}{'Response'};
    responsetimes(counter)= responsetime;
    list{'Timestamps'}{'Response'} = responsetimes;  
end

function queststim(list)
    %Adding current iteration to counter
    counter = list{'Stimulus'}{'Counter'};
    counter = counter + 1;
    list{'Stimulus'}{'Counter'} = counter; 

    %Import important objects
    player = list{'Stimulus'}{'Player'};
    standardf = list{'Stimulus'}{'StandardFreq'};
    p_odd = list{'Stimulus'}{'ProbabilityOdd'};
    q = list{'Quest'}{'Object'};
    
    %Formulate new oddf
    freqdiff = abs(QuestQuantile(q));
    oddf = standardf + freqdiff;
    list{'Stimulus'}{'OddFreq'} = oddf;
    
    %Dice roll to decide if odd or standard
    roll = rand;
    frequency(roll > p_odd) = standardf;
    frequency(roll <= p_odd) = oddf;
    
    %Prepping player and playing
    player.frequency = frequency;
    player.prepareToPlay;

    player.play;

    %Logging times and frequencies
    playtimes = list{'Stimulus'}{'Playtimes'};
    playtimes(counter) = player.lastPlayTime;
    list{'Stimulus'}{'Playtimes'} = playtimes;
    
    playfreqs = list{'Stimulus'}{'Playfreqs'};
    playfreqs(counter) = frequency;
    list{'Stimulus'}{'Playfreqs'} = playfreqs;  
end

function playstim(list)
    %Adding current iteration to counter
    counter = list{'Stimulus'}{'Counter'};
    counter = counter + 1;
    list{'Stimulus'}{'Counter'} = counter; 
    
    %importing important list objects
    player = list{'Stimulus'}{'Player'};
    standardf = list{'Stimulus'}{'StandardFreq'};
    oddf = list{'Stimulus'}{'OddFreq'};
    p_odd = list{'Stimulus'}{'ProbabilityOdd'};

    %Dice roll to decide if odd or standard
    roll = rand;
    frequency(roll > p_odd) = standardf;
    frequency(roll <= p_odd) = oddf;

    %Prepping player and playing
    player.frequency = frequency;
    player.prepareToPlay;

    player.play;

    %Logging times and frequencies
    playtimes = list{'Stimulus'}{'Playtimes'};
    playtimes(counter) = player.lastPlayTime;
    list{'Stimulus'}{'Playtimes'} = playtimes;
    
    playfreqs = list{'Stimulus'}{'Playfreqs'};
    playfreqs(counter) = frequency;
    list{'Stimulus'}{'Playfreqs'} = playfreqs;
end

function gazelog(list)
    %Reading gaze
    [lefteye, righteye, timestamp, ~] = tetio_readGazeData;

    %Storing/Organizing data
    if ~isempty(lefteye) || ~isempty(righteye)
    
        leftx = lefteye(:,7); %column 7 is 2D X eye position
        lefty = lefteye(:,8); %column 8 is 2D y eye position
        leftp = lefteye(:,12); %column 12 is eye pupil diameter
        leftv = lefteye(:,13); %this column is validity code

        rightx = righteye(:,7);
        righty = righteye(:,8);
        rightp = righteye(:,12);
        rightv = righteye(:,13);

        list{'Eye'}{'Left'} = [list{'Eye'}{'Left'}; leftx lefty leftp leftv];
        list{'Eye'}{'Right'} = [list{'Eye'}{'Right'}; rightx righty rightp rightv];
        list{'Eye'}{'Time'}= [list{'Eye'}{'Time'}; timestamp];
        list{'Eye'}{'RawTime'} = [list{'Eye'}{'RawTime'}; timestamp];  
        list{'Eye'}{'SynchState'} = [list{'Eye'}{'SynchState'}; tetio_clockSyncState]; 
    end
end

function output = checkFixation(list)
    %Initialize output
    output = 'CheckReady'; %This causes a State Machine loop until fixation is achieved

    %Get parameters for holding fixation
    fixtime = list{'Eye'}{'Fixtime'}*60; %converting from seconds to samples

    %Get eye data for left eye
    eyedata = list{'Eye'}{'Left'};
    if ~isempty(eyedata) && length(eyedata) > fixtime + 1
        eyedata = eyedata(end-fixtime:end, :); %Cutting data to only the last 'fixtime' time window
        eyeX = eyedata(:,1);
        eyeY = eyedata(:,2);

        %cleaning up signal to let us tolerate blinks
        if any(eyeX > 0) && any(eyeY > 0)
            eyeX(eyeX < 0) = [];
            eyeY(eyeY < 0) = [];
        end

        %Seeing if there's fixation (X Y values between 0.45 and 0.55
        fixX = eyeX > 0.30 & eyeX < 0.70;
        fixY = eyeY > 0.30 & eyeY < 0.70;

        if all(fixY) && all(fixX)
            output = 'Stimulus'; %Send output to get State Machine to produce stimulus
        end
    end

end

function distractfunc(list)
    %Import player
    player = list{'Distractor'}{'Player'};
    playprobability = list{'Distractor'}{'Probability'};
    oddf = list{'Stimulus'}{'OddFreq'};
    
    %Give player characteristics
    player.frequency = oddf;
    
    %randomly assign whether or not noise will play
    willplay = rand;
    willplay = rand <= playprobability;
    
    player.intensity = 1*willplay;
    
    player.prepareToPlay;
    
    %Play sound
    player.play;
    
    %Store time
    list{'Distractor'}{'Playtimes'} = [list{'Distractor'}{'Playtimes'}, player.lastPlayTime];
end