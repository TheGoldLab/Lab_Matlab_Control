function cohTimeLearn_readCohThresh(varargin)
%Read a Quest threshold from dXtask.userData
%
%   cohTimeLearn_readCohThresh(varargin)
%
%   Look for a task named CohTimeLearn_timeQuest, and read a dXquest
%   threshold value from that task's userData property.
%
%   Set the threshold value to the current dXdots coherence.
%
%   cohTimeLearn_readCohThresh should be called by the task named
%   CohTimeLearn_timeQuest, which has a single dXdots helper, and which
%   should be the current task.
%
%   varargin is ignored.
%
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

% read data from the task of interest, the previous cohQuest

thresh = rGet('dXparadigm', 1, 'userData');

% set the dXdots coherence to threshold
global ROOT_STRUCT

rSet('dXtc', 2, 'values', thresh);
ROOT_STRUCT.dXtc = reset(ROOT_STRUCT.dXtc, true);
tStr = sprintf('%.2f ', thresh);
disp(sprintf('set threshold coherence, %s', tStr));

%viewingTime = rGet('dXtask', taski, 'userData');

% set the dXquest initial viewing time to the viewing time from the
% previous cohQuest
%rSet('dXquest', 1, 'stimValues', viewingTime);
%global ROOT_STRUCT


%disp(sprintf('picked new viewing time, %d', vts(vtCondition)))

%%%%%ORIGINAL BELOW%%%%%%%%

% read data from the task of interest, the previous cohQuest

%info = rGet('dXtask', taski, 'userData');

% some no-crash defaults
%if isempy(info)
%    warning(sprintf('%s is using default thresh and viewing time', ...
%        mfilename));
%    info.thresh = 100;
%    info.viewingTime = 1000;
%end

% set the dXdots coherence to threshold
%rSet('dXdots', 1, 'coherence', info.thresh);
%disp(sprintf('picked new coherence, %d', info.thresh))

% set the dXquest initial viewing time to the viewing time from the
% previous cohQuest
%rSet('dXquest', 1, 'startValue', info.viewingTime);
%global ROOT_STRUCT
%ROOT_STRUCT.dXtc = reset(ROOT_STRUCT.dXtc, true);

%disp(sprintf('picked new viewing time, %d', vts(vtCondition)))