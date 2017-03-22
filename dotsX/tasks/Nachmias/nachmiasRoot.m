function nachmiasRoot(subject)
% Make a root with all the NachmiasTasks and some setup crap.  This is
% easier than selecting tasks with the gui all the time and changing fields
% one at a time.  Especially when task or class definitions change!!!!
global ROOT_STRUCT

if ~nargin || isempty(subject) ||~ischar(subject)
    disp('Subject, genius.')
    return
end

% select all the nachmias tasks, separated by contrast and dots
tL = { ...
    'taskDetectDownContrast', ...
    'taskDetectUpContrast', ...
    'taskDiscrim2afcContrast', ...
    'taskDiscrim3afcContrast', ...
    'taskDetectLDots', ...
    'taskDetectRDots', ...
    'taskDiscrim2afcDots', ...
    'taskDiscrim3afcDots', ...
    };

% init and set dXparadigm.screenMode to same
sMode = 'remote';
rInit(sMode);

% add with fields customized to subject's name
pName = [subject, '_Both'];
rAdd('dXparadigm',      1, ...
    'name',             pName, ...
    'screenMode',       sMode, ...
    'taskList',         tL, ...
    'taskProportions',  ones(size(tL)), ...
    'FIRA_saveDir',     ['/Users/lab/GoldLab/Data/', subject], ...
    'FIRA_filenameBase', ['R', subject]);

% load all tasks
ROOT_STRUCT.dXparadigm = loadTasks(ROOT_STRUCT.dXparadigm);

% configure paradigm with task helpers, randomize tasks, etc
common_paradigm_sets;

bigName = fullfile(rGet('dXparadigm', 1, 'ROOT_saveDir'), pName);
if exist(bigName)
    save(bigName, 'ROOT_STRUCT', '-append');
else
    save(bigName, 'ROOT_STRUCT');
end

clear all