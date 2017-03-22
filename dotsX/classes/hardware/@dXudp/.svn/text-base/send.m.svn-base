function send(u, messageString)
% function send(u, messageString)
%
% send method for dXudp class
%
% Sends a message using a modified version of the UDP/IP
% implementation in pnet.c (originally a free download from MATHWORKS).
% pnet needs to be compiled in a MATLAB path directory.
%
% Always sends to remote host at IP address u.remoteIP on port u.port.
% Remote host is proabaly another instance of dXudp, but UDP protocol is
% general, so it could send to anyone (like, even google.com).
%
% Arguments:
%   u               a dXudp instance
%
%   messageString   will only send data of type string
%
% Returns: zilch
%
% Examples:
%   send(u, 'Sit on a potato pan, otis');

% 2006 by Benjamin Heasly
%   University of Pennsylvania

if isstr(messageString)
    matlabUDP('send', messageString);
    u.messageOut = messageString;
else
    disp('dXudp.send would *really* prefer a string');
end