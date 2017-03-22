% Make a root with the readout task and configure.
%   pick subject, motion direction(s)
global ROOT_STRUCT

% who!
% select directions for training or for testing

% subject = 'Ling';
%%dirs = [90 90 90 90 15 -40 165 220]-65;
% dirs = [25];
% dirInc = 10;
%dirStd = [40];
%%dirStd = [10 40 40 40 20 40 40 40 60 40 40 40 80 40 40 40];
%probeDir = nan; 
%probeDir = [-120 -80 -50 -30 -10 0 10 30 50 80 120 180] + dirs
%viewingTime = 350;

% subject = 'BenH4';
% dirs = [90 90 90 90 15 -40 165 220]-65;
% dirs = [25];
% dirInc = 10;
% dirStd = 80;
% dirStd = [20 80 80 80 40 80 80 80 120 80 80 80 160 80 80 80];
% probeDir = nan;
% probeDir = [-135 -90 -60 -30 -10 0 10 30 60 90 135 180] + dirs
% viewingTime = 350;

subject = 'Matt5';
% dirs = [90 90 90 90 15 -40 165 220]-65;
dirs = [25];
dirInc = 10;
dirStd = 60;
% dirStd = [20 60 60 60 40 60 60 60 80 60 60 60 100 60 60 60] 
probeDir = nan; 
% probeDir = [-130 -100 -70 -40 -10 0 10 40 70 100 130 180] + dirs
viewingTime = 350;

numTrials = 168;  % training and testing
% numTrials = 100;  % reference ;
% numTrials = 144;  % probeDir = ~nan;
% numTrials = 128;    % change representations

% select all the response bias tasks
%   pass args for repetitions and stimulus orientations
tL = { ...
    'taskReadout', 3, {dirs, dirInc, dirStd, probeDir, numTrials, viewingTime}, ...
    };
 
% init and set dXparadigm.screenMode to same
sMode = 'remote';
rInit(sMode);

% add with fiels customized to subject's name
pName = ['readout_', subject];

% dXparadigm/runTasks will bomb if dir doesn't exist.
FIRADir = ['/Users/lab/GoldLab/Data/readout/', subject];
if exist(FIRADir) ~=7
    mkdir(FIRADir)
end

% configure paradigm with task helpers, randomize tasks, etc.
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


rAdd('dXparadigm',      1,  ...
    'name',                 pName, ...
    'screenMode',           sMode, ...
    'taskList',             tL, ...
    'taskOrder',            'blockTasks', ...
    'FIRA_saveDir',         FIRADir, ...
    'FIRA_filenameBase',    subject, ...
    'saveToFIRA',           true, ...
    'FIRA_doWrite',         true, ...
    'iti',                  0.5, ...
    'moreFeedbackFunction', @readoutFeedback, ...
    'showFeedback',         true, ...
    'feedbackSelect',       feedbackSelect)

% load all tasks
ROOT_STRUCT.dXparadigm = loadTasks(ROOT_STRUCT.dXparadigm);

bigName = fullfile(rGet('dXparadigm', 1, 'ROOT_saveDir'), pName);
if exist(bigName)
    save(bigName, 'ROOT_STRUCT', '-append');
else
    save(bigName, 'ROOT_STRUCT');
end

rDone
clear all