function [overtask, list] = CalibrationTaskXS(iter, donts)
%% Calibration Task
%Display calibration dots, change color predictably, and then get reaction
%time.

%% Housekeeping
%Setting up the screen
mglSetParam('visualAngleSquarePixels',0,1)
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 2); %change display index to 0 for debug. 1 for full screen. Use >1 for external monitors.
sc.reset('backgroundColor', [110 178 233]);
sc.pixelsPerDegree

%Call GetSecs just to load up the Mex files for getting time, so no delays
%later
GetSecs;
mglGetSecs;

%% List
%Creating list object that can be referenced by my functions
list = topsGroupedList();

%Setting important values
    blocks = 1;
    rtwindow = 1;
    changetimes = ones(1,blocks*9)*2; %dictates time to color change, in seconds.
    target_reactionTime = 0.4;

% CALIB
    if nargin < 1
        iter = 0;
    end
    
    if nargin < 2
        donts = [];
    end

    %Getting screensize of secondary (Tobii) monitor
    screensize = get(0, 'MonitorPositions'); 
    screensize = screensize(1,:); 
    set(0, 'DefaultFigurePosition', screensize)    

    % screensize = [1 1  1200 1920]; Default scr size, laptop

    Calib.mondims1.x = screensize(1);
    Calib.mondims1.y = screensize(2);
    Calib.mondims1.width = screensize(3);
    Calib.mondims1.height = screensize(4);

    Calib.MainMonid = 1; 
    Calib.TestMonid = 1;

    %Counstruct Calib points. Add them to each other to make some multiple
    %of 9 trials. 
    
    Calib.points.x = [0.1 0.1 0.1 0.5 0.5 0.5 0.9 0.9 0.9];  % X coordinates in [0,1] coordinate system 
    Calib.points.y = [0.1 0.5 0.9 0.1 0.5 0.9 0.1 0.5 0.9];  % Y coordinates in [0,1] coordinate system

    %Getting many blocks of Calib point
    Calib.points.x = repmat(Calib.points.x, 1, blocks);
    Calib.points.y = repmat(Calib.points.y, 1, blocks);
    
    %
    Calib.points.n = size(Calib.points.x, 2); % Number of calibration points
    Calib.bkcolor = [0 0 0]; % background color used in calibration process
    Calib.fgcolor = [1 0 0]; % (Foreground) color used in calibration process
    Calib.fgcolor2 = [1 0 0]; % Color used in calibration process when a second foreground color is used (Calibration dot)
    Calib.TrackStat = 25; % 
    Calib.altcolor = [1 1 0]; % Color the marker changes to (Stimulus)
    Calib.feedcolor = [0 1 0]; %Feedback color if a correct trial
    Calib.BigMark = 25; % the big marker 
    Calib.SmallMark = 7; % the small marker
    Calib.resize = 1; % To show a smaller window 

    mOrder = randperm(Calib.points.n); %Randomized sequence of dot presentation

%Adding all important values/structs to List

% SUBJECT
    list{'Subject'}{'ID'} = input('Subject ID: ', 's');

%CALIB
    list{'Calib'}{'Counter'} = 0; %Starts a counter for the task
    list{'Calib'}{'Screen'} = sc; %To use Snowdots in drawing targs
    list{'Calib'}{'Calib'} = Calib;
    list{'Calib'}{'mOrder'} = mOrder;
    list{'Calib'}{'iter'} = iter;
    list{'Calib'}{'donts'} = donts;
    
%COORDINATES
    list{'Coordinates'}{'X'} = Calib.points.x(mOrder);
    list{'Coordinates'}{'Y'} = Calib.points.y(mOrder);
    
%COLOR CHANGE
    list{'Change'}{'ReactionWindow'} = rtwindow; %Time in seconds allowed to make decision
    list{'Change'}{'TargetRT'} = target_reactionTime;
    list{'Change'}{'ChangeTimes'} = changetimes; %Times to color change
    
