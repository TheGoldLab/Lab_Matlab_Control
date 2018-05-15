function RTDconfigureStateMachine(datatub)
% function RTDconfigureStateMachine(datatub)
%
% RTD = Response-Time Dots
%
% Configure state machine (flow control)
%
% Inputs:
%  datatub ... tub o' data
%
% 5/11/18 written by jig

%% ---- Collect convenient variables, etc
% The screen and drawable objects
stimulusEnsemble = datatub{'Graphics'}{'stimulusEnsemble'};
feedbackEnsemble = datatub{'Graphics'}{'feedbackEnsemble'};
screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};
sis = datatub{'Graphics'}{'stimulus inds'};

% The user-interface object
ui = datatub{'Control'}{'ui'};
kb = datatub{'Control'}{'keyboard'};

% Fevalables for state list
blanks = {@callObjectMethod, screenEnsemble, @blank};
chkuif = {@getNextEvent ui false {'holdFixation'}};
chkuib = {@getNextEvent ui false {'brokeFixation'}};
chkuic = {@getNextEvent ui false {'choseLeft' 'choseRight'}};
chkkbd = {@getNextEvent kb false {'done' 'pause' 'quit' 'calibrate'}};
showfx = {@RTDsetVisible, stimulusEnsemble, sis(1), sis(2:3), datatub, 'fixOn'};
showt  = {@RTDsetVisible, stimulusEnsemble, sis(2), [], datatub, 'targsOn'}; 
showd  = {@RTDsetVisible, stimulusEnsemble, sis(3), []}; 
hided  = {@RTDsetVisible, stimulusEnsemble, [], sis([1 3]), datatub, 'dotsOff'};
showfb = {@RTDsetVisible, feedbackEnsemble, [], [], datatub, 'fdbkOn'};
abrt   = {@RTDabort, datatub};
calpl  = {@calibrate, ui};
sch    = @(x)cat(2, {@RTDsetChoice, datatub}, x);
fg     = @(x,y,z){@RTDsetGazeWindow, ui, x, y, z};
gwfxw  = fg('fpWindow', false, true);
gwfxh  = fg('fpWindow', true, true);
gwts   = fg({'fpWindow' 't1Window' 't2Window'}, [false false false], [false true false]);
t      = true; % for readabilty below
f      = false;

% Timing variables
tft = datatub{'Timing'}{'fixationTimeout'};
tfh = datatub{'Timing'}{'holdFixation'};
dtt = datatub{'Timing'}{'dotsTimeout'};
tsf = datatub{'Timing'}{'showFeedback'};
iti = datatub{'Timing'}{'InterTrialInterval'};

%% ---- Make the state machine
trialStates = {...
   'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
   'showFixation'      showfx   {}       0          {}      'waitForFixation' ; ...
   'waitForFixation'   gwfxw    chkuif   tft        {}      'done'            ; ...
   'holdFixation'      gwfxh    chkuib   tfh        {}      'showTargets'     ; ...   
   'showTargets'       showt    chkuib   1          gwts    'showDots'        ; ...   
   'showDots'          showd    chkuic   dtt        hided   'noChoice'        ; ...   
   'brokeFixation'     sch(-2)  {}       0          {}      'blank'           ; ...
   'noChoice'          sch(-1)  {}       0          {}      'blank'           ; ...
   'choseLeft'         sch( 0)  {}       0          {}      'blank'           ; ...
   'choseRight'        sch( 1)  {}       0          {}      'blank'           ; ...
   'blank'             {}       {}       0.2        blanks  'showFeedback'    ; ...   
   'showFeedback'      showfb   {}       tsf        blanks  'done'            ; ...
   'done'              {}       chkkbd   iti        {}       ''               ; ...   
   'pause'             {}       chkkbd   inf        {}       ''               ; ...   
   'calibrate'         calpl    chkkbd   0          {}       ''               ; ...   
   'quit'              abrt     {}       0          {}       ''               ; ...   
   };
   
%% ---- Put stuff together in a stateMachine so that it will run
stateMachine = topsStateMachine();
stateMachine.addMultipleStates(trialStates);
stateMachine.startFevalable = {@RTDstartTrial, datatub};
stateMachine.finishFevalable = {@RTDfinishTrial, datatub};
datatub{'Control'}{'stateMachine'} = stateMachine;

%% ---- Make a concurrent composite to interleave run calls
stateMachineComposite = topsConcurrentComposite('stateMachine Composite');
stateMachineComposite.addChild(stateMachine);
stateMachineComposite.addChild(stimulusEnsemble, false);
stateMachineComposite.addChild(screenEnsemble, false);

%% ---- Set up ensemble activation list. See activateEnsemblesByState for details.
activeList = {{stimulusEnsemble, screenEnsemble}, {'showDots'}};
stateMachine.addSharedFevalableWithName( ...
   {@activateEnsemblesByState stateMachineComposite activeList}, ...
   'activateEnsembles', 'entry');

%% ---- Save the topsConcurrentComposite
datatub{'Control'}{'stateMachineComposite'} = stateMachineComposite;

