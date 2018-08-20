function [overtask, list] = CalibrationTAsk(iter, donts)
%% Calibration Task
%Display calibration dots, change color predictably, and then get reaction
%time.

%% Housekeeping
%Setting up the screen
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 2); %change display index to 0 for debug. 1 for full screen. Use >1 for external monitors.
sc.reset('backgroundColor', [0 0 0]);

%Call GetSecs just to load up the Mex files for getting time, so no delays
%later
GetSecs;

%% List
%Creating list object that can be referenced by my functions
list = topsGroupedList();

%Setting important values
    rtwindow = 0.5;
    changetime = 0.5; %dictates time to color change, in seconds.

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

    Calib.points.x = [0.1 0.1 0.1 0.5 0.5 0.5 0.9 0.9 0.9];  % X coordinates in [0,1] coordinate system 
    Calib.points.y = [0.1 0.5 0.9 0.1 0.5 0.9 0.1 0.5 0.9];  % Y coordinates in [0,1] coordinate system 
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

    list{'Calib'}{'Counter'} = 0; %Starts a counter for the task
    list{'Calib'}{'Calib'} = Calib;
    list{'Calib'}{'mOrder'} = mOrder;
    list{'Calib'}{'iter'} = iter;
    list{'Calib'}{'donts'} = donts;
    
    list{'Change'}{'ReactionWindow'} = rtwindow; %Time in seconds allowed to make decision
    list{'Change'}{'ChangeTime'} = changetime; %Time to color change
    
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
    
%%  Graphics

    %Target point
    target = dotsDrawableTargets();
    target.xCenter = 0;
    target.yCenter = 0; %Snowdots coordinates (0,0) are in the screen center
    target.colors = Calib.fgcolor;
    target.width = 34;
    target.height = 1;
    target.isVisible = false;
    
    %Cursor point
    cursor = dotsDrawableTargets();
    cursor.xCenter = 0;
    cursor.yCenter = 0;
    cursor.colors = Calib.fgcolor2;
    cursor.width = 0.3;
    cursor.height = 0.3;
    target.isVisible = false;
 
 %ENSEMBLE
    
    %Graphical ensemble
    ensemble = dotsEnsembleUtilities.makeEnsemble('Fixation Point', false);
    targInd = ensemble.addObject(target);
    cursorInd = ensemble.addObject(cursor);
    
    list{'Graphics'}{'Ensemble'} = ensemble;
    list{'Graphics'}{'CursorInd'} = cursorInd;
    list{'Graphics'}{'TargetInd'} = targInd;
    
    % tell the ensembles how to draw a frame of graphics
    %   the static drawFrame() takes a cell array of objects
    ensemble.automateObjectMethod(...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

%SCREEN
% 
%     % also put dotsTheScreen into its own ensemble
%     screen = dotsEnsembleUtilities.makeEnsemble('screen', false);
%     screen.addObject(dotsTheScreen.theObject());
% 
%     % automate the task of flipping screen buffers
%     screen.automateObjectMethod('flip', @nextFrame);

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

    %Anonymous functions for useful shorthand
    show = @(index) ensemble.setObjectProperty('isVisible', true, index); %show asset
    hide = @(index) ensemble.setObjectProperty('isVisible', false, index); %hide asset
    change = @(index) ensemble.setObjectProperty('colors', Calib.altcolor, index);
    changeback = @(index) ensemble.setObjectProperty('colors', Calib.fgcolor2, index);

calibList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'Draw', {@calibpoint list}, {}, {}, 1, 'Change';
                 'Change', {@changeup list}, {}, {}, 0, 'Feedback';
                 'Feedback', {@feedback list}, {}, {}, 3, '';};
Machine.addMultipleStates(calibList);

%Concurrent Composite
contask = topsConcurrentComposite();
%contask.addChild(ensemble);
contask.addChild(Machine);
contask.addChild(readui);

%Main task tree
maintask = topsTreeNode();
maintask.startFevalable = {@openfig, list};
maintask.iterations = 9;
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
            
    drawnow;
                        
end



function changeup(list)
   %Find this current trial iteration
    counter = list{'Calib'}{'Counter'};
    
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
         'o','MarkerEdgeColor',Calib.altcolor,'MarkerFaceColor',Calib.altcolor ,'MarkerSize',ms);
            
    drawnow;
    
    %Tell Tobii that the drawn points are points that the subject is
    %looking at. 
    tetio_addCalibPoint(Calib.points.x(morder(counter)),Calib.points.y(morder(counter)));

end

function feedback(list)
    %Import UI and ReactionWindow
    ui = list{'Input'}{'Controller'};
    rtwindow = list{'Change'}{'ReactionWindow'};
    
    %Find this current trial iteration
    counter = list{'Calib'}{'Counter'};
    
    %Import vital variables
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
    
    tic
    while toc < rtwindow
            read(ui);
            [a, b, eventname, d] = ui.getHappeningEvent();
            if ~isempty(eventname)
                plot(Calib.mondims.width*Calib.points.x(morder(counter)),...
                     Calib.mondims.height*Calib.points.y(morder(counter)),...
                     'o','MarkerEdgeColor',Calib.feedcolor,'MarkerFaceColor',Calib.feedcolor ,'MarkerSize',ms);
            
                      drawnow;
            end
            
    end
    clf %clears plots for next trial
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