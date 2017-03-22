function cohTimeLearn_interleaved_saveCohThresh(varargin)
%Save several Quest thresholds to dXtask.userData
%
%   cohTimeLearn_interleaved_saveCohThresh(varargin)
%
%   Look for a task named taskCohTimeLearn_interleaved_timeQuest, and put
%   the current set of dXquest threshold values into that task's userData
%   property.
%
%   cohTimeLearn_interleaved_saveCohThresh should be called by the task
%   named taskCohTimeLearn_interleaved_cohQuest, which has a few dXquest
%   helpers, each for a different dots viewing time, and which should be
%   loaded along side taskCohTimeLearn_interleaved_timeQuest.
%
%   varargin is ignored.

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

% copy the current Quest threshold estimates
q = rGet('dXquest');
threshs = [q.estimateLike];
rSet('dXtask', taski, 'userData', threshs);

tStr = sprintf('%.2f ', threshs);
disp(sprintf('saved threshold coherences, %s', tStr));