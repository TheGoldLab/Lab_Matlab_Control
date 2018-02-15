function [maintask, list] = AudRTTaskT(effort, distractor_on)
%AudRT Task, [task, list] = AudRTTaskT(effort, distractor)
%by M.Kabir. E-mail at kabir.naim@gmail.com for bugfixes.

%Effort = 0 is a passive task.
%Effort = 1 is a single-button press task.
%Effort = 2 is a patterned button press task.
%Distractor_on = 0 is no distractor
%Distractor_on = 1 means distractor sounds WILL play.

%% Housekeeping
%Setting up the screen
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 2); %change display index to 0 for debug. 1 for full screen. Use >1 for external monitors.

%Call GetSecs just to load up the Mex files for getting time, so no delays
%later
GetSecs;

%% Setting up a list structure
list = topsGroupedList;

%Subject ID
subj_id = input('Subject ID: ','s');

%IV Parameters
if nargin < 1
    effort = 0; %0 is a passive task, 1 is a button press, 2 is a pattern press, 3 is long hold
    distractor_on = 0; %0 for no distractor, 1 for distractor
elseif nargin < 2
    distractor_on = 0;
end

%Setting important values
fixtime = 2; %fixation time in seconds
trials = 15;
H1 = 0.5;
H2 = 0.2;

%Getting sound sequence
statespace = [1 2]; %1 for left, 2 for right
statelist = zeros(1,trials);
statelist(1) = randi(length(statespace));
for i = 2:trials
    if statelist(i-1) == 1
        H = H1;
    else
        H = H2;
    end
    
    roll = rand;
    if roll > H
        statelist(i) = statelist(i-1);
    else
        newspace = statespace;
        newspace(newspace == statelist(i-1)) = [];
        statelist(i) = newspace(randi(length(newspace)));
    end
end
    
%Creating audioplayer
player = dotsPlayableNote();

%Getting sound wavfiles as .mat
azimuth1 = 90;  %Strong is 90--weak is anything less than 90.
azimuth2 = 360-azimuth1;

azimuth1 = num2str(azimuth1); %converting to strings to load wavfiles
azimuth2 = num2str(azimuth2);

wavL = [];
wavR = []; % each row is a sound channel
for i = 1:50  %sound versions stored in third dimension
    wavL(:,:,i) = audioread(['subj1023_az' azimuth1 '_v1.wav'])';
    wavR(:,:,i) = audioread(['subj1023_az' azimuth2 '_v1.wav'])';
end
wavfiles = cat(4, wavL, wavR); %Left and right sounds stored in 4th dimension

% SUBJECT INFORMATION
    list{'Subject'}{'ID'} = subj_id;

% COUNTER
    list{'Counter'}{'Trial'} = 0;
    
% STIMULUS
    list{'Stimulus'}{'Hazards'} = [H1, H2];
    list{'Stimulus'}{'Statelist'} = statelist;
    list{'Stimulus'}{'Azimuths'} = {azimuth1; azimuth2};
    list{'Stimulus'}{'Player'} = player;
    list{'Stimulus'}{'Wavfiles'} = wavfiles;
    
% TIMESTAMPS
list{'Timestamps'}{'Stimulus'} = zeros(1,trials);
list{'Timestamps'}{'Choices'} = zeros(1,trials);

% INPUT
list{'Input'}{'Choices'} = zeros(1,trials);
responsewindow = 3; %Time allowed to respond in, in seconds
list{'Input'}{'ResponseWindow'} = responsewindow;

% SYNCH
    daq = labJack();
    daqinfo.port = 0;
    daqinfo.pulsewidth = 200; %milliseconds
    list{'Synch'}{'DAQ'} = daq;
    list{'Synch'}{'Info'} = daqinfo;
    list{'Synch'}{'Times'} = [];

% EYE TRACKER
    list{'Eye'}{'Left'} = [];
    list{'Eye'}{'Right'} = [];
    list{'Eye'}{'Time'} = [];
    list{'Eye'}{'RawTime'} = [];
    list{'Eye'}{'SynchState'} = [];
    
    list{'Eye'}{'Fixtime'} = fixtime*60; %fixation time in terms of sample number
    
    
