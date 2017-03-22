% Build a root struct with a dXparadigm and the two RT modality tasks
%   randomize diagonal dot direction (+/- 45 deg)
%   randomize dot placement (above/below fixation)
%   randomize which task is mainstream and which is odd
global ROOT_STRUCT

% flip three coins: 1 + (rand(1,3)>.5)
coin.Test = 1 + (rand(1,3)>.5);
coin.XL =  [2 1 2];
coin.NKM = [2 1 1];
coin.BMS = [1 1 2];
coin.MAG = [1 1 1];
coin.EAF = [1 2 2];
coin.JIG = [2 2 2];
coin.CC =  [1 2 1];

% who!
subject = 'Test';
c = coin.(subject);
% flip?
c = 3-c;

% pick dot parameters
angs = [+45, -45];
dot.ang = angs(c(1));

dot.diam = 6;
dot.y = 0;
dot.x = 0;
dot.dens = 25;
% place = [-7 +7];
% dot.diam = 8;
% dot.y = place(c(2));

% how often to repeat each task?
reps = [1, 5];
eyeReps = reps(c(3));
leverReps = reps(3-c(3));

disp(subject)
disp(sprintf('"rightward" dots at %.0f deg', dot.ang))
disp(sprintf('placed at %.0f deg', dot.y))
disp(sprintf('%d eye to %d lever', eyeReps, leverReps))

% select all the response modality tasks
%   pass args for repetitions and stimulus orientations
tL = { ...
    'taskModalityRTEye', eyeReps, {'dotParams', dot}, ...
    'taskModalityRTLever', leverReps, {'dotParams', dot}, ...
    };

% init and set dXparadigm.screenMode to same
sMode = 'remote';
rInit(sMode);

% dXparadigm/runTasks will bomb if dir doesn't exist.
FIRADir = ['/Users/lab/GoldLab/Data/response_modality/RT/', subject];
if exist(FIRADir) ~=7
    mkdir(FIRADir)
end

feedbackSelect = { ...
    'showPctGood',      false; ...
    'showNumGood',      false; ...
    'showGoodRate',     false; ...
    'showPctCorrect',   false; ...
    'showNumCorrect',   false; ...
    'showCorrectRate',  false; ...
    'showTrialCount',   false; ...
    'showMoreFeedback', true};
feedbackSelect = cell2struct(feedbackSelect(:,2), feedbackSelect(:,1), 1);

pName = ['ModalityRT_', subject];
rAdd('dXparadigm',      1, ...
    'name',                 pName, ...
    'screenMode',           sMode, ...
    'taskList',             tL, ...
    'taskOrder',            'randomTaskByBlock', ...
    'iti',                  1.0, ...
    'saveToFIRA',           true, ...
    'FIRA_doWrite',         true, ...
    'FIRA_saveDir',         FIRADir, ...
    'FIRA_filenameBase',	subject, ...
    'showFeedback',         true, ...
    'feedbackSelect',       feedbackSelect, ...
    'moreFeedbackFunction', @modalityFeedback);

% load all tasks and save
ROOT_STRUCT.dXparadigm = loadTasks(ROOT_STRUCT.dXparadigm);
bigName = fullfile(rGet('dXparadigm', 1, 'ROOT_saveDir'), pName);
save(bigName, 'ROOT_STRUCT');

% clean up
rDone
clear all