function cohTimeLearn_interleaved_readCohThresh(varargin)
%Read some Quest thresholds from dXtask.userData
%
%   cohTimeLearn_interleaved_readCohThresh(varargin)
%
%   Look for a task named cohTimeLearn_interleaved_readCohThresh, and read
%   several dXquest threshold value from that task's userData property.
%
%   Set the thresholds to the "values" of the current, second dXtc instance.
%
%   cohTimeLearn_interleaved_readCohThresh should be called by the task
%   named CohTimeLearn_interleaved_timeQuest, which has dXtc helpers, and
%   which should be the current task.
%
%   varargin is ignored.
%
% Copyright 2008 by Benjamin Heasly, University of Pennsylvania

% the task of interest:
taskn = 'CohTimeLearn_interleaved_timeQuest';

% locate the task
taski = rTaskIndex(taskn);
if isempty(taski)
    warning(sprintf('%s could not find a task named %s', ...
        mfilename, taskn));
    return
end

% read a coherence and a viewing time
%   from the userData of the task of interest, the timeQuest
threshs = rGet('dXtask', taski, 'userData');

% set the dXdots coherence to threshold
global ROOT_STRUCT
rSet('dXtc', 2, 'values', threshs);
ROOT_STRUCT.dXtc = reset(ROOT_STRUCT.dXtc, true);

tStr = sprintf('%.2f ', threshs);
disp(sprintf('set threshold coherences, %s', tStr));