% DISTRACTOR
% adds distraction tones throughout task
    distractplayer = dotsPlayableNote();
    distractplayer.duration = 0.5;
    distractplayer.noise = 0.35;
    distractprobability = 0.15;
    list{'Distractor'}{'Player'} = distractplayer;
    list{'Distractor'}{'Probability'} = distractprobability;
    list{'Distractor'}{'Playtimes'} = []; 
    
    distractor = topsCallList();
    distractor.addCall({@distractfunc, list}, 'Play distractor sounds');

% EFFORT
% Modulate effort
if effort == 0
    effortFunction = @(x) passiveKey(x);
elseif effort == 1
    effortFunction = @(x) waitForChoiceKey(x);
else
    effortFunction = @(x) waitForChoiceKeyPattern(x);
end

%Passive listen parameters
passivetime = 0.35; %Wait time for sound to stop
list{'Effort'}{'PassiveTime'} = passivetime;

%Pattern press parameters
pattern = [2 4 2; 4 2 4]; %Top row is pattern to choose Left, bottom is Right
list{'Effort'}{'Pattern'} = pattern;
list{'Effort'}{'PatternWindow'} = 0.4; %Seconds in which the pattern must be completed

%Functions that operate on List
startsave(list);
    
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

%STATE MACHINE
Machine = topsStateMachine();
stimList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'CheckReady', {}, {@checkFixation list}, {}, 0, 'CheckReady';
                 'Stimulus', {@playstim list}, {}, {effortFunction list}, 0, 'Exit';
                 'Exit', {@stopstim list}, {}, {}, fixtime, ''};
             
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

function playstim(list)
    %Add this trial to the counter
    counter = list{'Counter'}{'Trial'};
    counter = counter + 1;
    list{'Counter'}{'Trial'} = counter;
    
    %Get current state
    statelist = list{'Stimulus'}{'Statelist'};
    state = statelist(counter);
    
    %Get sound file
    wavfiles = list{'Stimulus'}{'Wavfiles'};
    version = randi(50); %randomly choose one of 50 sound versions
    waveform = wavfiles(:,:, version, state);
    waveform = waveform(:,1:ceil((3/4)*length(waveform)));
    
    %Play sound
    player = list{'Stimulus'}{'Player'};
    player.waveform = [waveform waveform]; %waveform waveform waveform waveform waveform];
    player.play;
    
    %Get timestamp
    timestamps = list{'Timestamps'}{'Stimulus'};
    timestamps(counter) = player.lastPlayTime;
    list{'Timestamps'}{'Stimulus'} = timestamps;
    
    fprintf('Trial %d', counter)
end

function stopstim(list)
    %Get sound player
    player = list{'Stimulus'}{'Player'};
   
    %Stop player
    player.stop;
end

function waitForChoiceKey(list)
    % Getting list items
    choices = list{'Input'}{'Choices'};
    counter = list{'Counter'}{'Trial'};
    ui = list{'Input'}{'Controller'};
    player = list{'Stimulus'}{'Player'};
    responsewindow = list{'Input'}{'ResponseWindow'};
    playsecs = (length(player.waveform)/player.sampleFrequency)*6;
    
    ui.flushData
    
    %Initializing variable
    press = '';
    
    %Waiting for keypress
    tic 
    while ~strcmp(press, 'left') && ~strcmp(press, 'right')
        %Break loop if responsewindow expires and move to next trial
        if toc > responsewindow %This was previously Playsecs
            choice = NaN;
            timestamp = NaN;
            break
        end
        
        %Check for button press
        press = '';
        read(ui);
        [~, ~, eventname, ~] = ui.getHappeningEvent();
        if ~isempty(eventname) && length(eventname) == 1
            press = eventname;
        end
    end

    if strcmp(press, 'left')
        choice = 1;
        %Getting choice timestamp
        timestamp = ui.history;
        timestamp = timestamp(timestamp(:, 2) > 1, :); %Just to make sure I get a timestamp from a pressed key/button
        timestamp = timestamp(end);
    elseif strcmp(press, 'right')
        choice = 2;
        %Getting choice timestamp
        timestamp = ui.history;
        timestamp = timestamp(timestamp(:, 2) > 1, :); %Just to make sure I get a timestamp from a pressed key/button
        timestamp = timestamp(end);
    end
    
    %Updating choices list
    choices(counter+1) = choice;
    list{'Input'}{'Choices'} = choices;
    
    %Updating timestamps list
    timestamps = list{'Timestamps'}{'Choices'};
    timestamps(counter) = timestamp;
    list{'Timestamps'}{'Choices'} = timestamps;
