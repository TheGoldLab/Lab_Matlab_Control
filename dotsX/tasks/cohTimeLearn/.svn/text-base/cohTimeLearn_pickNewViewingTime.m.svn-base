function cohTimeLearn_pickNewViewingTime(varargin)
%Read a viewing time from dXtask.userData
%
%   cohTimeLearn_pickNewViewingTime(varargin)
%
%   Look for a task named CohTimeLearn_cohQuest and read an array of
%   viewing times value from from that task's userData property.  Then
%   select one viewing time from the array using the current
%   dXparadigm.repeatAllTasks value as an index.
%
%   Set the selected viewing time time to the second active instance of
%   dXtc.
%
%   cohTimeLearn_pickNewViewingTime should be called by the current task,
%   which should be named CohTimeLearn_cohQuest or CohTimeLearn_Practice,
%   both of which have two dXtc helpers.  The second dXtc is there just to
%   hold this viewing time value and save it to FIRA.
%
%   varargin is ignored.

% Copyright 2008 by Benjamin Heasly, University of Pennsylvania

% the task of interest:
% taskn = 'CohTimeLearn_cohQuest';
% 
% % locate the task
% taski = rTaskIndex(taskn);
% if isempty(taski)
%     warning(sprintf('%s could not find a task named %s', ...
%         mfilename, taskn));
%     return
% end

% read an array of viewing times
%   from the userData of the task of interest
vts = rGet('dXtask', rGet('dXparadigm', 1, 'taski'), 'userData');

% read the task repetition index from the current dXparadigm
vtCondition = length(vts) - rGet('dXparadigm', 1, 'repeatAllTasks');

% oops!
if vtCondition <= length(vts)

    % set the new viewing time to the second active dXtc
    rSet('dXtc', 2, 'values', vts(vtCondition));

    % reset all tuning curves as a group, to reflect this new "values"
    global ROOT_STRUCT
    ROOT_STRUCT.dXtc = reset(ROOT_STRUCT.dXtc, true);

    disp(sprintf('picked new viewing time, %d', vts(vtCondition)))
end

% Set to 100% coherence, for the practice task
%   this will be overridden by dXquest in the cohQuest task
rSet('dXdots', 1, 'coherence', 100);