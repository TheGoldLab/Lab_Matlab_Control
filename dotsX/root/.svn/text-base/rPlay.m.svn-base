function rPlay(class_name, index)
% rPlay(class_name, index)
%
% Invokes the play method of the specified class instances
%   i.e. plays the given sound or video
%
% Arguments:
%   class_name  ... 'dXbeep', 'dXsound', 'dXvideo', etc.
%   index       ... index for ROOT_STRUCT.(class_name).  Default=1.

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% 24 April 2008, BSH spawned from rSoundPlay, for sake of dXvideo class

global ROOT_STRUCT

if nargin == 1 || isempty(index)
    play(ROOT_STRUCT.(class_name)(1));
else % if nargin == 2
    play(ROOT_STRUCT.(class_name)(index));
end