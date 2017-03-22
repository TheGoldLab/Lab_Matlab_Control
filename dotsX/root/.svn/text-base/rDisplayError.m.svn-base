function rDisplayError(errMessage, errSound, throwErr)
%Show an error message in dXgui, play a sound, throw an error.
%   rDisplayError(errMessage, errSound, throwErr)
%
%   errMessage is a string containing an error message to display.  The
%   message is also appended to ROOT_STRUCT.error.
%
%   errSound is optional.  If logical true, rDisplayError will play a
%   standard message informing the subject that there was a technical
%   problem and she or he should discontinue the current session.
%
%   Alternatively, errSound may be a cell array pointer to a DotsX sound
%   object. For example: {'dXbeep', 1}.
%
%   throwErr is optional.  If logical true, rDisplayError will throw an
%   error and stop execution.
%
%   see also dXbeep play rPlay

% Copyright 2007 by Benjamin Heasly
%   University of Pennsylvania

global ROOT_STRUCT

if ~nargin || ~ischar(errMessage)
    errMessage = 'Unspecified error, you dope.';
end

% save the error with a timestamp in DotsX's ROOT_STRUCT.error
ROOT_STRUCT.error = cat(1, ROOT_STRUCT.error, {GetSecs, errMessage});

errPrefix = 'DotsX error: ';
if ~isempty(ROOT_STRUCT) && ishandle(ROOT_STRUCT.guiFigure)
    handles = guidata(ROOT_STRUCT.guiFigure);
    if ishandle(handles.DotsXStatusText)
        set(handles.DotsXStatusText, ...
            'String', [errPrefix, errMessage]);
    end
end

% play a sound?
if nargin > 1
    if islogical(errSound) && errSound
        % play the default error audio message
        disp('error sound!!')
        %play(dXdefaultErrSound(1));
    elseif iscell(errSound)
        % play() the given DotsX sound object
        rPlay(errSound{:});
    end
end

% throw a MATLAB error?
if nargin > 2 && islogical(throwErr) && throwErr
    error([errPrefix, errMessage]);
else
    disp([errPrefix, errMessage]);
end