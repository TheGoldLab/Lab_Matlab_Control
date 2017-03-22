function sendMsgH(messageString, noWait)
% function sendMsgH(messageString, noWait)
%
% Send a message using the UDP/IP implementation in matlabUDP.mexmac,
% which should be in DotsX/mex.
%
% *H is for handshake -- sends only if we've received a timestamp
%   from the client since the last sendMsgH call.  Timestamp stored in
%   ROOTS_STRUCT.remoteTimestamp.
%
% messageString should be of type char.
%
% If noWait is true, sendMsgH will check once for a timestamp and send
% messageString only if it finds one.  Otherwise, sendMsgH will wait forever,
% yielding CPU time to the OS, until a timestamp arrives.
%
% Returns: zilch
%
% Examples:
%   sendMsgH('Sit on a potato pan, otis');
%
% See also sendMsg, getMsg, getMsgH

% 2006 by Benjamin Heasly
%   University of Pennsylvania

%disp(sprintf('msg is <%s>', messageString))
% return

% No return message received & noWait flag set ... outta
if nargin > 1 && noWait && isempty(getMsgH)
    return % MESSAGE NOT SENT
else
    % wait for 30 minutes
    getMsgH(18e5);
end

% got a timestamp!  Send the message!
matlabUDP('send', messageString);

% disp(sprintf('sendMsgH: sent <%s>', messageString))

% clear the old timestamp
global ROOT_STRUCT
ROOT_STRUCT.remoteTimestamp = [];

% fprintf(ROOT_STRUCT.fid, 'From Server at %.5f:\n\t%s\n\n', ...
%     GetSecs, messageString);