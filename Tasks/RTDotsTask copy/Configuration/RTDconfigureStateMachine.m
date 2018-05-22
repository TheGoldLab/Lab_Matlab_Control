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
screenEnsemble   = datatub{'Graphics'}{'screenEnsemble'};
stimulusEnsemble = datatub{'Graphics'}{'stimulusEnsemble'};
sis              = datatub{'Graphics'}{'stimulus inds'};
textEnsemble     = datatub{'Graphics'}{'textEnsemble'};
tis              = datatub{'Graphics'}{'text inds'};

% The user-interface object
ui = datatub{'Control'}{'ui'};
kb = datatub{'Control'}{'keyboard'};

% Fevalables for state list
blanks = {@callObjectMethod, screenEnsemble, @blank};
chkuif = {@getNextEvent, ui, false, {'holdFixation'}};
chkuib = {@getNextEvent, ui, false, {'brokeFixation'}};
chkuic = {@RTDgetAndSaveNextEvent, datatub, {'choseLeft' 'choseRight'}, 'choice'};
chkkbd = {@getNextEvent kb, false, {'done' 'pause' 'calibrate' 'skip' 'quit'}};
showfx = {@RTDsetVisible, stimulusEnsemble, sis(1), sis(2:3), datatub, 'fixOn'};
showt  = {@RTDsetVisible, stimulusEnsemble, sis(2), [], datatub, 'targsOn'}; 
showd  = {@RTDsetVisible, stimulusEnsemble, sis(3), [], datatub, 'dotsOn'}; 
hided  = {@RTDsetVisible, stimulusEnsemble, [], sis([1 3]), datatub, 'dotsOff'};
showfb = {@RTDsetVisible, textEnsemble, tis(1), [], datatub, 'fdbkOn'};
abrt   = {@RTDabortExperiment, datatub};
skip   = {@RTDabortTask, datatub};
calpl  = {@RTDcalibratePupilLabs, datatub};
sch    = @(x)cat(2, {@RTDsetChoice, datatub}, x);
fg     = @(x,y,z){@RTDsetGazeWindow, ui, x, y, z};
gwfxw  = fg({'fpWindow' 't1Window' 't2Window'}, [false false false], [true false false]);
gwfxh  = fg('fpWindow', true, true);
gwts   = fg({'fpWindow' 't1Window' 't2Window'}, [false false false], [false true true]);

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
   'waitForFixation'   gwfxw    chkuif   tft        {}      'blankNoFeedback' ; ...
   'holdFixation'      gwfxh    chkuib   tfh        {}      'showTargets'     ; ...   
   'showTargets'       showt    chkuib   1          gwts    'preDots'         ; ...   
   'preDots'           {}       {}       0          {}      'showDots'        ; ...
   'showDots'          showd    chkuic   dtt        hided   'noChoice'        ; ...
   'brokeFixation'     sch(-2)  {}       0          {}      'blank'           ; ...
   'noChoice'          sch(-1)  {}       0          {}      'blank'           ; ...
   'choseLeft'         sch( 0)  {}       0          {}      'blank'           ; ...
   'choseRight'        sch( 1)  {}       0          {}      'blank'           ; ...
   'blank'             {}       {}       0.2        blanks  'showFeedback'    ; ...   
   'showFeedback'      showfb   {}       tsf        blanks  'done'            ; ...
   'blankNoFeedback'   {}       {}       0          blanks  'done'            ; ...      
   'done'              {}       chkkbd   iti        {}      ''                ; ...   
   'pause'             {}       chkkbd   inf        {}      ''                ; ...   
   'calibrate'         calpl    {}       0          {}      ''                ; ...   
   'skip'              skip     {}       0          {}      ''                ; ...
   'quit'              abrt     {}       0          {}      ''                ; ...   
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
stateMachineComposite.addChild(stimulusEnsemble);
stateMachineComposite.addChild(screenEnsemble);

%% ---- Set up ensemble activation list. See activateEnsemblesByState for details.
% Note that the predots state is what allows us to get a good timestamp
%   of the dots onset... we start the flipping before, so the dots will start
%   as soon as we send the isVisible command in the entry fevalable of showDots
activeList = {{stimulusEnsemble, 'draw'; screenEnsemble, 'flip'}, ...
    {'preDots' 'showDots'}};
stateMachine.addSharedFevalableWithName( ...
   {@activateEnsemblesByState activeList}, 'activateEnsembles', 'entry');

%% ---- Save the topsConcurrentComposite
datatub{'Control'}{'stateMachineComposite'} = stateMachineComposite;

