% Try this:
%   Save some points using the dXdots debug mode and also save the random
%   seed.
%   Then, make some new dots, reset the seed, and try to save the same
%   points.
clear all
close all

% pick one seed
commonSeed = GetSecs;

% start up
global ROOT_STRUCT
rInit('local');
rAdd('dXdots', 1, 'debugSavePts', true, 'visible', true);

% seed the generator
ROOT_STRUCT.randSeed = commonSeed;
ROOT_STRUCT.randMethod = 'twister';
rand(ROOT_STRUCT.randMethod, ROOT_STRUCT.randSeed);
rand(1,7)

% controled draw
for ii = 1:100
    ROOT_STRUCT.dXdots = draw(ROOT_STRUCT.dXdots);
end

oldPoints = rGet('dXdots', 1, 'ptsHistory');

% clear out
rDone
ROOT_STRUCT = [];

% start up again
rInit('local');
rAdd('dXdots', 1, 'debugSavePts', true, 'visible', true);

% seed the generator
ROOT_STRUCT.randSeed = commonSeed;
ROOT_STRUCT.randMethod = 'twister';
rand(ROOT_STRUCT.randMethod, ROOT_STRUCT.randSeed);
rand(1,7)

% controled draw
for ii = 1:100
    ROOT_STRUCT.dXdots = draw(ROOT_STRUCT.dXdots);
end

newPoints = rGet('dXdots', 1, 'ptsHistory');

% clear out
rDone

% check to see if old and new points are the same
figure(3333)
nf = min(size(oldPoints, 3), size(oldPoints, 3));
lOld = line(0, 0, 'Marker', '.', 'LineStyle', 'none', 'Color', [0 0 1]);
lNew = line(0, 0, 'Marker', 'o', 'LineStyle', 'none', 'Color', [1 0 0]);
for ii = 1:nf
    set(lOld, 'XData', oldPoints(1,:,ii), 'YData', oldPoints(2,:,ii));
    set(lNew, 'XData', newPoints(1,:,ii), 'YData', newPoints(2,:,ii));
    waitforbuttonpress
end