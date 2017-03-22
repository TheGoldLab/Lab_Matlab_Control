function common_paradigm_sets
% a quick way to call some sets on dXparadigm, for all of the Nachmias
% tasks.

global ROOT_STRUCT

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

% swawp around the task order
tL = get(ROOT_STRUCT.dXparadigm, 'taskList');
tP = get(ROOT_STRUCT.dXparadigm, 'taskProportions');

% shuffle the first and second halves
% maybe swap the first and second halves
n = length(tL);
switcheroo = [randperm(n/2), randperm(n/2)+(n/2)];

% swap dots and contrast chunks?
% if rand > 0.5
%     switcheroo = fliplr(switcheroo);
% end

tL = tL(switcheroo);
tP = tP(switcheroo);
ROOT_STRUCT.dXtask = ROOT_STRUCT.dXtask(switcheroo);

% % for a debugging
% for tt = 1:length(tL)
%     rSet('dXtask', tt, 'blockReps', 1)
% end

% set changes to paradigm
rSet('dXparadigm', 1, ...
    'taskList',             tL, ...
    'taskProportions',      tP, ...
    'taski',                switcheroo(1), ...
    'saveToFIRA',           true, ...
    'FIRA_doWrite',         true, ...
    'iti',                  1, ...
    'moreFeedbackFunction', @previewFeedback, ...
    'showFeedback',         true, ...
    'feedbackSelect',       feedbackSelect);

% show the changes to paradigm
p = findobj('Tag', 'paradigmFigure');
if ~isempty(p)
    handles = guidata(p);
    dXparadigmGUI('bonusMagnus_Callback', handles.bonusMagnus, [], handles);
end

g = findobj('Name', 'dXgui');
if ~isempty(g)
    handles = guidata(g);
    dXGUI_sync(handles);
    drawnow
end