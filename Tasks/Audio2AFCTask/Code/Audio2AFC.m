function [task, list] = Audio2AFC(trials)

%% Housekeeping
%Setting up the screen
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 2); %change display index to 0 for debug. 1 for full screen. Use >1 for external monitors.
sc.reset('backgroundColor', [110 178 233]);

%Call GetSecs just to load up the Mex files for getting time, so no delays
%later
GetSecs;

%% List Items
list = topsGroupedList();

if nargin < 1
    trials = 100;
end

%Setting important values
metahazard = 0.01;
hazards = [0.3, 0.05];
Adists = [1 0; 0 1];
Bdists = [0.8 0.2; 0.2 0.8];
fixtime = 3; %Minimum interstimulus interval (in seconds)
list{'Eye'}{'Fixtime'} = fixtime;

%Creating our audio player
player = dotsPlayableNote();
player.intensity = 0.5; %Player is loud. Set to small intensity (0.01)
player.frequency = 196.00;
player.duration = 0.3;

% SUBJECT
    list{'Subject'}{'ID'} = input('Subject ID? ', 's');

% STIMULUS
    list{'Stimulus'}{'Player'} = player;

    list{'Stimulus'}{'Counter'} = 0;
    list{'Stimulus'}{'Trials'} = trials;
    list{'Stimulus'}{'Metahazard'} = metahazard;
    list{'Stimulus'}{'Hazards'} = hazards;
    list{'Stimulus'}{'Statelist'} = zeros(1, trials);
    list{'Stimulus'}{'Statespace'} = [1 2];
  
    list{'Stimulus'}{'Directionlist'} = zeros(1, trials);
    
    list{'Stimulus'}{'Dists'} = {Adists, Bdists};
    list{'Stimulus'}{'Distlist'} = zeros(1, trials);
    list{'Stimulus'}{'Distspace'} = [1 2]; %Choose bottom/distribution 
    
% TIMESTAMPS
    list{'Timestamps'}{'Stimulus'} = zeros(1,trials); 
    list{'Timestamps'}{'Choices'} = zeros(1,trials);
    
% INPUT
    list{'Input'}{'Choices'} = zeros(1,trials+1); %trials + 1 because you can't actually make a choice on the first trial
       
% EYE TRACKER                   
    list{'Eye'}{'Left'} = [];
    list{'Eye'}{'Right'} = [];
    list{'Eye'}{'Time'} = [];
    list{'Eye'}{'RawTime'} = [];
    list{'Eye'}{'SynchState'} = [];

%% Input
gp = dotsReadableHIDGamepad(); %Set up gamepad object
gp.deviceInfo
if gp.isAvailable
    % use the gamepad if connected
    ui = gp;
   
    % define movements, which must be held down
    %   map x-axis -1 to left and +1 to right
    isLeft =  [gp.components.ID] == 7;
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
    isSpace = strcmp({kb.components.name}, 'KeyboardSpacebar');
    isRight = strcmp({kb.components.name}, 'KeyboardJ');

    LeftKey = kb.components(isLeft);
    SpaceKey = kb.components(isSpace);
    RightKey = kb.components(isRight);
    
    kb.setComponentCalibration(LeftKey.ID, [], [], [0 +2]);
    kb.setComponentCalibration(SpaceKey.ID, [], [], [0 +3]);
    kb.setComponentCalibration(RightKey.ID, [], [], [0 +4]);
    
    % undefine any default events
    IDs = kb.getComponentIDs();
    for ii = 1:numel(IDs)
        kb.undefineEvent(IDs(ii));
    end
    
    % define events, which fire once even if held down
    % pressing w a d keys is a 'choice' event
    kb.defineEvent(LeftKey.ID, 'left',  0, 0, true);
    kb.defineEvent(SpaceKey.ID, 'continue',  0, 0, true);
    kb.defineEvent(RightKey.ID, 'right',  0, 0, true);
    
ui = kb;
end

    %Making sure the UI is running on the same clock as everything else!
    %Using Operating System Time as absolute clock
    ui.clockFunction = @GetSecs;

    %Storing ui in a List bin to access from functions!
    ui.isAutoRead = 1;
    list{'Input'}{'Controller'} = ui;
    
