function fig_ = measureDotDensityPerformance
% Gradually increase the density of dots in a 10-deg aperture and measure
% drawing/flipping performance.
%
% On weak machines, we might expect frame skipping for high densities.

% Copyright 2007 Benjamin Heasly, University if Pennsylvania
clear all
clear Screen
global ROOT_STRUCT

disp('Measuring performance at various dXdots densities')

try
    rInit('local')
    wn = rWinPtr;
    fr = rGet('dXscreen', 1, 'frameRate');
    ap = 20;
    rAdd('dXdots', 1, 'diameter', ap, 'visible', true);

    reps = 50;
    dens = 10:10:500;
    nd = length(dens);

    numDots = nan*ones(1, nd);
    preDraws = nan*ones(reps, nd);
    preFlips = nan*ones(reps, nd);
    postFlips = nan*ones(reps, nd);

    for dd = 1:nd
        ROOT_STRUCT.dXdots(1) = set(ROOT_STRUCT.dXdots(1), ...
            'density', dens(dd));
        numDots(dd) = rGet('dXdots', 1, 'nDots');

        for rr = 1:reps
            preDraws(rr,dd) = GetSecs;
            ROOT_STRUCT.dXdots(1) = draw(ROOT_STRUCT.dXdots(1));
            preFlips(rr,dd) = GetSecs;
            %Screen('DrawingFinished', wn);
            Screen('Flip', wn);
            postFlips(rr,dd) = GetSecs;
        end
    end
catch
    e = lasterror
    rDone
end
rDone

fig_ = figure(47);
clf(fig_);
set(fig_, 'Name', 'dot density');
axa = axes;
set(axa, 'Position', get(axa, 'Position').*[1 1 1 .9])
frameTime = postFlips-preDraws;
line(dens, 1000*mean(frameTime), 'Color', [0 0 0], 'Parent', axa);
line(dens, 1000*prctile(frameTime, 5), 'Color', [0 0 0], ...
    'LineStyle', 'none', 'Marker', '.', 'Parent', axa);
line(dens, 1000*prctile(frameTime, 95), 'Color', [0 0 0], ...
    'LineStyle', 'none', 'Marker', '.', 'Parent', axa);

xlabel(axa, 'dot density (dot/deg^2/sec)')
ylabel(axa, 'return from flip mean, 5^t^h, 95^t^h percentile (ms)')
xlim(axa, [dens(1), dens(nd)])
ylim(axa, [0 3000/fr])

axb = axes('Position', get(axa, 'Position'), 'Color', 'none', ...
    'XAxisLocation', 'top', 'YAxisLocation', 'right', 'YColor', [0 .5 0]);
drawTime = preFlips-preDraws;
line(numDots, 1000*mean(drawTime), 'Color', [0 .5 0], 'Parent', axb);
line(numDots, 1000*prctile(drawTime, 5), 'Color', [0 .5 0], ...
    'LineStyle', 'none', 'Marker', '.', 'Parent', axb);
line(numDots, 1000*prctile(drawTime, 95), 'Color', [0 .5 0], ...
    'LineStyle', 'none', 'Marker', '.', 'Parent', axb);
xlim(axb, [numDots(1), numDots(nd)])
xlabel(axb, 'number of dots')
ylabel(axb, 'draw time mean, 5^t^h, 95^t^h percentile (ms)')
ylim(axb, [0 3000/fr])
title(axb, sprintf( ...
    'dXdots performance at various densities (%.1f deg aperture)(%.1fHz frame rate)', ap, fr));