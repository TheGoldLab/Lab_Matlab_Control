%% Heart rate task 
function [maintask, list] = HRVTask
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

%Making sounds to play
player = dotsPlayableNote();
player.duration = 0.05;
player.frequency = 700;
player.prepareToPlay;

soundOn = player.waveform;

player.intensity = 0;
player.prepareToPlay;

soundOff = player.waveform;

soundmatrix = cat(3, soundOff, soundOn);

%Building list of random wait times for sound
trials = 300;
hazard = 0; %set to 0 for no noise. Set to 0.05 for rare noise
playlist = rand(1,trials);
playlist = playlist <= hazard;


% STIMULUS
    list{'Stimulus'}{'Player'} = player;
    list{'Stimulus'}{'Playlist'} = playlist;
    list{'Stimulus'}{'Soundmatrix'} = soundmatrix;
    list{'Stimulus'}{'Counter'} = 0;
    list{'Stimulus'}{'Trials'} = trials;
    list{'Stimulus'}{'Hazard'} = hazard;
    list{'Stimulus'}{'Timestamps'} = zeros(1, trials);
    
% SYNCH
    %Scanner object
    scan = AInScan1208FS();
    scan.channels = [10 10]; %CHANNEL IS 11 ON THE DEVICE UPSTAIRS
    scan.frequency = 10000;
    list{'Synch'}{'Scanner'} = scan;

    %Pulser object
    pulser = dotsDOut1208FS();
    pulser.pulseWidth = 0.2;
    list{'Synch'}{'Pulser'} = pulser;
    list{'Synch'}{'Port'} = 0;
    
    list{'Synch'}{'Out'} = [];
    list{'Synch'}{'In'} = [];
    
% EYE TRACKER                   
    list{'Eye'}{'Left'} = [];
    list{'Eye'}{'Right'} = [];
    list{'Eye'}{'Time'} = [];
    list{'Eye'}{'RawTime'} = [];
    list{'Eye'}{'SynchState'} = [];
    
%% Graphics
    % Fixation point
    fix = dotsDrawableTargets();
    fix.colors = [1 1 1];
    fix.pixelSize = 10;
    fix.isVisible = true;
    
    %Permanent cursor
    permcursor = dotsDrawableTargets();
    permcursor.colors = [0.75 0.75 0.75];
    permcursor.width = 0.3;
    permcursor.height = 0.3;
    permcursor.isVisible = true;
    
    %Graphical ensemble
    ensemble = dotsEnsembleUtilities.makeEnsemble('Fixation Point', false);
    dot = ensemble.addObject(fix);
    perm = ensemble.addObject(permcursor);
    
    list{'Graphics'}{'Ensemble'} = ensemble;
    list{'Graphics'}{'Dot Index'} = dot;
    list{'Graphics'}{'Perm Index'} = perm;
    
    % tell the ensembles how to draw a frame of graphics
    %   the static drawFrame() takes a cell array of objects
    ensemble.automateObjectMethod(...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

%% Call Lists
% Read eyetracker data constant call
readgaze = topsCallList();
readgaze.addCall({@gazelog, list}, 'Read gaze');

%Trigger constant call (function that sends trigger and timestamps it)
synch = topsCallList();
synch.addCall({@pacsynch, list}, 'Send Synch Pulses');

%% Runnables
Machine = topsStateMachine();
calibList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'Play', {@playsound list}, {}, {}, 0, '';};
Machine.addMultipleStates(calibList);

%Concurrent Composite
contask = topsConcurrentComposite();
contask.addChild(ensemble);
contask.addChild(Machine);
contask.addChild(readgaze);
contask.addChild(synch);

%Main task tree
maintask = topsTreeNode();
maintask.iterations = trials;
maintask.addChild(contask);
    
end

function playsound(list)
    %Adding this iteration to counter
    counter = list{'Stimulus'}{'Counter'};
    counter = counter + 1;
    list{'Stimulus'}{'Counter'} = counter;
    
    %Importing list items
    player = list{'Stimulus'}{'Player'};
    playlist = list{'Stimulus'}{'Playlist'};
    soundmatrix = list{'Stimulus'}{'Soundmatrix'};
    
    %Seeing if sound will play
    player.intensity = playlist(counter);
    player.prepareToPlay; %Made generative. Using preloaded data causes timestamp issues. 
    
    %Playing sound
    player.play
    fprintf('Stimulus %d\n', counter)
    
    %Storing timestamp
    timestamps = list{'Stimulus'}{'Timestamps'};
    timestamps(counter) = player.lastPlayTime;
    list{'Stimulus'}{'Timestamps'} = timestamps;
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

function pacsynch(list)
    %Importing list items
    scanner = list{'Synch'}{'Scanner'};
    pulser = list{'Synch'}{'Pulser'};
    
    out = list{'Synch'}{'Out'};
    in = list{'Synch'}{'In'};

    %Scanning
    scanner.prepareToScan();
    ti = scanner.startScan();
    
    %starting pulse sequence
    t_out = pulser.sendTTLPulse(0);%0 is ch1, 1 is ch2. 
    out = [out, t_out*1e6]; % 10e6 is to get this in terms of microseconds, like tetio_localTimeNow
    pause(0.5)
 
    %Stopping, getting voltage data; 
    tf = scanner.stopScan();
    
    [c, v, t, u] =  scanner.getScanWaveform;
    
    v(v<3) = 0;
    max_idx = [0 diff(v)];
    max_idx = find(max_idx);
    
    in = [in, t(max_idx(1))*1e6];

list{'Synch'}{'Out'} = out;
list{'Synch'}{'In'} = in;
end