%% Graphics

    % Fixation point
    fix = dotsDrawableTargets();
    fix.colors = [1 1 1];
    fix.pixelSize = 10;
    fix.isVisible = false;
    
    %Permanent cursor
    permcursor = dotsDrawableTargets();
    permcursor.colors = [0.75 0.75 0.75];
    permcursor.width = 0.3;
    permcursor.height = 0.3;
    permcursor.isVisible = false;
    
    readyprompt = dotsDrawableText();
    readyprompt.string = 'Ready?';
    readyprompt.fontSize = 42;
    readyprompt.typefaceName = 'Calibri';
    readyprompt.isVisible = true;
    
    buttonprompt = dotsDrawableText();
    buttonprompt.string = 'press the A button to get started';
    buttonprompt.fontSize = 24;
    buttonprompt.typefaceName = 'Calibri';
    buttonprompt.y = -2;
    buttonprompt.isVisible = true;
    
    %Graphical ensemble
    ensemble = dotsEnsembleUtilities.makeEnsemble('Fixation Point', false);
    dot = ensemble.addObject(fix);
    perm = ensemble.addObject(permcursor);
    ready = ensemble.addObject(readyprompt);
    button = ensemble.addObject(buttonprompt);
    
    list{'Graphics'}{'Ensemble'} = ensemble;
    list{'Graphics'}{'Dot Index'} = dot;
    list{'Graphics'}{'Perm Index'} = perm;
    
    % tell the ensembles how to draw a frame of graphics
    %   the static drawFrame() takes a cell array of objects
    ensemble.automateObjectMethod(...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

%% Constant Calls

% Read User Interface constant call
readui = topsCallList();
readui.addCall({@read, ui}, 'Read the UI');

% Read eyetracker data constant call
readgaze = topsCallList();
readgaze.addCall({@gazelog, list}, 'Read gaze');

%% Runnables  
    %Anonymous functions for use in state lists
    show = @(index) ensemble.setObjectProperty('isVisible', true, index); %show asset
    hide = @(index) ensemble.setObjectProperty('isVisible', false, index); %hide asset
  
    % Prepare machine, for use in antetask
    prepareMachine = topsStateMachine();
    prepList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                'Ready', {@startsave list},      {},      {@waitForCheckKey list},     0,       'Hide';
                'Hide', {hide [ready button]}, {}, {}, 0, 'Show';
                'Show', {show [perm dot]}, {}, {}, 0, 'Finish'
                'Finish', {}, {}, {}, 0, '';};
    prepareMachine.addMultipleStates(prepList);
            
    % State Machine, for use in maintask
    Machine = topsStateMachine();
    stimList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'CheckReady', {}, {@checkFixation list}, {}, 0, 'CheckReady'
                 'Stimulus', {@playnote list}, {}, {}, 0, 'Rest';
                 'Rest', {@waitForChoiceKey list}, {}, {}, 0, 'Exit';
                 'Exit', {}, {}, {}, fixtime, ''};
    Machine.addMultipleStates(stimList);
             
    % Concurrent Composites
    conprep = topsConcurrentComposite();
    conprep.addChild(ensemble);
    conprep.addChild(prepareMachine);
    
    contask = topsConcurrentComposite();
    contask.addChild(ensemble);
    contask.addChild(readgaze);
    contask.addChild(readui);
    contask.addChild(Machine);
    
    % Top Level Runnables    
    antetask = topsTreeNode();
    antetask.addChild(conprep);
    
    maintask = topsTreeNode();
    maintask.addChild(contask);
    maintask.iterations = list{'Stimulus'}{'Trials'};
    
    task = topsTreeNode();
    task.addChild(antetask);
    task.addChild(maintask);

end

%% Accessory Functions

