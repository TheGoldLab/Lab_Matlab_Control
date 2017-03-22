function [b_, attributes_, batchMethods_] = dXbeep(num_objects)
% function [b_, attributes_, batchMethods_] = dXbeep(num_objects)
%
% Constructor method for class dXbeep
%
% Arguments:
%   num_objects    ... number of objects to create
%
% Returns:
%   bs_            ... array of created beep objects
%   attributes_    ... default object attributes
%   batchMethods_  ... not used

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% default object attributes
attributes = { ...
    % name              type		ranges(?)	default
    'duration',         'scalar',	[],         0;      ... % sec
    'frequency',        'scalar',	[],         1000;	... % Hz
    'sampleFrequency',  'scalar',	[],         44100;	... % Hz
    'bitrate',          'scalar',   [],         16;     ... % bits/sample
    'mute',             'boolean',  [],         false;	...
    'gain',             'scalar',   [],         1;      ... % volume
    'sound',            'auto',     [],         [];     ...
    'tag',              'auto',     [],         0};         % ignored

% make an array of objects from structs made from the attributes
b = cell2struct(attributes(:,4), attributes(:,1), 1);
for ii = 1:num_objects
    b_(ii) = class(b, 'dXbeep');
end

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% no batch methods
if nargout > 2
    batchMethods_ = {};
end


% i've placed a modified version of the Matlab low-level
% sound driver in the Files-Section of the forum. The
% "playsnd.mexmac" is a replacement for the corresponding
% file in your Matlab installation directory. Use the
% Search function of your Operating system to localize it
% and then replace it by this file (Always make backups from
% the original file before doing so).
% 
% This driver makes the Psychtoolbox SND function and Matlab's
% Sound, Soundsc and Wavplay functions non-blocking: They
% return immediately after starting playback of a sound and
% don't wait until the sound is finished.
% 
% Use the following sequence of commands in your scripts to
% play a sound in close sync with stimulus onset:
% 
% Screen('Flip', .....)
% Snd('Play', mySound, ....);
% WaitSecs(waitduration);
% ...
% 
% where waitduration should be at least 0.001 == 1 ms, but
% may need to be higher - you'll have to play around with
% the value. The idea is that the Snd command issues the
% sound playback request to the operating system and returns
% immediately, but then your Script needs to "sleep" for
% a few milliseconds to yield some processor time so that
% the operating system can run its sound-drivers and actually
% start playback of the sound.
