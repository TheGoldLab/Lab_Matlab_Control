function fig_ = measureFrameFlipDeadline
% A video frame lasts tens of miliseconds, depending on the monitor refresh
% rate.  The CPU/video driver has a certain amount of time to do
% processing/drawing/etc., then the GPU needs to have time to render/write
% to the video buffer.
%
% For the simple case of drawing nothing and simply waiting and flipping
% the screen buffer, what is the minimum time that the GPU needs to meet
% each flip deadline?  Equivalently, what is maximum CPU time available for
% drawing, etc., before the user's program must call 'Flip'?
clear all
clear Screen

disp('Measuring CPU time available during graphics frames')

reps = 50;
try
    Screen('Preference', 'SkipSyncTests',1);
    wn = Screen('OpenWindow', 0);
    fr = Screen('FrameRate', wn);
    if ~fr
        fr = -60;
    end
    ss = abs(1000/fr);

    waiters = 0:1:ss*1.3;
    nw = length(waiters);
    preWaits = nan*ones(reps, nw);
    preFlips = nan*ones(reps, nw);
    postFlips = nan*ones(reps, nw);

    for ww = 1:nw
        for rr = 1:reps
            preWaits(rr,ww) = GetSecs;
            WaitSecs(waiters(ww)/1000);
            preFlips(rr,ww) = GetSecs;
            %Screen('DrawingFinished', wn);
            Screen('Flip', wn);
            postFlips(rr,ww) = GetSecs;
        end
    end
catch
    e = lasterror
    Screen('CloseAll');
end
Screen('CloseAll');

fig_ = figure(49);
clf(fig_)
set(fig_, 'Name', 'cpu time');
axa = axes('XTick', waiters(1:2:end), 'XMinorTick', 'on');
frameTime = postFlips-preWaits;
line(waiters, 1000*mean(frameTime), 'Color', [0 0 0], 'Parent', axa);
line(waiters, 1000*prctile(frameTime, 5), 'Color', [0 0 0], ...
    'LineStyle', 'none', 'Marker', '.', 'Parent', axa);
line(waiters, 1000*prctile(frameTime, 95), 'Color', [0 0 0], ...
    'LineStyle', 'none', 'Marker', '.', 'Parent', axa);
line(waiters([1, end]), [ss, ss], 'Color', [0 1 0])
text(waiters(end), ss, 'one frame', 'Color', [0 1 0]);
line(waiters([1, end]), 2*[ss, ss], 'Color', [1 0 0])
text(waiters(end), 2*ss, 'two frames', 'Color', [1 0 0]);
line(ss*[1 1], ss*[.9 ,2.1], 'Color', [0 0 0])
text(ss, ss*.8, 'one frame', 'Color', [0 0 0]);

xlabel(axa, 'delay vefore flip (ms)')
ylabel(axa, 'return from flip mean, 5^t^h, 95^t^h percentile (ms)')
ylim(axa, [0 3*ss])
title(sprintf('Titrated Flip Deadline: refresh rate of %.2fHz', fr))