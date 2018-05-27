function RTDconfigureDotsStateMachine(datatub)
% function RTDconfigureDotsStateMachine(datatub)
%
% RTD = Response-Time Dots
%
% Configure state machine (flow control)
%
% Inputs:
%  datatub ... tub o' data
%
% PUts in the datatub:
%  dotsStateMachine          ... the state machine
%  dotsStateMachineComposite ... the state machine plus screen and stimulus
%                                   ensembles to run concurrently
% 
% 5/11/18 written by jig

%% ---- Collect convenient variables, etc
% The screen and drawable objects
screenEnsemble   = datatub{'Graphics'}{'screenEnsemble'};
stimulusEnsemble = datatub{'Graphics'}{'dotsStimuliEnsemble'};
sis              = datatub{'Graphics'}{'dotsStimuli inds'};
textEnsemble     = datatub{'Graphics'}{'textEnsemble'};
tis              = datatub{'Graphics'}{'text inds'};

% The user-interface objects
ui = datatub{'Control'}{'userInputDevice'};
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
abrtf  = @(x)abort(datatub{'Control'}{x});
abrt   = {abrtf, 'mainTask'};
skip   = {abrtf 'currentTask'};
calpl  = {@calibrate, ui};
sch    = @(x)cat(2, {@RTDsetDotsChoice, datatub}, x);
dce    = @defineCompoundEvent;
gwfxw  = {dce, ui, {'fpWindow', 'isActive', true}};
gwfxh  = {dce, ui, {'fpWindow', 'isInverted', true}};
gwts   = {dce, ui, {'fpWindow', 'isActive', false}, ...
    {'t1Window', 'isActive', true}, {'t2Window', 'isActive', true}};

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
dotsStateMachine = topsStateMachine();
dotsStateMachine.addMultipleStates(trialStates);
dotsStateMachine.startFevalable = {@RTDstartTrial, datatub};
dotsStateMachine.finishFevalable = {@RTDfinishTrial, datatub};

% Set up ensemble activation list. See activateEnsemblesByState for details.
% Note that the predots state is what allows us to get a good timestamp
%   of the dots onset... we start the flipping before, so the dots will start
%   as soon as we send the isVisible command in the entry fevalable of showDots
activeList = {{stimulusEnsemble, 'draw'; screenEnsemble, 'flip'}, ...
   {'preDots' 'showDots'}};
dotsStateMachine.addSharedFevalableWithName( ...
   {@activateEnsemblesByState activeList}, 'activateEnsembles', 'entry');

%% ---- Make a concurrent composite to interleave run calls
dotsStateMachineComposite = topsConcurrentComposite('stateMachine Composite');
dotsStateMachineComposite.addChild(dotsStateMachine);
dotsStateMachineComposite.addChild(stimulusEnsemble);
dotsStateMachineComposite.addChild(screenEnsemble);

%% ---- Save the stateMachine and Composite in the tub
datatub{'Control'}{'dotsStateMachine'} = dotsStateMachine;
datatub{'Control'}{'dotsStateMachineComposite'} = dotsStateMachineComposite;
