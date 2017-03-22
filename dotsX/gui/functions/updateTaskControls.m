function updateTaskControls(t, handles, isCurrentTask)
% function updateTaskControls(t, handles, isCurrentTask)
%
% Refresh a row of task info controls for dXparadigm GUI.
%   called from GUI functions and dXparadigm methods, hence own file.
%
% In:   t           ... index of a dXtask
%
%       handles     ... handles of dXparadigmGUI instance
%
%       isCurrentTask ... flag to select the task
%
% Out:  bubkis

% 2006 By Benjamin Heasly at University of Pennsylvania

% handle the row of uicontrols
p = handles.taskInfoControls(t,:);

% update the task proportions from control's pointer
textH   = findobj(p, 'Tag', 'proportionText');
sliderH = findobj(p, 'Tag', 'proportionSlider');
data    = get(sliderH, 'UserData');
propo   = rGet(data.ptr{:});

set(textH, 'String', propo(data.index));

% ditto block repetitions
textH   = findobj(p, 'Tag', 'blocksText');
sliderH = findobj(p, 'Tag', 'blocksSlider');
data    = get(sliderH, 'UserData');
set(textH, 'String', rGet(data.ptr{:}));

% similarly update trialOrder menu
menuH   = findobj(p, 'Tag', 'trialOrderMenu');
ptr     = get(menuH, 'UserData');
nowVal  = find(strcmp(get(handles.trialOrderMenu, 'String'), rGet(ptr{:})));
set(menuH, 'Value', nowVal);

% maybe 'press' the current task button
if isCurrentTask
    toggleH = findobj(p, 'Tag', 'taskToggle');
    dXparadigmGUI('taskToggle_Callback', toggleH, [], handles);
end