%% RTDserver
%
% Run this on the server machine to allow it to accept connections. Make
% sure IP addresses match between both computers.

%% Get IP addresses
[clientIP, clientPort, serverIP, serverPort] = RTDconfigureIPs;

%% Start dots
s = dotsTheScreen.theObject;
s.displayIndex = 2;
s.openWindow();

%% Start server
server = dotsEnsembleServer(clientIP,clientPort,serverIP,serverPort);
try
   server.run();   
catch   
   disp('SERVER ERROR')
end