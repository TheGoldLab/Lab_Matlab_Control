function [wn_, sr_, ppd_, fr_] = rRemoteSetup(monitorWidth, viewingDistance)
% function rRemoteSetup
%
% silly overload which allows UDP messaged to be captured locally instead
% of being sent to a remote machine

global ROOT_STRUCT

% % trigger a fake client to send config info
% if nargin == 2
%     sendMsgH(sprintf('rRemoteSetup(%.2f, %.2f)', monitorWidth, viewingDistance));
% else
%     sendMsgH('rRemoteSetup');
% end

% fake some return values
g = rGet('dXscreen', 1);
wn_     = g.windowNumber;
sr_     = g.screenRect;
ppd_	= g.pixelsPerDegree;
fr_     = g.frameRate;

% % trigger fake slave to send over it's local system time
% disp('getting intersystem time offset...')
% round_trip = 100;
% while round_trip > .002
%     % getMsg polls for messages every 2ms so if round_trip < 1ms,
%     % we didn't have to do much waiting, which is good.
% 
%     tic;
%     sendMsg('give time');
%     round_trip = toc;
% end
% 
% ROOT_STRUCT.remoteTimeOffset = round_trip;
% sendMsg('setupDone');
% disp(sprintf('...got it: %0.4f',ROOT_STRUCT.remoteTimeOffset));