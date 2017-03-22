function cohTimeLearn_pickQuestCondition
% pick the right quest instance and stim condition
%   this is either a viewing time condition or a coherence condition

% get the value for the current dots viewing time or coherence condition
value = rGet('dXtc', 2, 'value');

% get the list of all conditions from the current task
global ROOT_STRUCT
conditions = rGetTaskByName(ROOT_STRUCT.groups.name, 'userData');

% get the index of the stim value from the list
index = find(value==conditions);

% update the quest from this condition only
ROOT_STRUCT.dXquest(index) = update(ROOT_STRUCT.dXquest(index));

% allow only the quest for this condition time to do endTrial computations
rSet('dXquest', 1:length(conditions), 'doEndTrial', false);
rSet('dXquest', index, 'doEndTrial', true);

rGet('dXquest', index, 'value')