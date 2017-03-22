function [a_, ret_, time_] = putValues(a_, values)
% append new asynchronous event data, check in-out mappings

% append new events
%   nx5: [pupil diam, x, y, frame, isBlinking]
a_.values = cat(1, a_.values, values);

% check new data against mappings
[a_, ret_, time_] = getJump(a_);