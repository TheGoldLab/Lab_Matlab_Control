% demoDotsNoInit.m
%
% demo random dots using DotsX code
%
% shows 4 dots fields with various behaviors
%
% Don't reinitialize and don't rDone, so that this can be called
% repeatedly, especially when eval()ed by rRemoteClient.

% Copyright 2004-2007 by Joshua I. Gold and Benjamin Heasly
%   University of Pennsylvania

try
    % rInit should have been called already, so 
    %   just clear out existing class instances
    rClear

    rAdd('dXtarget', 8, 'visible', true, 'diameter', 0.5, 'color', [255,0,0], ...
        'x', {-12 -2 2 12 -12 -2  2 12}, ...
        'y', {  4  4 4  4  -4 -4 -4 -4});

    rAdd('dXdots', 4, 'visible', true, 'direction', 0.00, 'density', 33, ...
        'speed', 3, 'diameter', 6, 'color', {2 1 3 4},...
        'coherence', {99.9, 51.2, 25.6 12.8}, ...
        'x', {-7 7 -7  7}, ...
        'y', { 4 4 -4 -4}, 'deltaDir', {15, 0, 0, 0}, ...
        'lifetimeMode', {'random' 'limit'  'limit'  'limit'}, ...
        'flickerMode',  {'random' 'random' 'move'   'move'}, ...
        'wrapMode',     {'random' 'wrap'   'random' 'wrap'});

    rGraphicsDraw(inf);
    rGraphicsBlank;
    % don't rDone
catch
    e = lasterror
    rDone
end