function takeABreak(taski, varargin)
%Show a timer and play a tune between tasks/blocks
%
%   takeABreak(taski, varargin)
%
%   I intend @takeABreak to be set as the endTrialFcn of a dXtask object.
%   In that case, dXparadigm/runTasks will automatically invoke takeABreak
%   once per block, right after the task executes its last trial.
%
%   taski is the index of the current dXtask, ROOT_STRUCT.dXtask(taski).
%
%   taski and varargin are ignored.
%
%   takeABreak activates the gXtakeABreak group, which has graphics for
%   showing a clock, and a dXsound object for playing music.  Takeabreak
%   loads a random music file (see shortMusicFiles.m) and animates the
%   clock for the duration of the music.
%
%   See also gXtakeABreak, shortMusicFiles

% 2008 by Benjamin Heasly at the University of Pennsylvania

% activate graphics for a clock
%   get the clock hand radius
rGroup('gXtakeABreak');
r = rGet('dXline', 1, 'y2');
rGraphicsShow;
rGraphicsDraw;

% load some nice music 1:00 to 2:00 long
%   there are almost 200 files in this list
%   pick 1 at random
[fullf, name, path, ext, nFiles] = shortMusicFiles;
randInd = floor(1-eps+rand*nFiles);
rSet('dXsound', 1, 'rawSound', fullf(randInd));

% normalize the volume of all music
s = rGet('dXsound', 1, 'sound');
rSet('dXsound', 1, 'gain', 1/max(abs(s(1:numel(s)))));

% Name that tune.  What's the name of that song?
disp(sprintf('%s playing #%d, "%s"', mfilename, randInd, name{randInd}))

% animate the clock while the music plays
musicSecs = ceil(rGet('dXsound', 1, 'duration'));
rPlay('dXsound', 1);
startSecs = GetSecs;
for ii = 0:musicSecs

    % update the clock number
    rSet('dXtext', 2, 'string', sprintf('%d', musicSecs-ii));

    % move the clock hands
    y2 = r*cos(-2*pi*ii/musicSecs);
    x2 = r*sin(-2*pi*ii/musicSecs);
    rSet('dXline', 1, 'y2', y2, 'x2', x2);

    % wait for the next scheduled tick
    while GetSecs < startSecs+ii
        WaitSecs(.002);
    end
    rGraphicsDraw;
end