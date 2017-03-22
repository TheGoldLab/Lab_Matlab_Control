function randomRoot(subject)
% Make a root for the random numbers task with some setup crap.  This is
% easier than selecting the task with the gui all the time and changing
% fields one at a time.  Especially when task or class definition changes!!
global ROOT_STRUCT

if ~nargin || isempty(subject) ||~ischar(subject)
    disp('Subject, Tzvetomir.')
    return
end

% select all the response modality tasks
tL = { ...
    'taskRandomNumbers', ...
    };

% init and set dXparadigm.screenMode to same
sMode = 'remote';
rInit(sMode);

% add with fields customized to subject's name
pName = [subject, '_Random'];

% dXparadigm/runTasks will bomb if dir doesn't exist.
FIRADir = ['/Users/lab/GoldLab/Data/random_numbers/', subject];
if exist(FIRADir) ~=7
    mkdir(FIRADir)
end

rAdd('dXparadigm',      1, ...
    'name',             pName, ...
    'screenMode',       sMode, ...
    'taskList',         tL, ...
    'taskOrder',        'randomTaskByTrial', ...
    'FIRA_saveDir',     FIRADir, ...
    'FIRA_filenameBase', ['R', subject]);

% load all tasks (which makes equal proportons) then set proportions
ROOT_STRUCT.dXparadigm = loadTasks(ROOT_STRUCT.dXparadigm);

% configure paradigm with task helpers, randomize tasks, etc
random_paradigm_sets;

bigName = fullfile(rGet('dXparadigm', 1, 'ROOT_saveDir'), pName);
if exist(bigName)
    save(bigName, 'ROOT_STRUCT', '-append');
else
    save(bigName, 'ROOT_STRUCT');
end

clear all