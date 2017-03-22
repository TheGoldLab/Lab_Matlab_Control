% Play SquareTag with improvements: OpenGL graphics and USB/HID input.
clear
close all

% make a new "back end" for SquareTag
logic = SquareTagLogic('SquareTagPlus demo');
logic.nTrials = 3;
logic.nSquares = 5;

% make a "front end" which defines graphics or sound for the back end
av = SquareTagAVPlus(logic);

% read input X and Y position from a USB/HID mouse
mouse = dotsReadableHIDMouse();
mouse.isAutoRead = true;

% may need to choose a specific mouse
%   see mexHIDScout() for a summary of connected devices
% mouse.devicePreference.VendorID = 1452;
% mouse.devicePreference.ProductID = 553;
% mouse.initialize();

% scale raw X and Y component data to the SquareTag unitless [0 1] space
cursorScale = 1000;
getX = @()(mouse.getValue(mouse.xID)/cursorScale) + 0.5;
getY = @()(-mouse.getValue(mouse.yID)/cursorScale) + 0.5;

% wire up the back end, front end, and user input
[runnable, list] = configureSquareTag(logic, av, getX, getY);

% view flow structure and data
% runnable.gui();
% list.gui();

% execute SquareTagPlus!
topsDataLog.flushAllData();
runnable.run();

% view data logged during the task
%topsDataLog.gui();