function showDotsCheckFP(dots, fp)
% show the dots and if the fp is in the same place, hide it
%
%   showDotsCheckFP(dots, fp)
%
%   dots should be a cell array pointer to a dXdots object (or any
%   graphics object with x, y, and diameter).
%
%   fp should be a cell array pointer to a dXtarget object (or any graphics
%   object with x and y).
%
%   I don't expect this to be all that fast.  I'm intending to call it
%   during fixation-holding downtime.

% 2008 Benjamin Heasly at University of Pennsylvania

% get dots and fp properties
d = rGet(dots{:});
t = rGet(fp{:});

% check to see if dots and fp are in the same place
if abs(d.x-t.x) <= d.diameter/2 && abs(d.y-t.y) <= d.diameter/2

    % dots and fp overlap.  Hide fp.
    show = cat(2, dots, {{}}, fp);

else

    % no overlap, ignore fp.
    show = dots;
end

% show at least the dots
rGraphicsShow(show{:});