function rScreen(cmd, varargin)
%Makes a Psychtoolbox Screen call for the window being used by DotsX.
%   rScreen(cmd, varargin)
%
%   rScreen executes the Psychtoolbox Screen function specified by the
%   string cmd and includes any arguments in the list varargin.  rScreen
%   will use the same windowPtr that DotsX is using.
%
%   rScreen can execute Screen functions of the form
%       Screen(cmd, windowPtr, [,arg1] ...)
%
%   rScreen will not capture return values from Screen commands.
%
%   To specify Screen arguments in a different order or to capture return
%   arguments, consider using rWinPtr.
%
%   To capture return values from 
%
%   For example, the following will flip the DotsX window buffers.
%
%       rInit('local');
%       rScreen('flip');
%
%   See also rWinPtr, rInit

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania

if isempty(cmd)
    return
end

global ROOT_STRUCT
Screen(cmd, ROOT_STRUCT.windowNumber, varargin{:});