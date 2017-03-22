% Build a root struct with a dXparadigm and the fine discrimination task
%   pick standard and different directions
clear all
global ROOT_STRUCT

% who is it?
subject = 'Test';

% dot directions and coherence for each subject
%   nan coherence means do QUEST
subs.Test.standard = 90;
subs.Test.different = 87;
subs.Test.coherence = 100;
subs.Test.mouseMode = true;

subs.BSH.standard = 90;
subs.BSH.different = 87;
subs.BSH.coherence = 100;
subs.BSH.mouseMode = false;

subs.BossJIG.standard = 90;
subs.BossJIG.different = 87;
subs.BossJIG.coherence = 100;
subs.BossJIG.mouseMode = false;

% pick screen background color
%   Ball and Sekuler 1982 use 2 cd/m^2 ([1 1 1]*10).
%   Since I'm doing a dark room I'm using about 0.3 cd/m^2.
subs.(subject).bgColor = [1 1 1]*1;

% select fine discrimination task for Eye and Lever
tL = { ...
    'taskFineDiscrimEye', 0, {subs.(subject)}, ...
    'taskFineDiscrimLever', 7, {subs.(subject)}, ...
    };

% init and set dXparadigm.screenMode to same
sMode = 'remote';
rInit(sMode);

% dXparadigm/runTasks will bomb if dir doesn't exist.
FIRADir = ['/Users/lab/GoldLab/Data/fine_discrimination/', subject];
if exist(FIRADir) ~=7
    mkdir(FIRADir)
end

% where to put the output of this file, for loading later
ROOTDir = '/Users/lab/GoldLab/Matlab/mfiles_lab/DotsX/tasks/fine_discrimination/roots';
if ~exist(ROOTDir, 'dir')
    mkdir(ROOTDir)
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

pName = ['fine_discrimination_', subject];
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
    'ROOT_saveDir',         ROOTDir, ...
    'showFeedback',         true, ...
    'feedbackSelect',       feedbackSelect, ...
    'moreFeedbackFunction', @fineFeedback);

% load all tasks and save
ROOT_STRUCT.dXparadigm = loadTasks(ROOT_STRUCT.dXparadigm);
bigName = fullfile(rGet('dXparadigm', 1, 'ROOT_saveDir'), pName);
save(bigName, 'ROOT_STRUCT');

% clean up
rDone
clear all