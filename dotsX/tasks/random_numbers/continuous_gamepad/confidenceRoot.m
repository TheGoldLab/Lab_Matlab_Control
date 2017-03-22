% Make a root for the continuous/gamepad random numbers task
%   pick subject, ans sub-blick sizes
global ROOT_STRUCT

% who!
subject = 'test';
blockSD = [30 20 10];
numBlocks = length(blockSD);
%mean sublock size for each block minus 5
mSbs   = [20 20 20] 


% Reset estimate bar to alpha of .5?
half = false
% cue subjects to changes?
cue  = false

% select all the response modality tasks
%   pass args for repetitions and stimulus orientations
tL = { ...
    'taskRandomConfidence', numBlocks, {blockSD, mSbs, half, cue} ...
    };

% init and set dXparadigm.screenMode to same
sMode = 'remote';
rInit(sMode);

% add with fields customized to subject's name
pName = ['random_confidence_', subject];

% place to save data
FIRADir = ...
    ['/Users/lab/GoldLab/Data/random_numbers/confidence/', subject];
if exist(FIRADir) ~=7
    mkdir(FIRADir)
end

% where to put the output of this file, for loading later
ROOTDir = ['/Users/lab/GoldLab/Data/random_numbers/confidence/', subject];
if ~exist(ROOTDir, 'dir')
    mkdir(ROOTDir)
end

% show wha t feedback?
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

rAdd('dXparadigm',          1, ...
    'name',                 pName, ...
    'screenMode',           sMode, ...
    'taskList',             tL, ...
    'taskOrder',            'randomTaskByBlock', ...
    'FIRA_saveDir',         FIRADir, ...
    'FIRA_filenameBase',    ['R', subject], ...
    'saveToFIRA',           true, ...
    'FIRA_doWrite',         true, ...
    'ROOT_saveDir',         ROOTDir, ...
    'iti',                  .1, ...
    'moreFeedbackFunction', @randomFeedback, ...
    'showFeedback',         true, ...
    'feedbackSelect',       feedbackSelect);

% load all tasks (which makes equal proportons) then set proportions
ROOT_STRUCT.dXparadigm = loadTasks(ROOT_STRUCT.dXparadigm);
rDone;

bigName = fullfile(rGet('dXparadigm', 1, 'ROOT_saveDir'), pName);
if exist(bigName)
    save(bigName, 'ROOT_STRUCT', '-append');
else
    save(bigName, 'ROOT_STRUCT');
end

clear all