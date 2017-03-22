function [overtask, list] = CalibrationTask(iter, donts)
%% Calibration Task
%Display calibration dots, change color predictably, and then get reaction
%time.

%% Housekeeping
%Call GetSecs just to load up the Mex files for getting time, so no delays
%later
GetSecs;

%% List
%Creating list object that can be referenced by my functions
list = topsGroupedList();

%Setting important values
    blocks = 2;
    rtwindow = 1;
    changetimes = ones(1,blocks*9)*2; %dictates time to color change, in seconds.

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

%CALIB
    list{'Calib'}{'Counter'} = 0; %Starts a counter for the task
    list{'Calib'}{'Calib'} = Calib;
    list{'Calib'}{'mOrder'} = mOrder;
    list{'Calib'}{'iter'} = iter;
    list{'Calib'}{'donts'} = donts;
    
%COORDINATES
    list{'Coordinates'}{'X'} = Calib.points.x(mOrder);
    list{'Coordinates'}{'Y'} = Calib.points.y(mOrder);
    
%COLOR CHANGE
    list{'Change'}{'ReactionWindow'} = rtwindow; %Time in seconds allowed to make decision
    list{'Change'}{'ChangeTimes'} = changetimes; %Times to color change
    
%TIMESTAMPS
    list{'Timestamps'}{'Drawing'} = zeros(1, Calib.points.n);
    list{'Timestamps'}{'Change'} = zeros(1, Calib.points.n);
    list{'Timestamps'}{'Response'} = zeros(1, Calib.points.n);
    list{'Timestamps'}{'ReactionTime'} = zeros(1, Calib.points.n);
    list{'Timestamps'}{'TrialStart'} = zeros(1, Calib.points.n);
    list{'Timestamps'}{'Pulses'} = [];
    
%OUTPUT DATA
    list{'Output'}{'RT'} = zeros(1, Calib.points.n);
    
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
    
%% Callables

%This reads the UI when called
readui = topsCallList();
readui.addCall({@read ui}, 'Read ui');
readui.alwaysRunning = true;

%Tester
disper = topsCallList();
disper.addCall({@disp 'Running'}, 'Read ui');
disper.alwaysRunning = true;

%Sends synch pulses when called

%% Runnables
Machine = topsStateMachine();
calibList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'Draw', {@calibpoint list}, {}, {}, 0, 'Change';
                 'Change', {@changeup list}, {}, {}, 0, 'Feedback';
                 'Feedback', {@feedback list}, {}, {}, 0, '';};
Machine.addMultipleStates(calibList);

%Concurrent Composite
contask = topsConcurrentComposite();
contask.addChild(Machine);
contask.addChild(readui);

%Main task tree
maintask = topsTreeNode();
%maintask.startFevalable = {@openfig, list};
maintask.iterations = Calib.points.n;
maintask.addChild(contask);

overtask = topsTreeNode();
overtask.startFevalable = {@openfig, list};
overtask.addChild(maintask);

end

function calibpoint(list)

    %Log this current trial iteration
    counter = list{'Calib'}{'Counter'};
    counter = counter + 1;
    list{'Calib'}{'Counter'} = counter;
    
    %Import vital variables
    Calib = list{'Calib'}{'Calib'};
    morder = list{'Calib'}{'mOrder'};
    donts = list{'Calib'}{'donts'};
    
    %Plotting calib point
    
    Calib.mondims = Calib.mondims1;
    ms = Calib.BigMark; 

    
    axes('Visible', 'off', 'Units', 'normalize','Position', [0 0 1 1],'DrawMode','fast','NextPlot','replacechildren');
    xlim([1,Calib.mondims.width]); 
    ylim([1,Calib.mondims.height]);
    axis ij;
    set(gca,'xtick',[]);
    set(gca,'ytick',[]); 
    
    
    plot(Calib.mondims.width*Calib.points.x(morder(counter)),...
         Calib.mondims.height*Calib.points.y(morder(counter)),...
         'o','MarkerEdgeColor',Calib.fgcolor,'MarkerFaceColor',Calib.fgcolor ,'MarkerSize',ms);
     
    drawT = GetSecs; 
    drawnow;
    
    %Storing data
    drawtimes = list{'Timestamps'}{'Drawing'};
    drawtimes(counter) = drawT;
    list{'Timestamps'}{'Drawing'} = drawtimes;
end



