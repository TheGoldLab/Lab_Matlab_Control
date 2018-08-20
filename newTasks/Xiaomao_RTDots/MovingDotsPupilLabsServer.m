%% MovingDotsPupilLabsServer
%
% Run this on the server machine to allow it to accept connections. Make
% sure IP addresses match between both computers.

%% Set IP addresses
clientIP = '158.130.221.199';
clientPort = 30000;
serverIP = '158.130.217.154';
serverPort = 30001;

%% Start dots
s = dotsTheScreen.theObject;
s.displayIndex = 2;
s.openWindow();

%% Start server
server = dotsEnsembleServer(clientIP,clientPort,serverIP,serverPort);
server.run();