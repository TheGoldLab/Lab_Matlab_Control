% just demonstrate the graphics for the fine_discrimination task
%
%   also, how many dots are we talking?
clear all

% load the task graphics
rInit('remote');

% make the screen bg match the dots mask (this is not how it works in a
% real task, but it's fine for this demo...)
rGroup('gXfine_graphics');
rSet('dXscreen', 1, 'bgColor', rGet('dXdots', 1, 'maskColor'));

% show them and wait
rGraphicsShow;
rGraphicsDraw(inf);

rDone;