function playnote(list)
    %Adding this iteration to counter
    counter = list{'Stimulus'}{'Counter'};
    counter = counter + 1;
    list{'Stimulus'}{'Counter'} = counter;

    %Importing list items
    player = list{'Stimulus'}{'Player'};
    playtimes = list{'Timestamps'}{'Stimulus'};
    metahazard = list{'Stimulus'}{'Metahazard'};
    statelist = list{'Stimulus'}{'Statelist'};
    statespace = list{'Stimulus'}{'Statespace'};
    hazards = list{'Stimulus'}{'Hazards'};
    dists = list{'Stimulus'}{'Dists'};
    distlist = list{'Stimulus'}{'Distlist'};
    dirlist = list{'Stimulus'}{'Directionlist'};
    
    %Rolling to see what hazard rate 'state' we're in
    if ~any(statelist) %50/50 diceroll to decide starting state
        roll = rand;
        state(roll > 0.5) = 1;
        state(roll <= 0.5) = 2;
    else %else roll to see hazard rate based on metahazard rate
        last = statelist(counter-1);
        newspace = statespace;
        newspace(newspace==last) = []; %editing statespace to disinclude last
        
        roll = rand;
        state(roll > metahazard) = last; 
        state(roll <= metahazard) = newspace(randi(length(newspace)));
    end
    
    %Updating statelist
    statelist(counter) = state;
    
    %Set hazard according to state
    H = hazards(state);
    
    %Set dists according to state
    dist = dists{state};
    
    if ~any(distlist)
        roll = rand; 
        distchoice(roll > 0.5) = 1;
        distchoice(roll <= 0.5) = 2;
        
        p = dist(distchoice,:); %Effective probability for this trial
    else
        last = distlist(counter - 1);
        newspace = statespace; 
        newspace(newspace == last) = [];
    
        roll = rand;
        distchoice(roll > H) = last; 
        distchoice(roll <= H) = newspace(randi(length(newspace)));
        
        p = dist(distchoice,:);
    end
    
    %Updating Distlist
    distlist(counter) = distchoice;
    
    %Choose sound direction based on probability distribution
    roll = rand;
    dir(roll <= p(1)) = 1;
    dir(roll > p(1)) = 2;
    
    %updating dirlist
    dirlist(counter) = dir;
    
    %Play sound
    player.prepareToPlay;
    if dir == 1
        player.waveform = [player.waveform(1,:); zeros(1, length(player.waveform))];
    elseif dir == 2
        player.waveform = [zeros(1, length(player.waveform)); player.waveform(1,:)];
    end
    
    player.play;
    playtimes(counter) = player.lastPlayTime; %Log audio onset time
    
    %Record stuff
    list{'Stimulus'}{'Statelist'} = statelist;
    list{'Stimulus'}{'Distlist'} = distlist;
    list{'Stimulus'}{'Directionlist'} = dirlist;
    list{'Timestamps'}{'Stimulus'} = playtimes;
end
    
function gazelog(list)
    %Reading gaze
    [lefteye, righteye, timestamp, trigSignal] = tetio_readGazeData;

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

function waitForCheckKey(list)
    % Getting list items
    ui = list{'Input'}{'Controller'};
    ui.flushData;
    
    %Initializing variable
    press = '';
  
    %Waiting for keypress
    while ~strcmp(press, 'continue')
        press = '';
        read(ui);
        [a, b, eventname, d] = ui.getHappeningEvent();
        if ~isempty(eventname) && length(eventname) == 1
            press = eventname;
        end
    end
end

function waitForChoiceKey(list)
    % Getting list items
    choices = list{'Input'}{'Choices'};
    counter = list{'Stimulus'}{'Counter'};
    ui = list{'Input'}{'Controller'};
    
    ui.flushData
    
    %Initializing variable
    press = '';
    
    disp('Waiting...')
    %Waiting for keypress
    while ~strcmp(press, 'left') && ~strcmp(press, 'right')
        press = '';
        read(ui);
        [a, b, eventname, d] = ui.getHappeningEvent();
        if ~isempty(eventname) && length(eventname) == 1
            press = eventname;
        end
    end
    
    disp('Pressed')
    
    if strcmp(press, 'left')
        choice = 1;
    else
        choice = 2;
    end
    
    %Updating choices list
    choices(counter+1) = choice; %counter + 1, because this is a prediction task
    list{'Input'}{'Choices'} = choices;
    
    %Getting choice timestamp
    timestamp = ui.history;
    timestamp = timestamp(timestamp(:, 2) > 1, :); %Just to make sure I get a timestamp from a pressed key/button
    timestamp = timestamp(end);
    
    timestamps = list{'Timestamps'}{'Choices'};
    timestamps(counter) = timestamp;
    list{'Timestamps'}{'Choices'} = timestamps;
end

function output = checkFixation(list)
    %Initialize output
    output = 'CheckReady'; %This causes a State Machine loop until fixation is achieved

    %Get parameters for holding fixation
    fixtime = list{'Eye'}{'Fixtime'}*60; %Converting from seconds to samples

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

        %Seeing if there's fixation (X Y values between 0.40 and 0.60
        fixX = eyeX > 0.40 & eyeX < 0.60;
        fixY = eyeY > 0.40 & eyeY < 0.60;

        if all(fixY) && all(fixX)
            output = 'Stimulus'; %Send output to get State Machine to produce stimulus
        end
    end

end

function startsave(list)
    %creates a viable savename for use outside of function, to save file
    ID = list{'Subject'}{'ID'};
    savename = [ID '_Audio2AFC_list.mat'];
    
    %Checking if file already exists, if so, changes savename by appending
    %a number
    appendno = 1;
    while exist(savename)
        savename = [ID num2str(appendno) '_Audio2AFC.mat'];
        appendno = appendno + 1;
    end
    
    list{'Subject'}{'Savename'} = savename;
end