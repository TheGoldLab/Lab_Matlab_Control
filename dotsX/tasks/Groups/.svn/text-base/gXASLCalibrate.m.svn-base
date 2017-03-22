function aslc_ = gXASLCalibrate(varargin)
%describe a standard set of eyetracker calibration points

% Copyright 2007 by Benjamin Heasly at University of Pennsylvania

% 3x3 array of targets
%   On the CRT in Johnson 115, at a viewing distance of 63.5cm,
%   BSH measured 12 degrees -> 13.49cm and 10 degrees -> 10.95cm
%   (these are not quite consistent)
x = 12;
y = 10;
xt = {-x 0 x -x 0 x -x  0  x};
yt = { y y y  0 0 0 -y -y -y};

% sort the targets like the numpad
numPad = [7 8 9 4 5 6 1 2 3];

% targets are red
arg_target = {'visible', true, ...
    'diameter', 0.5, 'color', [128 0 0 255], ...
    'x', xt(numPad), 'y', yt(numPad)};

% two green points for asl stationary scene plane
arg_point = {'visible', true, ...
    'diameter', 0.5, 'color', [0 128 0 255], ...
    'x', {x/2, -x/2}, 'y', {y/2, -y/2}};

% one cyan point for current eye position
arg_eye = {'visible', false, ...
    'diameter', 0.7, 'color', [0 255 255 128], ...
    'x', 0, 'y', 0};

% {'group', reuse, setnow, setalways}
reswap = {mfilename, false, true, true};
aslc_ = { ...
    'dXtarget',     9,      reswap,   arg_target; ...
    'dXtarget',     2,      reswap,   arg_point; ...
    'dXtarget',     1,      reswap,   arg_eye};