function [wn_, sr_, ppd_, fr_] = rRemoteSetup(monitorWidth, viewingDistance)
%Get and set some properties of a remote stimulus screen
%   [wn_, sr_, ppd_, fr_] = rRemoteSetup(monitorWidth, viewingDistance)
%
%   For the dXscreen instance residing on a remote graphics client,
%   rRemoteSetup returns the window number wn_, screen rectangle sr_,
%   pixels per degree ppd_, and frame rate fr_.
%
%   During rRemoteSetup, the server machine exchanges messages with the
%   remote client machine to measure a clock offset between them (server
%   time - client time ±2ms).  This allows timestamps recorded on the
%   client machine to  be translated into the server's frame of reference.
%   The offset is stored in the global variable
%   ROOT_STRUCT.remoteTimeOffset.
%
%   rRemoteSetup also reinitializes the remote graphics client to make it
%   ready for a new experiment.  If monitorWidth and viewingDistance are
%   both provided, the client will be reinitialized using these values.
%
%   If a remote machine is connected and runnig rRemoteClient, the
%   following will initialize the client with bogus monitorWidth and
%   viewingDistance values, and return values such as window number for the
%   remote dXscreen.
%
%   rInit('remote');
%   [wn_, sr_, ppd_, fr_] = rRemoteSetup(3, 1000)
%
%   Subsequently, the following will diaplay the offset between the client
%   and server system clocks.
%
%   global ROOT_STRUCT
%   disp(ROOT_STRUCT.remoteTimeOffset)
%
%   see also rInit, rRemoteClient, dXscreen

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

if ROOT_STRUCT.screenMode == 2

    % Note that this function assumes it is called
    %   via "eval" from rRemoteClient.

    % remote mode ... need screen attributes from
    %   remote machine
    if nargin == 2
        sendMsgH(sprintf('rRemoteSetup(%.2f, %.2f)', ...
            monitorWidth, viewingDistance));
        disp('rRemoteSetup sent Screen parameters to client')
    else
        sendMsgH('rRemoteSetup');
    end
    
    % client should eval() and send some data
    msg = getMsg(200);
    tries = 1;
    retry = rGet('dXudp', 1, 'retry');
    while ~strncmp(msg, 'wn_=', 4) && tries <= retry
        msg   = getMsg(200);
        tries = tries + 1;
    end

    if tries >= retry
        % show error, play error message, and throw an error bomb
        rDisplayError('rRemoteSetup got no Screen data from client', ...
            true, true);
    end

    % evaluate the data message...see contents below
    eval(msg);
    
    disp('rRemoteSetup got Screen parameters from client')
else

    % This portion executed by the remote client with eval().

    % rClear does most of the work of cleaning up
    %   ROOT_STRUCT, leaving for initialized classes
    rClear;

    if nargin == 2
        % update monitorWidth, viewingDistance in dXscreen
        rSet('dXscreen', 1, 'monitorWidth', monitorWidth, ...
            'viewingDistance', viewingDistance);
    end

    % call rGraphicsGetScreenAtributes for values
    [wn, sr, ppd, fr] = rGraphicsGetScreenAttributes;

    % package them into a string and send
    sendMsg(sprintf( ...
        'wn_=%d;sr_=[%d %d %d %d];ppd_=%.3f;fr_=%d;',wn, sr, ppd, fr));
end
