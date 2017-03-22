% Build a root struct with a dXparadigm and the two FVT modality tasks
%   randomize diagonal dot direction
%   randomize which task is mainstream and which is odd
global ROOT_STRUCT

% who!
subject = 'Test';

% flip two coins
coin = 1 + (rand(1,2)>.5);

% pick dot parameters
angs = [+45, -45];
dot.ang = angs(coin(1));
dot.diam = 6;
dot.y = -7;
dot.x = 0;

% how often to repeat each task?
reps = [1, 5];
eyeReps = reps(coin(2));
leverReps = reps(3-coin(2));

disp(sprintf('"rightward" dots at %.0f deg', dot.ang))
disp(sprintf('%d eye and %d lever blocks', eyeReps, leverReps))

% select all the response modality tasks
%   pass args for repetitions and stimulus orientations
tL = { ...
    'taskModalityFVTEye', eyeReps, {'dotParams', dot}, ...
    'taskModalityFVTLever', leverReps, {'dotParams', dot}, ...
    };

% init and set dXparadigm.screenMode to same
sMode = 'remote';
rInit(sMode);

% dXparadigm/runTasks will bomb if dir doesn't exist.
FIRADir = ['/Users/lab/GoldLab/Data/response_modality/FVT/', subject];
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

pName = [subject, '_ModalityFVT'];
rAdd('dXparadigm',      1, ...
    'name',                 pName, ...
    'screenMode',           sMode, ...
    'taskList',             tL, ...
    'taskOrder',            'randomTaskByBlock', ...
    'iti',                  .5, ...
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
%clear all