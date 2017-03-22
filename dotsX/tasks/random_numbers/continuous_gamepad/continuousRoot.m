% Make a root for the continuous/gamepad random numbers task
%   pick subject, ans sub-blick sizes
global ROOT_STRUCT

% who!
subject = 'test';
blockSD = [35 25 15 5];    % plug in nan to get noise to be pulled from distribution of possible noises
numBlocks = length(blockSD);
%mean sublock size for each block minus 5
mSbs   = [20 20 20 20];     % when using the Hidden Hazard rate version set to 32

% Reset estimate bar to alpha of .5?
half = false

% Cue subject to changes in sub-Block?
cue = 0

% are you trying to run the version with no blocks that changes hazard rate
% without telling subjects?
HHvar  = 0
% run the version with two independant distributions (cued by color)
twoDist= 0

% select all the response modality tasks
%   pass args for repetitions and stimulus orientations... and variables to
%   specify which version of the task we are running.
tL = { ...
    'taskRandomContinuous', numBlocks, {blockSD, mSbs, half, cue, HHvar, twoDist} ...
    };

% init and set dXparadigm.screenMode to same
sMode = 'remote';
rInit(sMode);

% add with fields customized to subject's name
pName = ['random_continuous_', subject];

% place to save data
FIRADir = ...
    ['/Users/lab/GoldLab/Data/random_numbers/continuous_gamepad/', subject];
if exist(FIRADir) ~=7
    mkdir(FIRADir)
end

% where to put the output of this file, for loading later
ROOTDir = ['/Users/lab/GoldLab/data/random_numbers/continuous_gamepad/', subject];
if ~exist(ROOTDir, 'dir')
    mkdir(ROOTDir)
end

% show what feedback?
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
    'ROOT_saveDir',         ROOTDir, ...
    'saveToFIRA',           true, ...
    'FIRA_writeInterval',   30, ...
    'FIRA_doWrite',         true, ...
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