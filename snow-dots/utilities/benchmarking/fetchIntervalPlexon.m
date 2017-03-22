% Use the Plexon Matalb online client SDK to access strobed word intervals.
% @param option optional string 'init' or 'close' to initalize of close the
% Plexon connection instead of reading data.
% @details
% fetchIntervalPlexon() is intended to be invoked via a
% dotsClientEnsemble, connected to a dotsEnselbleServer which is running on
% a machine with access to the Plexon Matlab client SDK.
% @details
% fetchIntervalPlexon() expects to be initialized the first time its
% called, with @a option equal to 'init'.  It expects to be closed the last
% time its called, with @a option equal to 'close'.  In between, it expects
% to be called multiple times with @a option omitted.
% @details
% Locates the two most recent strobed word timestamps as seen by Plexon and
% returns the interval betwen them.
%
% @ingroup dotsUtilities
function lastInterval = fetchIntervalPlexon(option)
persistent plexonServer

lastInterval = nan;

if nargin && ischar(option)
    % initialize or close the link to the Plexon server,
    %   running on the same machine
    switch option
        case 'init'
            plexonServer = PL_InitClient();
        case 'close'
            PL_Close(plexonServer);
            plexonServer = -1;
    end
    
elseif ~isempty(plexonServer) && plexonServer > 0
    % Wait for Plexon to report two strobed words,
    %   and compute the interval between them
    tic;
    n = 0;
    data = zeros(0,4);
    while n < 2 && toc < .5
        [newN, newData] = PL_GetTS(plexonServer);
        if newN > 0
            n = n+newN;
            data = cat(1, data, newData);
        end
    end
    
    if n >= 2
        strobeChannel = 257;
        isStrobe = data(:,2) == strobeChannel;
        if sum(isStrobe) >= 2
            times = data(isStrobe,4);
            lastInterval = times(end) - times(end-1);
        end
    end
end