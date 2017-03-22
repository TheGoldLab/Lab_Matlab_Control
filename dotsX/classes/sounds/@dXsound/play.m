function play(s)
% function play(s)
%
% plays the given dXsound sound, applies gain

% Copyright 2008 by Benjamin Heasly
%   University of Pennsylvania

playsnd(s.sound.*s.gain, s.sampleFrequency, s.bitrate);