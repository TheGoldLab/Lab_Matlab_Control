function play(v)
% function play(v)
%
% plays the given dXvideo movie(s)
%
% This starts the sound and tells Screen to start counting video frames.
% The actual drawing of the frames should take place in the draw() method.

% Copyright 2008 by Benjamin Heasly
%   University of Pennsylvania

vis = [v.visible];
for ii = find(vis)
    [v(ii).droppedFrames] = Screen('PlayMovie', ...
        v(ii).moviePtr, ...
        v(ii).rate, ...
        v(ii).loop, ...
        (~v(ii).mute)*v(ii).soundVolume);
end