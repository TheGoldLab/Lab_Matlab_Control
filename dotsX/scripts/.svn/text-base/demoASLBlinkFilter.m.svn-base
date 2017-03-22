% demonstrate blink filtering for the ASL eyetracker using streaming data
% via as.mexmac.
%
%   put on the ASL headgear and get the eye position on screen
%   this will show streaming eye data in 4 plots:
%       1 pupil diameter
%       2 horizontal eye position
%       3 vertical eye position
%       4 blinking or not
%
%   The blink filter should work as follows.  Frame number i of eye data is
%   considered a blink frame if, 
%       pupilDiameter(i) <= lowP,
%   or, for any of the frames j = i-n : i-1,
%       pupilDiameter(j) <= lowP, or
%       |pupilDiameter(j+1) - pupilDiameter(j)| >= deltaP, or
%       |horizontal(j+1) - horizontal(j)| >= deltaH, or
%       |vertical(j+1) - vertical(j)| >= deltaV
%   This amounts to a threshold for pupil diameter, and speed limits for
%   pupilDiameter and horizontal and vertical eye positions.  The units of
%   the filter parameters will depend on eye-head-integration and camera
%   frequency.

% copyright 2007 Benjamin Heasly, University of Pennsylvania

clear as

clf(figure(932))
showN = 1000;
duration = 60;

ax_pd = subplot(4,1,1, 'YLim', [0, 100], 'XLim', [0,showN], 'XTick', []);
ylabel(ax_pd, 'pupil diameter')
pd = line(nan, nan, 'Color', [0 0 1], 'Parent', ax_pd);

ax_hp = subplot(4,1,2, 'XLim', [0,showN], 'XTick', []);
ylabel(ax_hp, 'horizontal position')
hp = line(nan, nan, 'Color', [0 .5 0], 'Parent', ax_hp);

ax_vp = subplot(4,1,3, 'XLim', [0,showN], 'XTick', []);
ylabel(ax_vp, 'vertical position')
vp = line(nan, nan, 'Color', [.7 .7 0], 'Parent', ax_vp);

ax_bn = subplot(4,1,4, 'XLim', [0,showN], 'XTick', [], ...
    'YLim', [-.1, 1.1], 'YTick', [0 1], ...
    'YTickLabel', {'normal', 'blinking'});
bn = line(nan, nan, 'Color', [1 0 0], 'Parent', ax_bn);

% configure blink filter parameters
% number of frames to examine
BF.n = 5;
BF.lowP = 0;
BF.deltaP = 10;
BF.deltaH = 500;
BF.deltaV = 500;
as('init', BF);

% start reading eye data
d = as('read');
while isempty(d)
    d = as('read');
end

% start plotting eye data
start = cputime;
while cputime < duration + start
    d = [d; as('read')];
    n = size(d, 1);
    naxis = max(n-showN, 1):n;
    xaxis = d(naxis, 4)-d(naxis(1), 4);
    set(pd, 'XData', xaxis, 'YData', d(naxis, 1));
    set(hp, 'XData', xaxis, 'YData', d(naxis, 2));
    set(vp, 'XData', xaxis, 'YData', d(naxis, 3));
    set(bn, 'XData', xaxis, 'YData', d(naxis, 5));
    drawnow;
end

as('close');