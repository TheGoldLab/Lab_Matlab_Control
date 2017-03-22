% load one FIRA and check out the basic session data for writeup.
%   incase I closed the gui before writing in the book

% get new FIRA data or use existing (like, right after a session)
global FIRA ROOT_STRUCT
if isempty(FIRA)
    concatenateFIRAs
else
    disp(FIRA.header.filename)
    FIRA.allHeaders = FIRA.header;
    FIRA.allHeaders.trialSelect = (1:size(FIRA.ecodes.data, 1))';
end
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,50);

% get "correct" ecode, or build it from responses
correct = fixMissingCorrect;

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = FIRA.ecodes.data(:,eGood);

ROOT_STRUCT = FIRA.header.session;
ROOT_STRUCT.screenMode = 0;

tl = rGet('dXparadigm', 1, 'taskList');
disp(sprintf('%s(%d)\n%s(%d)', tl{[1 2 4 5]}));

rGroup('gXmodality_graphics');
place = rGet('dXdots', 1, 'y');
disp(sprintf('placement at %.0f degrees vertical', place))

rGroup('gXmodality_motionControl');
axis = rGet('dXtc', 1, 'values');
disp(sprintf('motion at %.0f, %.0f degrees', axis(1), axis(2)))

for ii = 1:length(tasks)
    taskSelect = taskID == ii & ~isnan(blockNum)';
    t = sum(taskSelect);
    g = sum(good(taskSelect));
    c = sum(correct(taskSelect));
    disp(sprintf('%s\t%d\t%d\t%d', tasks{ii}, t, g, c))
end
taskSelect = ~isnan(taskID);
t = sum(taskSelect);
g = sum(good(taskSelect));
c = sum(correct(taskSelect));
disp(sprintf('%s\t%d\t%d\t%d', 'totaltotaltotal', t, g, c))