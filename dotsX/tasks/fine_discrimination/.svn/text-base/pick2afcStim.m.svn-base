function pick2afcStim(interval, standard, different)
% Set dXdots direction from current interval and dXtc 2afc condition
%
%   pick2afcStim(interval, standard, different)
%
%   interval is the current interval during a trial.  1 or 2.
%
%   standard is the direction to use for both intervals during "same" trials
%   and for one of the intervals during "different" trials.
%
%   different is the direction to use for the other interval during
%   "different" trials.

% 2008 Benjamin Heasly at University of Pennsylvania

% condition can be 
%   0, meaning this is a "same" trial,
%   1, meaning interval 1 is the "different" interval, or
%   2, meaning interval 2 is the "different" interval
condition = rGet('dXtc', 1, 'value');
if interval == condition
    rSet('dXdots', 1, 'direction', different);
else
    rSet('dXdots', 1, 'direction', standard);
end