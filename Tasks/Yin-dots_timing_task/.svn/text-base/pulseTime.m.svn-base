function time = pulseTime(coh, cohcode)
% yl: 2010-09-12
% PULSETIME takes an array of coherence w/ pulses and returns an array that
% defines the start the pulses
%
%   INPUTS:
%       coh = trial-by-trial coherence stim (coded per cohcode)
%       cohcode = cell array allowing decoding of coh
%           e.g., 1 in coh <=> refers to [50 50 70] in cohcode{1}
%
%   OUTPUTS:
%       time = trial-by-trial start time of the pulses

% 1. figure out where pulse times start in cohcode
startcode = [];
for i = 1:length(cohcode)
    [maxcoh, startcode(i)] = max(cohcode{i});
    if sum(cohcode{i}-maxcoh)==0            % if coh is not temporally modulated
        startcode(i)=0;
    end
end

% 2. recode coh as start of pulse times
time = zeros(size(coh));
for i = 1:length(cohcode)
    time(coh==i) = startcode(i);
end
