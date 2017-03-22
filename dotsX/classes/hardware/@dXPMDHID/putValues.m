function [p_, ret_, time_] = putValues(p_, values)
% append new asynchronous event data, check in-out mappings

% append new events
%   nx3: [channel, value, time]
p_.values = cat(1, p_.values, values);

% check new data against mappings
[p_, ret_, time_] = getJump(p_);