function changeup(list)
   %Find this current trial iteration
    counter = list{'Calib'}{'Counter'};
    
    %Import vital variables
    changetimes = list{'Change'}{'ChangeTimes'};
    Calib = list{'Calib'}{'Calib'};
    morder = list{'Calib'}{'mOrder'};
    donts = list{'Calib'}{'donts'};
    
    pause(changetimes(counter)) %Pausing the appropriate amount of time 'till color change
    
    %Tell Tobii that the drawn points are points that the subject is
    %looking at. 
    tetio_addCalibPoint(Calib.points.x(morder(counter)),Calib.points.y(morder(counter)));
    
    %Plotting calib point  
    Calib.mondims = Calib.mondims1;
    ms = Calib.BigMark; 
    
    axes('Visible', 'off', 'Units', 'normalize','Position', [0 0 1 1],'DrawMode','fast','NextPlot','replacechildren');
    xlim([1,Calib.mondims.width]); 
    ylim([1,Calib.mondims.height]);
    axis ij;
    set(gca,'xtick',[]);
    set(gca,'ytick',[]); 
    

    plot(Calib.mondims.width*Calib.points.x(morder(counter)),...
         Calib.mondims.height*Calib.points.y(morder(counter)),...
         'o','MarkerEdgeColor',Calib.altcolor,'MarkerFaceColor',Calib.altcolor ,'MarkerSize',ms);
    
    changeT = GetSecs;
    drawnow;

    %STORING DATA
    changetimestamps = list{'Timestamps'}{'Change'};
    changetimestamps(counter) = changeT;
    list{'Timestamps'}{'Change'} = changetimestamps; 
end

function feedback(list)
    %Import UI and ReactionWindow
    ui = list{'Input'}{'Controller'};
    rtwindow = list{'Change'}{'ReactionWindow'};
    
    %Find this current trial iteration
    counter = list{'Calib'}{'Counter'};
    
    %Import vital variables
    changetimestamps = list{'Timestamps'}{'Change'};
    Calib = list{'Calib'}{'Calib'};
    morder = list{'Calib'}{'mOrder'};
    donts = list{'Calib'}{'donts'};
    
    %Prepping to plot calib point  
    Calib.mondims = Calib.mondims1;
    ms = Calib.BigMark; 
    
    axes('Visible', 'off', 'Units', 'normalize','Position', [0 0 1 1],'DrawMode','fast','NextPlot','replacechildren');
    xlim([1,Calib.mondims.width]); 
    ylim([1,Calib.mondims.height]);
    axis ij;
    set(gca,'xtick',[]);
    set(gca,'ytick',[]);
    
    responseT = -1; %Initialize response time as something inviable
    
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
                 
                 clf;
                     axes('Visible', 'off', 'Units', 'normalize','Position', [0 0 1 1],'DrawMode','fast','NextPlot','replacechildren');
                     xlim([1,Calib.mondims.width]); 
                     ylim([1,Calib.mondims.height]);
                     axis ij;
                     set(gca,'xtick',[]);
                     set(gca,'ytick',[]); 
                 text(Calib.mondims.width*Calib.points.x(morder(counter)),...
                     Calib.mondims.height*Calib.points.y(morder(counter)), RT,...
                     'HorizontalAlignment', 'center', 'Color', [1 1 1],...
                     'FontSize', 24, 'FontName', 'Calibri');
                 
                 drawnow;
                 pause(1);
            end
            
    end
    clf %clears plots for next trial
    
    % STORE DATA
    rtimes = list{'Output'}{'RT'};
    rtimes(counter) = responseT;
    list{'Output'}{'RT'} = rtimes;
end

function openfig(list)
    
    %Get Calib parameters
    Calib = list{'Calib'}{'Calib'};
    
    %Get matlab figure
    figH = figure('menuBar','none','name','Calibrate','Color', Calib.bkcolor,'Renderer', 'Painters');
    axes('Visible', 'off', 'Units', 'normalize','Position', [0 0 1 1],'DrawMode','fast','NextPlot','replacechildren');
    Calib.mondims = Calib.mondims1;
    set(figH,'position',[Calib.mondims.x Calib.mondims.y Calib.mondims.width Calib.mondims.height]);
    xlim([1,Calib.mondims.width]); 
    ylim([1,Calib.mondims.height]);
    axis ij;
    set(gca,'xtick',[]);
    set(gca,'ytick',[]); 
end