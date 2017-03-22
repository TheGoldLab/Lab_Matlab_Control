function windowPtr = rWinPtr
%Gives the Psychtoolbox Screen windowPtr being used by DotsX.
%   windowPtr = rWinPtr
%
%   rWinPtr gives access to the Screen window that DotsX is using, allowing
%   you to bypass DotsX functions and make direct Screen calls.
%
%   For example, the following will flip the DotsX window buffers.
%
%       rInit('local');
%       [VBLTime] = Screen('Flip', rWinPtr)
%
%   See also rInit, rScreen

% 2006 by Benjamin Heasly at University of Pennsylvania

global ROOT_STRUCT
windowPtr = ROOT_STRUCT.windowNumber;