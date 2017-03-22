function cohTimeLearn_saveCohThresh(varargin)
%Save a Quest threshold to dXtask.userData
%
%   cohTimeLearn_saveCohThresh(varargin)
%
%   Look for a task named CohTimeLearn_timeQuest, and put the current
%   dXquest threshold value into that task's userData property.
%
%   cohTimeLearn_saveCohThresh should be called by the task named
%   CohTimeLearn_cohQuest, which has a single dXquest helper, and which
%   should be loaded along side CohTimeLearn_timeQuest.
%
%   varargin is ignored.

% Copyright 2008 by Benjamin Heasly, University of Pennsylvania

% the task of interest:
% taskn = 'CohTimeLearn_timeQuest';
% 
% % locate the task
% taski = rTaskIndex(taskn);
% if isempty(taski)
%     warning(sprintf('%s could not find a task named %s', ...
%         mfilename, taskn));
%     return
% end

% copy the current Quest threshold estimate and viewing time
%   to the userData of the task of interest

q=rGet('dXquest');

if isstruct(q)
thresh = [q.estimateLike];

%thresh = rGet('dXquest', 1, 'estimateLike');

thresh_old = rGet('dXparadigm', 1, 'userData');
rSet('dXparadigm', 1, 'userData', [thresh_old thresh]);

thresh
end

%info.viewingTime = rGet('dXtc', 2, 'values');
%rSet('dXtask', taski, 'userData', thresh);

%disp(sprintf('saved coherence, %.2f and viewingTime %.2f', ...
%    info.thresh, info.viewingTime));