function RTDconfigureSaccadeStateMachine(datatub)
% function RTDconfigureSaccadeStateMachine(datatub)
%
% RTD = Response-Time Dots
%
% Configure state machine (flow control) for VS and MGS saccade tasks
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
stimulusEnsemble = datatub{'Graphics'}{'saccadeStimuliEnsemble'};
sis              = datatub{'Graphics'}{'saccadeStimuli inds'};
textEnsemble     = datatub{'Graphics'}{'textEnsemble'};
tis              = datatub{'Graphics'}{'text inds'};

% The user-interface object
ui = datatub{'Control'}{'ui'};
kb = datatub{'Control'}{'keyboard'};

% Fevalables for state list
blanks = {@callObjectMethod, screenEnsemble, @blank};
chkuif = {@getNextEvent, ui, false, {'holdFixation'}};
chkuib = {@getNextEvent, ui, false, {'brokeFixation'}};
chkuic = {@RTDgetAndSaveNextEvent, datatub, {'choseTarget'}, 'choice'};
chkkbd = {@getNextEvent kb, false, {'done' 'pause' 'calibrate' 'skip' 'quit'}};
showfx = {@RTDsetVisible, stimulusEnsemble, sis(1), sis(2), datatub, 'fixOn'};
showt  = {@RTDsetVisible, stimulusEnsemble, sis(2), [], datatub, 'targOn'};
hidet  = {@RTDsetVisible, stimulusEnsemble, [], sis(2), datatub, 'targOff'};
hidefx = {@RTDsetVisible, stimulusEnsemble, [], sis(1), datatub, 'fixOff'};
showfb = {@RTDsetVisible, textEnsemble, tis(1), [], datatub, 'fdbkOn'};
abrt   = {@RTDabortExperiment, datatub};
skip   = {@RTDabortTask, datatub};
calpl  = {@calibrate, ui};
sch    = @(x)cat(2, {@RTDsetSaccadeChoice, datatub}, x);
sgw    = @dotsReadableEye.setGazeWindows;
gwfxw  = {sgw, ui, {'fpWindow', 'isActive', true}};
gwfxh  = {sgw, ui, {'fpWindow', 'isInverted', true, 'setToGaze', true}};
gwt    = {sgw, ui, {'fpWindow', 'isActive', false}, {'tcWindow', 'isActive', true}};

% Timing variables
tft = datatub{'Timing'}{'fixationTimeout'};
tfh = datatub{'Timing'}{'holdFixation'};
vtd = datatub{'Timing'}{'VGSTargetDuration'};
mtd = datatub{'Timing'}{'MGSTargetDuration'};
mdd = datatub{'Timing'}{'MGSDelayDuration'};
sto = datatub{'Timing'}{'saccadeTimeout'};
tsf = datatub{'Timing'}{'showFeedback'};
iti = datatub{'Timing'}{'InterTrialInterval'};

%% ---- Make the state machine
%
% Note that the startTrial routine sets the target location and the 'next'
% state after holdFixation, based on VGS vs MGS task
trialStates = {...
   'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
   'showFixation'      showfx   {}       0          {}      'waitForFixation' ; ...
   'waitForFixation'   gwfxw    chkuif   tft        {}      'blankNoFeedback' ; ...
   'holdFixation'      gwfxh    chkuib   tfh        {}      'showTarget'      ; ... % Branch here
   'VGSshowTarget'     showt    chkuib   vtd        gwt     'hideFix'         ; ... % VGS
   'MGSshowTarget'     showt    chkuib   mtd        {}      'MGSdelay'        ; ... % MGS
   'MGSdelay'          hidet    chkuib   mdd        gwt     'hideFix'         ; ...
   'hideFix'           hidefx   chkuic   sto        {}      'noChoice'        ; ...    
   'brokeFixation'     sch(-2)  {}       0          {}      'blank'           ; ...
   'noChoice'          sch(-1)  {}       0          {}      'blank'           ; ...
   'choseTarget'       sch( 1)  {}       0          {}      'blank'           ; ...
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
saccadeStateMachine = topsStateMachine();
saccadeStateMachine.addMultipleStates(trialStates);
saccadeStateMachine.startFevalable = {@RTDstartTrial, datatub};
saccadeStateMachine.finishFevalable = {@RTDfinishTrial, datatub};

% For debugging
%saccadeStateMachine.addSharedFevalableWithName( ...
%   {@showStateInfo}, 'debugStates', 'entry');

%% ---- Make a concurrent composite to interleave run calls
saccadeStateMachineComposite = topsConcurrentComposite('stateMachine Composite');
saccadeStateMachineComposite.addChild(saccadeStateMachine);

%% ---- Save the stateMachine and Composite in the tub
datatub{'Control'}{'saccadeStateMachine'} = saccadeStateMachine;
datatub{'Control'}{'saccadeStateMachineComposite'} = saccadeStateMachineComposite;
