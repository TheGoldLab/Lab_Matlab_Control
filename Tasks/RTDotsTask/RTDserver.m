%% RTDserver
%
% Run this on the server machine to allow it to accept connections. Make
% sure IP addresses match between both computers.

%% Get IP addresses
[clientIP, clientPort, serverIP, serverPort] = RTDconfigureIPs;

%% Start server
server = dotsEnsembleServer(clientIP,clientPort,serverIP,serverPort);
try
   server.run();
catch   
   disp('SERVER ERROR')
end