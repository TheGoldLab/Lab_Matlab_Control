function [g_, ret_, time_] = putValues(g_, values)
% append new asynchronous event data, check in-out mappings

% append new events
%   nx3: [button, value, time]
%   keep separate list of

g_.values = cat(1, g_.values, values);

% check new data against mappings
[g_, ret_, time_] = getJump(g_);