function times_ = RTDsendTTLPulses(dOutObject, channel, numPulses, timeBetweenPulses)
% function times_ = RTDsendTTLPulses(dOutObject, channel, numPulses, timeBetweenPulses)
%
% RTD = Response-Time Dots
%
% Utility for sending a sequence of regularly spaced TTL pulses
%
% 5/11/18 written by jig

if nargin < 2 || isempty(channel)
   channel = 0;
end

if nargin < 3 || isempty(numPulses)
   numPulses = 1;
end

if nargin < 4 || isempty(timeBetweenPulses)
   timeBetweenPulses = 0.001; % in sec
end

% save time of pulses
times_ = nans(numPulses, 1);
for pp = 1:numPulses
   times_(pp) = dOutObject.sendTTLPulse(channel); % ch 0 = positive output
   pause(timeBetweenPulses);
end
