% demoAllGraphics.m
%
% Show two of each type of DotsX graphics object.
%
% These include:
%   dXcorner, dXtext, dXline, dXtarget, dXtargets, dXdots, dXimage

% 2006 by Benjamin Heasly at University of Pennsylvania

try
    % select the screen mode you want:
    %   'debug', 'local', or 'remote'
    rInit('local');

    % show a little blue square in each upper corner
    % for snits, test the Screen.mexmac with a color index
    rAdd('dXcorner', 2,	'location', {1,2}, 'color', 4);

    % show two independent text fields with default color yellow
    rAdd('dXtext', 2, 'x', {-8, 4}, 'y', 6, 'string', {'true', 'pooh'});

    % show a nice, green cross near the middle of the screen
    rAdd('dXline', 2, 'x1', {-7.5, 0}, 'x2', {7.5, 0}, 'y1', {3, 2}, 'y2', {3, 4});

    % show two instances of no-'s' dXtarget class in red
    rAdd('dXtarget', 2, 'x', {-0.5, 0.5}, 'y', {3.5, 2.5}, ...
        'color', [255,0,0], 'diameter', .4);

    % show one instance of the dXtargets-with-'s' in green, with two dots
    rAdd('dXtargets', 1, 'x', [-0.5, 0.5], 'y', [2.5, 3.5], ...
        'color', [0,255,0], 'diameter', .4);

    % show two fields of dots.  For fun, superimpose them to resemble bees.
    rAdd('dXdots', 2, 'x', -10, 'y', -2.5, 'direction', {180, 90}, ...
        'diameter', 4, 'color', {[0,0,0,255], [200,200,1,255]}, 'density', 30, 'size', 1);

    % show two pooh images: Pooh with honey and Pooh walking with Piglet
    rAdd('dXimage', 2, 'x', {-7, 8} , 'y',  -3, ...
        'file', {'pooh16.bmp', 'sunset.bmp'}, 'scale', {1.2, .7});

    % an easy way to set 'visible' = true for all objects
    rGraphicsShow();

    % show the graphics and animate the dots for 1x10^5ms = 100sec
    %   or until a keyboard press
    rGraphicsDraw(1e5)

    % clear the screen
    rGraphicsBlank

    % close the Psychtoolbox Screen window, etc.
    rDone

catch
    % there was an error!  don't forget to
    %   close the Psychtoolbox Screen window, etc.
    rDone
end