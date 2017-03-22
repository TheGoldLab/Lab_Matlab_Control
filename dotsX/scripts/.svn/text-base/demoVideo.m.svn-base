% demonstrates how to play a video usuing DotsX and the dXvideo class.
%   I think this will be useful for inserting a mandatory break during
%   psychpohysics tasks.
%
% 24 April 2007
%   So far, only the "DualDiscs.mov" video that came from Psychtoolbox
%   demos works with sound and images.  Three other videos I downloaded
%   play with sound, but no images.
%
%   This is the same behavior I get with the Psychtoolbox demo,
%   PlayMoviesDemoOSX, so I think it's a Screen bug or Quicktime format
%   support problem.

% 2008 by Benjamin Heasly at University of Pennsylvania

% open a sondow
rInit('local')

% load a video with dXvideo class
ind = rAdd('dXvideo', 1, 'file', 'DualDiscs.mov', 'loop', 1);

% start movie playback
rPlay('dXvideo', ind);

% go through each movie frame in sync with sound
rGraphicsDraw(inf)

% free the video and close the window
rDone;