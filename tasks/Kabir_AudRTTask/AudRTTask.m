function [maintask, list] = AudRTTask()
%AudRT Task
%% Housekeeping
%Setting up the screen
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 0); %change display index to 0 for debug. 1 for full screen. Use >1 for external monitors.

%Call GetSecs just to load up the Mex files for getting time, so no delays
%later
GetSecs;

%% Setting up a list structure
list = topsGroupedList;

%Subject ID
subj_id = input('Subject ID: ','s');

%Setting important values
trials = 20;
H1 = 0.2;
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
    list{'Stimulus'}{'Player'} = player;
    list{'Stimulus'}{'Wavfiles'} = wavfiles;
    
% TIMESTAMPS
    list{'Timestamps'}{'Stimulus'} = zeros(1,trials); 
    list{'Timestamps'}{'Choices'} = zeros(1,trials);
    
% INPUT
    list{'Input'}{'Choices'} = zeros(1,trials);
    
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
                 'CheckReady', {}, {}, {@waitForCheckKey list}, 0, 'Stimulus';
                 'Stimulus', {@playstim list}, {}, {@waitForChoiceKey list}, 0, 'Exit';
                 'Exit', {@stopstim list}, {}, {}, 0, ''};
             
    Machine.addMultipleStates(stimList);

contask = topsConcurrentComposite();
contask.addChild(ensemble);
contask.addChild(readui);
%contask.addChild(readgaze);
contask.addChild(Machine);

maintask = topsTreeNode();
maintask.iterations = trials;
maintask.addChild(contask);

end

%% Accessory Functions
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
    
    %Play sound
    player = list{'Stimulus'}{'Player'};
    player.waveform = [waveform waveform waveform waveform waveform];
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
    
    ui.flushData
    
    %Initializing variable
    press = '';
    
    %Waiting for keypress
    while ~strcmp(press, 'left') && ~strcmp(press, 'right')
        press = '';
        read(ui);
        [a, b, eventname, d] = ui.getHappeningEvent();
        if ~isempty(eventname) && length(eventname) == 1
            press = eventname;
        end
    end
       
    if strcmp(press, 'left')
        choice = 1;
    else
        choice = 2;
    end
    
    %Updating choices list
    choices(counter+1) = choice;
    list{'Input'}{'Choices'} = choices;
    
    %Getting choice timestamp
    timestamp = ui.history;
    timestamp = timestamp(timestamp(:, 2) > 1, :); %Just to make sure I get a timestamp from a pressed key/button
    timestamp = timestamp(end);
    
    timestamps = list{'Timestamps'}{'Choices'};
    timestamps(counter) = timestamp;
    list{'Timestamps'}{'Choices'} = timestamps;
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