end

function waitForChoiceKeyPattern(list)
    % Getting list items
    choices = list{'Input'}{'Choices'};
    counter = list{'Counter'}{'Trial'};
    ui = list{'Input'}{'Controller'};
    pattern = list{'Effort'}{'Pattern'};
    pwindow = list{'Effort'}{'PatternWindow'};
    player = list{'Stimulus'}{'Player'};
    playsecs = (length(player.waveform)/player.sampleFrequency)*6;
    responsewindow = list{'Input'}{'ResponseWindow'};
    
    [~, width] = size(pattern);
    
    ui.flushData
    
    %Initializing variables
    isPattern = 0;
    isUnderTime = 0;
    
    %Waiting for keypress
    tic 
    while isPattern == 0 || isUnderTime == 0
                
        %Break loop if responsewindow expires and move to next trial
        if toc > responsewindow
            choice = NaN; 
            timestamp = NaN;
            break
        end
        
        read(ui);
        loc_history = ui.history;
        loc_history = loc_history(loc_history(:,2) > 1, :); %Getting only rows with button presses
        
        %Check if the second column contains a matching pattern
        loc_vals = loc_history(:,2);
        loc_times = loc_history(:,3);
        for ii = 0:length(loc_vals)-width
            i = length(loc_vals) - ii; %Indexing so we get recent patterns first
            loc_idx = i-width+1:i;
            triplet = loc_vals(loc_idx)';
            isPattern = all(triplet == pattern(1,:) | triplet == pattern(2,:)); 
            
            %Checking that patern was pressed within the time window
            timerng = range(loc_times(loc_idx));
            isUnderTime = timerng < pwindow;
            
            if isPattern > 0 && isUnderTime > 0
                 if all(triplet == pattern(1,:))
                     choice = 1;
                 elseif all(triplet == pattern(2,:)) 
                     choice = 2;
                 end 
                 
                %Getting choice timestamp
                timestamp = loc_times(loc_idx(1)); %Getting time of first press in pattern
                
                %Break the for-loop. No need to keep searching for pattern.  
                break
            end
            
        end
        
    end
    
    %Updating choices list
    choices(counter+1) = choice;
    list{'Input'}{'Choices'} = choices;
    
    %Storing choice timestamp
    timestamps = list{'Timestamps'}{'Choices'};
    timestamps(counter) = timestamp;
    list{'Timestamps'}{'Choices'} = timestamps;
end

function passiveKey(list)
    pausetime = list{'Effort'}{'PassiveTime'};
    %No button press required here. Will simply wait a set time and cont.
    WaitSecs(pausetime);
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

function output = checkFixation(list)
    %Initialize output
    output = 'CheckReady'; %This causes a State Machine loop until fixation is achieved

    %Get parameters for holding fixation
    fixtime = list{'Eye'}{'Fixtime'};

    %Get eye data for left eye
    eyedata = list{'Eye'}{'Left'};
    if ~isempty(eyedata)
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

function pulser(list)
    %import list objects
    daq = list{'Synch'}{'DAQ'};
    daqinfo = list{'Synch'}{'Info'};
    
    %send pulse
    time = GetSecs; %getting timestamp. Cmd-response for labjack is <1ms
    daq.timedTTL(daqinfo.port, daqinfo.pulsewidth);
    disp('Pulse Sent');
    
    %logging timestamp
    list{'Synch'}{'Times'} = [list{'Synch'}{'Times'}; time];
end

function startsave(list)
    %creates a viable savename for use outside of function, to save file
    ID = list{'Subject'}{'ID'};
    savename = [ID '_Audio2AFC_list.mat'];
    
    %Checking if file already exists, if so, changes savename by appending
    %a number
    appendno = 1;
    while exist(savename)
        savename = [ID num2str(appendno) '_Audio2AFC_list.mat'];
        appendno = appendno + 1;
    end
    
    list{'Subject'}{'Savename'} = savename;
end

function distractfunc(list)
    %Import player
    player = list{'Distractor'}{'Player'};
    playprobability = list{'Distractor'}{'Probability'};
    
    %Give player characteristics
    maxwait = 7; %maximum possible wait time before a new sound plays
    player.frequency = normrnd(400, 150);
    
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