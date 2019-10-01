%% runServer
%
% Run this on the server machine to allow it to accept connections. Make
% sure IP addresses match between both computers (set in getIPs).
%
% 5/11/18 written by jig

% could define IP/ports here, but normally just use defaults
% clientIP = 
% clientPort = 
% serverIP =
% serverPort =
% dotsEnsembleServer.runNewServer([],clientIP,clientPort,serverIP,serverPort);

%% Start server
dotsEnsembleServer.runNewServer();
