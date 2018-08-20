function [startTime, finishTime] = sendTTLsequence(numPulses)
% function [startTime, finishTime] = sendTTLsequence(numPulses)
%
% Utility for sending a sequence of TTL pulses with standard parameters.
% This way you only have to change it here.
%
% Created 5/28/18 by jig


persistent dOutObject channel pauseTime

% Define defaults
if isempty(dOutObject)
   dOutObject = feval( ...
      dotsTheMachineConfiguration.getDefaultValue('dOutClassName'));
   channel = 0;
   pauseTime = 0.2;
end

% Check argument
if nargin < 1 || isempty(numPulses)
   numPulses = 1;
end

if numPulses < 1
   startTime = [];
   finishTime = [];
   return
end

% Get time of first pulse
startTime = dOutObject.sendTTLPulse(channel);

% get the remaining pulses and save the finish time
finishTime = startTime;
for pp = 1:numPulses-1
   pause(pauseTime);
   finishTime = dOutObject.sendTTLPulse(channel);
end
