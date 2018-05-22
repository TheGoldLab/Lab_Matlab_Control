%% RTDserver
%
% RTD = Response-Time Dots
%
% Run this on the server machine to allow it to accept connections. Make
% sure IP addresses match between both computers (set in RTDconfigureIPs).
%
% 5/11/18 written by jig

%% Get IP addresses
[clientIP, clientPort, serverIP, serverPort] = RTDconfigureIPs;

%% Start server
dotsEnsembleServer.runNewServer([],clientIP,clientPort,serverIP,serverPort);
