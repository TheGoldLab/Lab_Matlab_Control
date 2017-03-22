% demonstrate the use of;
%   the DotsX group defined in gXtakeABreak
%   the function takeABreak
%
%   takeABreak is suitable for having subjects take a mandatory break
%   during a task.  gXtakeABreak defines some graphics to show a clock and
%   a dXsound instance for playing music.
%
%   The takeABreak function activates the group gXtakeABreak, loads a music
%   file (1-2 min) and plays the music while animating the clock.  The
%   function will block until the music is done playing.
%
%   Usually, takeABreak would be called during an experiment sessions, for
%   example, @takeABreak might be the 'endTaskFcn' of a dXtask object, in
%   which case dXparadigm/runTasks() would know to call takeABreak whenever
%   that task was finished.
%
%   In this case, we just call takeABreak once.
%
%   For deatails, look at the two files, gXtakeABreak.m and takeABreak.m.

% Copyright 2008 by Benjamin Heasly at the University of Pennsylvania

clear all
try
    rInit('remote');
    rSet('dXscreen', 1, 'bgColor', [1 1 1]);
    takeABreak;
end
rDone