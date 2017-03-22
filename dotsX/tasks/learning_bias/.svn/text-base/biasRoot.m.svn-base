% Make a root with all the response bias tasks and configure.
%   pick subject, task repetitions, and dot dir for rightward responses
global ROOT_STRUCT

% who!
subject = 'SKR';

% should we add and check the eye tracker?
useASL = false;

% select all the response bias tasks
%   pass args for repetitions and stimulus orientations
tL = { ...
    'taskBiasLever_180P', 0, {useASL}, ...
    'taskBiasLever_180Q', 0, {useASL}, ...
    'taskBiasLever_180C', 0, {useASL}, ...
    'taskBiasLever_20P', 1, {useASL}, ...
    'taskBiasLever_20Q', 1, {useASL}, ...
    'taskBiasLever_20C', 1, {useASL}, ...
    };

% init and set dXparadigm.screenMode to same
sMode = 'remote';
rInit(sMode);

% add with fields customized to subject's name
pName = ['learning_bias_', subject];

% dXparadigm/runTasks will bomb if dir doesn't exist.
FIRADir = sprintf('~/GoldLab/Data/learning_bias/%s/FIRA', subject);
if ~exist(FIRADir)
    mkdir(FIRADir)
end

% where to put the output of this file, for loading later
ROOTDir = sprintf('~/GoldLab/Data/learning_bias/%s/ROOT', subject);
%ROOTDir = '~/GoldLab/Matlab/mfiles_lab/DotsX/tasks/learning_bias/roots';
if ~exist(ROOTDir, 'dir')
    mkdir(ROOTDir)
end

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

rDone
clear all