%TIMESTAMPS
    list{'Timestamps'}{'Drawing'} = zeros(1, Calib.points.n);
    list{'Timestamps'}{'Change'} = zeros(1, Calib.points.n);
    list{'Timestamps'}{'Response'} = zeros(1, Calib.points.n);
    list{'Timestamps'}{'ReactionTime'} = ones(1, Calib.points.n)*-10;
    list{'Timestamps'}{'TrialStart'} = zeros(1, Calib.points.n);
    list{'Timestamps'}{'Pulses'} = [];
    
% EYE TRACKER                   
    list{'Eye'}{'Left'} = [];
    list{'Eye'}{'Right'} = [];
    list{'Eye'}{'Time'} = [];
    list{'Eye'}{'RawTime'} = [];
    list{'Eye'}{'SynchState'} = [];
    
% SYNCH
    daq = labJack();
    daqinfo.port = 0;
    daqinfo.pulsewidth = 200; %milliseconds
    list{'Synch'}{'DAQ'} = daq;
    list{'Synch'}{'Info'} = daqinfo;
    list{'Synch'}{'Times'} = [];
    
%OUTPUT DATA
    list{'Output'}{'RT'} = zeros(1, Calib.points.n);
    
%Save function
startsave(list)
    
%% User Interface
gp = dotsReadableHIDGamepad(); %Set up a gamepad object

if gp.isAvailable % Use the gamepad if one is connected
    
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
    isA = strcmp({kb.components.name}, 'KeyboardSpacebar');
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
    
%% Graphics
    % Fixation point
    fix = dotsDrawableTargets();
    fix.colors = [1 1 1];
    fix.pixelSize = 10;
    fix.isVisible = false;
    fix.width = 0.5;
    fix.height = 0.5;
    
    %Permanent cursor
    permcursor = dotsDrawableTargets();
    permcursor.colors = [0.75 0.75 0.75];
    permcursor.width = 0.3;
    permcursor.height = 0.3;
    permcursor.isVisible = false;
    
    text = dotsDrawableText();
    text.string = '';
    text.fontSize = 42;
    text.typefaceName = 'Calibri';
    text.isVisible = false;
    
%Putting graphics into list
    list{'Graphics'}{'Target'} = fix;
    list{'Graphics'}{'Cursor'} = permcursor;
    list{'Graphics'}{'Text'} = text;
    
%     %Graphical ensemble
%     ensemble = dotsEnsembleUtilities.makeEnsemble('Fixation Point', false);
%     dot = ensemble.addObject(fix);
%     perm = ensemble.addObject(permcursor);
%     text = ensemble.addObject(text);
%     
%     list{'Graphics'}{'Ensemble'} = ensemble;
%     list{'Graphics'}{'Dot Index'} = dot;
%     list{'Graphics'}{'Perm Index'} = perm;
%     
%     % tell the ensembles how to draw a frame of graphics
%     %   the static drawFrame() takes a cell array of objects
%     ensemble.automateObjectMethod(...
%     'draw', @dotsDrawable.drawFrame, {}, [], true);
    
%% Callables
%This reads the UI when called
readui = topsCallList();
readui.addCall({@read ui}, 'Read ui');
readui.alwaysRunning = true;

% Read eyetracker data constant call
readgaze = topsCallList();
readgaze.addCall({@gazelog, list}, 'Read gaze');

%Trigger constant call (function that sends trigger and timestamps it)
synch = topsCallList();
synch.addCall({@pulser, list}, 'Send Synch Pulses');

%% Runnables
Machine = topsStateMachine();
calibList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'Draw', {}, {@calibpoint list}, {}, 0, 'Change';
                 'Change', {@changeup list}, {}, {}, 0, 'Feedback';
                 'Early', {@earlypress list},{},{}, 2, '';
                 'Feedback', {@feedback list}, {}, {}, 2, '';};
Machine.addMultipleStates(calibList);
Machine.clockFunction = @GetSecs; %Putting Machine on same clock as everything else

list{'Runnables'}{'Machine'} = Machine;

