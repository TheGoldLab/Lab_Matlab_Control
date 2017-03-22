function [kb_, ret_, time_] = putValues(kb_, values)
% append new asynchronous event data, check in-out mappings

% preemptively check for pause/exit behavior
dXkbFunctionKeys(values(values(:,2)==1,1));

% append new events
%   nx3: [keycode, value, time]
kb_.values = cat(1, kb_.values, values);

% check new data against mappings
[kb_, ret_, time_] = getJump(kb_);