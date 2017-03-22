function  messageString_ = receive(u)
% function  messageString_ = receive(u)
%
% receive method for dXudp class
%
% Checks for/returns a message using a modified version of the UDP/IP
% implementation in pnet.c (originally a free download from MATHWORKS).
% pnet needs to be compiled in a MATLAB path directory.
%
% Always listens on interprocess communication port u.port.
% Remote host is proabaly another instance of dXudp, but UDP protocol is
% general, so it could receive from anyone (like, even google.com).
%
% Arguments:
%   u               a dXudp instance
%
% Returns: a string containing any message received,
%            may well be an empty string
%
% Examples:
%   returnMessage = receive(u);

% 2006 by Benjamin Heasly
%   University of Pennsylvania

if matlabUDP('check')
    messageString_ = matlabUDP('receive');
    u.messageIn = messageString_;
else
    messageString_ = '';
end