%Concurrent Composite
contask = topsConcurrentComposite();
contask.addChild(Machine);
contask.addChild(readui);
%contask.addChild(readgaze);
%contask.addChild(synch);

%Main task tree
maintask = topsTreeNode();
maintask.iterations = Calib.points.n;
maintask.addChild(contask);

overtask = topsTreeNode();
overtask.addChild(maintask);

end

function string = calibpoint(list)
    string = 'Feedback'; %ORIGINALLY THIS WAS 'CHANGE'
    %Import User Interface
    ui = list{'Input'}{'Controller'};
    
    %Log this current trial iteration
    counter = list{'Calib'}{'Counter'};
    counter = counter + 1;
    list{'Calib'}{'Counter'} = counter;
    
    %Import vital variables
    changetimes = list{'Change'}{'ChangeTimes'};
    Calib = list{'Calib'}{'Calib'};
    morder = list{'Calib'}{'mOrder'};
    donts = list{'Calib'}{'donts'};
    Machine = list{'Runnables'}{'Machine'};
    
    %Graphical variables
    fix = list{'Graphics'}{'Target'};
    text = list{'Graphics'}{'Text'};
    screen = list{'Calib'}{'Screen'};
    conversion = screen.pixelsPerDegree;
    
    %Log trial start time
    trialstarts = list{'Timestamps'}{'TrialStart'};
    trialstarts(counter) = Machine.startTime;
    list{'Timestamps'}{'TrialStart'} = trialstarts;
    
    %Prepping to plot calib point  
    %Algebraic manipulations are to convert coordinate systems
    Calib.mondims1.width
    X = Calib.mondims1.width*(Calib.points.x(morder(counter))-0.5); %-0.5 to offset Snowdots central origin point
    Y = Calib.mondims1.height*(-Calib.points.y(morder(counter))+0.5);
    X = X/conversion;
    Y = Y/conversion;
    fix.xCenter = X;
    fix.yCenter = Y;
    fix.colors = Calib.fgcolor;
    fix.isVisible = true;
    
    %Drawing point
    drawT = dotsDrawable.drawFrame({fix});
    
    %Storing data
    drawtimes = list{'Timestamps'}{'Drawing'};
    drawtimes(counter) = drawT.onsetTime;
    list{'Timestamps'}{'Drawing'} = drawtimes;
    
    %Waiting until color change
    tic
    while toc<changetimes(counter)
        read(ui);
        [a, b, eventname, d] = ui.getHappeningEvent();
        if ~isempty(eventname)
            string = 'Early'; %Aborting the iteration if bad trial
            %Draw negative feedback
            text.x = X;
            text.y = Y;
            text.color = [1 0 0];
            text.string = 'X';
            text.isVisible = true;
    
            dotsDrawable.drawFrame({text});
        end
    end
    
    %Adding calibration point
    tetio_addCalibPoint(Calib.points.x(morder(counter)),Calib.points.y(morder(counter)));
    
    %Changing color
    fix.colors = Calib.altcolor;
    fix.isVisible = true;
    
    %Drawing point
    if strcmp(string, 'Feedback')
        changeT = dotsDrawable.drawFrame({fix});
    elseif strcmp(string, 'Early')
        changeT.onsetTime = -1;
    end

    %STORING DATA
    changetimestamps = list{'Timestamps'}{'Change'};
    changetimestamps(counter) = changeT.onsetTime;
    list{'Timestamps'}{'Change'} = changetimestamps;
end

