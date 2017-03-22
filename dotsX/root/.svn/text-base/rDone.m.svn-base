function rDone(remote_call)
%Call the 'done' method for active DotsX objects.
%   rDone(remote_call)
%
%   rDone invokes the 'done' method of each active instance of each DotsX
%   class that defines a 'done' method.  The global ROOT_STRUCT.done is
%   always a current list of these classes.
%
%   remote_call is optional and specifies behavior for a remote graphics
%   client.  In remote graphics mode: remote_call = 1 invokes the 'done'
%   method of objects on the remote graphics client as well as on the local
%   machine; if remote_call is the empty [], not provided, or remote_call =
%   2, rDone invokes rClear on the remote machine and 'done' for objects on
%   the local machine.
%
%   For example, rDone normally invokes the 'done' method of the dXscreen
%   class (among others), which closes the current Psychtoolbox drawing
%   window and returns the user to the MATLAB command line.
%
%   The following uses rDone to conclude a simple task.
%
%   rInit('local');
%   rAdd('dXtext', 1, 'string', 'press a key or wait 5 sec', ...
%       'x', -5);
%   rGraphicsShow;
%   rGraphicsDraw(5000);
%   rDone;
%
%   See also dXscreen/done rBatch rClear rGroup

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% call root method with 'clear' flag
rBatch('root', [], 'clear');
ROOT_STRUCT.HIDxInit = HIDx('close');

if ROOT_STRUCT.screenMode == 2
    if ~nargin || isempty(remote_call) || remote_call == 2
        sendMsg('rClear;');
    elseif remote_call == 1
        sendMsg('rDone;');
    end
end