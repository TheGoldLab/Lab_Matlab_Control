% Make a root with many Quest blocks for coarse and fine discrimination
global ROOT_STRUCT

% who!
subject = 'SAM';

% should we add and check the eye tracker?
useASL = false;

% where to show graphics
sMode = 'remote';

trialsPerQuest = 80; %%<--- IMPORTANT NUMBER (~80)

fineCenters = [0,30,60,75,90];                             %+/-10
coarseCenters = [0,30,60,90];                           %+/-90

numFine = length(fineCenters);
numCoarse = length(coarseCenters);

% for practice/lapse trials
practiceTrials      = 6;
overrideProbability = 0.1;

% get enough Quest tasks blocks
tL = { ...
    'taskBiasLever_20Q',  numFine,   {useASL, fineCenters,   trialsPerQuest, practiceTrials}, ...
    'taskBiasLever_180Q', numCoarse, {useASL, coarseCenters, trialsPerQuest, practiceTrials}, ...
    };

% dXparadigm/runTasks will bomb if dir doesn't exist.
FIRADir = sprintf('~/GoldLab/Data/learning_bias/%s/FIRA', subject);
if ~exist(FIRADir)
    mkdir(FIRADir)
end

% where to put the output of this file, for loading later
ROOTDir = sprintf('~/GoldLab/Data/learning_bias/%s/ROOT', subject);
if ~exist(ROOTDir, 'dir')
    mkdir(ROOTDir)
end

% add with fields customized to subject's name
pName = ['learning_bias_', subject];

% init and set up dXparadigm
rInit(sMode);
rAdd('dXparadigm',      1, ...
    'name',             pName, ...
    'screenMode',       sMode, ...
    'taskList',         tL, ...
    'taskOrder',        'blockTasks', ...
    'ROOT_saveDir',     ROOTDir, ...
    'FIRA_saveDir',     FIRADir, ...
    'FIRA_filenameBase', subject);

% load all tasks
ROOT_STRUCT.dXparadigm = loadTasks(ROOT_STRUCT.dXparadigm);

% configure paradigm with task helpers, randomize tasks, etc.
bias_paradigm_sets;

bigName = fullfile(rGet('dXparadigm', 1, 'ROOT_saveDir'), ...
    [subject datestr(rGet('dXparadigm', 'sessionTime'), 30) 'R']);
if exist(bigName)
    save(bigName, 'ROOT_STRUCT', '-append');
else
    save(bigName, 'ROOT_STRUCT');
end

% % for testing:
% try
%     runTasks(ROOT_STRUCT.dXparadigm);
% catch err
%     rDone
%     rethrow(err)
% end

rDone
clear