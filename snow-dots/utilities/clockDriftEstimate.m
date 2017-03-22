% Compute drift and offset between two clocks, given coincident timestamps.
% @param timestampsA array of timestamps for some events, taken with
% "clock A"
% @param timestampsB array of timestamps for the same events as @a
% timestampsA, taken with "clock B"
% @details
% @a timestampsA and @a timestampsB must be the same size.  Both should
% contain timestamps for a common set of events, so that @a timestampsA are
% the event times as "seen" from clock A, and @a timestampsB are the event
% times as "seen" from clock B.
% @details
% Computes parameters for doing a linear transformation from @a timestampsA
% into @a timestampsB, or in general to transform timestamps from clock A
% into the clock B equivalents.  See clockDriftApply() to do the
% general transformation.
% @details
% Returns a struct with transformation parameters and information for
% estimating transformation error as returned from Matlab's polyfit().  The
% struct has fields:
%   - @b drift the rate at which clocks A and B drift apart over time: how
%   often clock B ticks for each tick of clock A
%   - @b offset the inital absolute difference between clocks A and B: the
%   time at clock B when clock A was at 0.
%   - @b polyMu centering and scaling parameters returned from polyfit()
%   - @b polyInfo struct of error estimation data returned from polyfit()
%   .
%
% @ingroup dotsUtilities
function aToB = clockDriftEstimate(timestampsA, timestampsB)
[coefficients, info, mu] = polyfit(timestampsA, timestampsB, 1);
aToB.drift = coefficients(1) / mu(2);
aToB.offset = coefficients(2) - aToB.drift*mu(1);
aToB.polyMu = mu;
aToB.polyInfo = info;

% f = figure(1);
% clf(f)
% n = numel(timestampsA);
% line(1:n, timestampsA, ...
%     'LineStyle', 'none', ...
%     'Marker', '*', ...
%     'Color', [0 0 1])
% line(1:n, timestampsB, ...
%     'LineStyle', 'none', ...
%     'Marker', 'o', ...
%     'Color', [0 1 0])
% line(1:n, clockDriftApply(timestampsA, aToB), ...
%     'LineStyle', 'none', ...
%     'Marker', '.', ...
%     'Color', [1 0 0])