% function changeup(list)
%    %Find this current trial iteration
%     counter = list{'Calib'}{'Counter'};
%     
%     %Import vital variables
%     Calib = list{'Calib'}{'Calib'};
%     morder = list{'Calib'}{'mOrder'};
%     donts = list{'Calib'}{'donts'};
%     
%     %Graphical variables
%     fix = list{'Graphics'}{'Target'};
%     text = list{'Graphics'}{'Text'};
%     screen = list{'Calib'}{'Screen'};
%     conversion = screen.pixelsPerDegree;
%     
%     %Tell Tobii that the drawn points are points that the subject is
%     %looking at. 
%     tetio_addCalibPoint(Calib.points.x(morder(counter)),Calib.points.y(morder(counter)));
%     
%     %Setting calib point coordinates
%     X = Calib.mondims1.width*(Calib.points.x(morder(counter))-0.5); %-0.5 to offset Snowdots central origin point
%     Y = Calib.mondims1.height*(Calib.points.y(morder(counter))+0.5);
%     X = X/conversion;
%     Y = Y/conversion;
%     fix.xCenter = X;
%     fix.yCenter = Y;
%     fix.colors = Calib.altcolor;
%     fix.isVisible = true;
%     
%     %Drawing point
%     changeT = dotsDrawable.drawFrame({fix});
% 
%     %STORING DATA
%     changetimestamps = list{'Timestamps'}{'Change'};
%     changetimestamps(counter) = changeT.onsetTime;
%     list{'Timestamps'}{'Change'} = changetimestamps; 
% end

function feedback(list)
    %Import UI and ReactionWindow
    ui = list{'Input'}{'Controller'};
    rtwindow = list{'Change'}{'ReactionWindow'};
    
    %Find this current trial iteration
    counter = list{'Calib'}{'Counter'};
    
    %Import vital variables
    changetimestamps = list{'Timestamps'}{'Change'};
    targetRT = list{'Change'}{'TargetRT'};
    Calib = list{'Calib'}{'Calib'};
    morder = list{'Calib'}{'mOrder'};
    donts = list{'Calib'}{'donts'};
    
    %Graphical variables
    fix = list{'Graphics'}{'Target'};
    text = list{'Graphics'}{'Text'};
    screen = list{'Calib'}{'Screen'};
    conversion = screen.pixelsPerDegree;
    
    %Prepping to plot calib point  
    %Algebraic manipulations are to convert coordinate systems
    X = Calib.mondims1.width*(Calib.points.x(morder(counter))-0.5); 
    Y = Calib.mondims1.height*(-Calib.points.y(morder(counter))+0.5);
    X = X/conversion;
    Y = Y/conversion;
    text.x = X;
    text.y = Y;
    text.isVisible = true;
    

    responseT = -1; %Initialize response time as something inviable
    
    history = ui.history;
    history = history(history(:,3) > changetimestamps(counter), :);
    if ~isempty(history)
        
        %Compute RT
        responseT = history(end);
        changeT = changetimestamps(counter);
        responseT = responseT(end)-changeT;
        RT = num2str(responseT);
        
        %Draw RT on screen
        text.string = RT;
        text.color = [(responseT>targetRT) (responseT<=targetRT) 0];   
        dotsDrawable.drawFrame({text});
    else %if no button pressed yet
        tic
        while toc < rtwindow
            read(ui);
            [a, b, eventname, d] = ui.getHappeningEvent();
            if ~isempty(eventname)
                %COMPUTE RT
                changeT = changetimestamps(counter);
                responseT = ui.history;
                responseT = responseT(responseT(:,2) > 1, 3);
                responseT = responseT(end)-changeT;
                RT = num2str(responseT);
                
                text.string = RT;
                text.color = [(responseT>targetRT) (responseT<=targetRT) 0];
                
                dotsDrawable.drawFrame({text});
            end  
        end
    end
    
    % STORE DATA
    rtimes = list{'Output'}{'RT'};
    rtimes(counter) = responseT;
    list{'Output'}{'RT'} = rtimes;
end

function earlypress(list)
   %Find this current trial iteration
    counter = list{'Calib'}{'Counter'};
    
    %Import vital variables
    Calib = list{'Calib'}{'Calib'};
    morder = list{'Calib'}{'mOrder'};
    donts = list{'Calib'}{'donts'};

    %Tell Tobii that the drawn points are points that the subject is
    %looking at. 
    tetio_addCalibPoint(Calib.points.x(morder(counter)),Calib.points.y(morder(counter)));
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