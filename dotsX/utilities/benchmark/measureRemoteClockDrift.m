% how much drift is there between local and remote machine GetSecs clocks?

% clear all
% close all
rInit('remote')

global ROOT_STRUCT

seconds = 60*10;
interval = 30;

clog = nans((seconds/interval), 2);

for ii = 1:(seconds/interval)
    ROOT_STRUCT.dXscreen = endTrial(ROOT_STRUCT.dXscreen);
    
    % sendMsg('%%%%whos your daddy');
    % rcl(ii, 2) = GetSecs;
    % rcl(ii, 1) = sscanf(getMsg(200), '%f');

    WaitSecs(interval);
end

rcl = rGet('dXscreen', 1, 'remoteClockLog');
ll = size(rcl, 1);
plot((1:ll)*interval, rcl(:,1)-rcl(:,2));

xlabel('time of clock check (s)')
ylabel('interclock difference (s)')
title('interclock difference should be small and stationary')