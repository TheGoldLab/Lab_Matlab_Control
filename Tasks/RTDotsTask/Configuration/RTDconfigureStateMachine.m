function RTDconfigureStateMachine(datatub)
% function RTDconfigureStateMachine(datatub)
%
% RTD = Response-Time Dots
%
% Configure state machine (flow control)
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
chkuic = {@getNextEvent ui false {'choseLeft' 'choseRight'}};
chkuif = {@getNextEvent ui false {'holdFixation'}};
chkkbd = {@getNextEvent kb false {'done' 'pause' 'quit'}};
waitf  = {@RTDsetVisible, stimulusEnsemble, sis(1), sis(2:3), datatub, 'fixOn'};
showt  = {@RTDsetVisible, stimulusEnsemble, sis(2), [], datatub, 'targsOn'}; 
showd  = {@RTDsetVisible, stimulusEnsemble, sis(3), []}; 
hided  = {@RTDsetVisible, stimulusEnsemble, [], sis([1 3]), datatub, 'dotsOff'};
showf  = {@RTDsetVisible, feedbackEnsemble, [], [], datatub, 'fdbkOn'};
sch    = @(x)cat(2, {@RTDsetChoice, datatub}, x);
abrt   = {@RTDabort, datatub};

% Timing variables
tft = datatub{'Timing'}{'fixationTimeout'};
tfh = datatub{'Timing'}{'holdFixation'};
dtt = datatub{'Timing'}{'dotsTimeout'};
tsf = datatub{'Timing'}{'showFeedback'};
iti = datatub{'Timing'}{'InterTrialInterval'};

%% ---- Make the state machine
trialStates = {...
   'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
   'waitForFixation'   waitf    chkuif   tft        {}      'done'            ; ...
   'holdFixation'      {}       chkuic   tfh        {}      'showTargets'     ; ...   
   'showTargets'       showt    chkuic   1          {}      'showDots'        ; ...   
   'showDots'          showd    chkuic   dtt        hided   'noChoice'        ; ...   
   'brokeFixation'     sch(-2)  {}       0          {}      'blank'           ; ...
   'noChoice'          sch(-1)  {}       0          {}      'blank'           ; ...
   'choseLeft'         sch( 0)  {}       0          {}      'blank'           ; ...
   'choseRight'        sch( 1)  {}       0          {}      'blank'           ; ...
   'blank'             {}       {}       0.2        blanks  'showFeedback'    ; ...   
   'showFeedback'      showf    {}       tsf        blanks  'done'            ; ...
   'done'              {}       chkkbd   iti        {}       ''               ; ...   
   'pause'             {}       chkkbd   inf        {}       ''               ; ...   
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

