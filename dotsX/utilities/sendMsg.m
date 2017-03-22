function sendMsg(messageString)
% function sendMsg(messageString)
%
% Send a message using the UDP/IP implementation in  .mexmac,
% which should be in DotsX/mex.
%
% Arguments:
%   messageString    should send data of type string
%
% Returns: zilch
%
% Examples:
%   sendMsg('Sit on a potato pan, otis');

% 2006 by Benjamin Heasly
%   University of Pennsylvania

% disp(['SENDING :<' messageString '>'])
% disp(sprintf('msg is <%s>', messageString))
% return

matlabUDP('send', messageString);