function id = getUniqueTaskID(name)
% function id = getUniqueTaskID(name)
%
% To standardize task IDs

if nargin < 1 || isempty(name)
   id = -1;
   return
end

% find in list
id = find(strcmp(name, { ...
   'topsTreeNodeTaskSaccade',                ...
   'topsTreeNodeTaskRTDots',                 ...
   'topsTreeNodeTaskSimpleBandit',           ...
   'topsTreeNodeTaskSimpleBanditNoGraphics', ...
   'topsTreeNodeTaskReversingDots',          ...
   'topsTreeNodeTask2AFCSwitch'}), 1);

% Default
if isempty(id)
   id = 0;
end