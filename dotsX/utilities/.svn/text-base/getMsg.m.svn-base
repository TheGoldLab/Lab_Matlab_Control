function messageString_ = getMsg(timeout)
% function messageString_ = getMsg(timeout)
%
% Checks for a message using the UDP/IP implementation in matlabUDP.mexmac,
% which should be in DotsX/mex.
%
% Arguments:
%   timeout ... time, in ms, to keep checking
%
% Returns: a string containing any message received,
%           may well be an empty string.
%
% Examples:
%   returnMessage = getMsg();
%   - OR -
%   returnMessage = getMsg(100); % check for 100 ms for a message

% 2006 by Benjamin Heasly
%   University of Pennsylvania

% messageString_ = 'doNothing;';
% return

if nargin < 1 || isempty(timeout) || timeout < 1
    
    % check once
    if matlabUDP('check')
        messageString_ = matlabUDP('receive');
    else
        messageString_ = '';
    end
    
else
    
    % check until timeout
    start_time = GetSecs;
    while GetSecs - start_time < timeout/1000
        
        if matlabUDP('check')
            messageString_ = matlabUDP('receive');
            return
        end
        
        % pause
        WaitSecs(0.001);
    end

    messageString_ = '';
end