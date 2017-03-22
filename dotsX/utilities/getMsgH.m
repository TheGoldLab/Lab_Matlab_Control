function timestamp_ = getMsgH(timeout, flush)
% function timestamp_ = getMsgH(timeout, flush)
%
% Receive a timestamp message using the UDP/IP implementation in
% matlabUDP.mexmac, which should be in DotsX/mex.
%
% Checks for a timestamp return message from a DotsX remote client, using
% the UDP/IP implementation in matlabUDP.mexmac, which should be in
% DotsX/mex.
%
% Corrects the timestamp for the intersystem 'GetSecs' offset.  Returns the
% reslult and also stores it in ROOT_STRUCT.remoteTimeOffset.
%
% Arguments:
%   timeout ... time, in ms, to keep checking
%
% Examples:
%   timestamp = getMsgH();
%   - OR -
%   timestamp = getMsgH(100); % check for 100 ms for a message
%
% See also getMsg, sendMsg, sendMsgH

% 2006 by Benjamin Heasly
%   University of Pennsylvania

if nargin < 2 || isempty(flush)
    flush = false;
end

global ROOT_STRUCT
if isempty(ROOT_STRUCT.remoteTimestamp)

    if ~nargin || isempty(timeout)
        % check once
        timeout = 1;
    end

    % check until timeout
    start_time = GetSecs;
    timestamp_ = [];
    while GetSecs - start_time < timeout/1000
        if matlabUDP('check')

            % get 1 or more numbers
            nums = sscanf(matlabUDP('receive'), '%f%*1s');

            % first number is recent frame vbl time
            timestamp_ = ROOT_STRUCT.remoteTimeOffset + nums(1);
            ROOT_STRUCT.remoteTimestamp = timestamp_;
                            
            % further numbers are pairs of past error times
            %   [... /inter-frame_interval@time_of_skipped_frame ...]
            if size(nums, 1) > 1
                % align frame times with local clock
                nums(1:2:end) = ...
                    nums(1:2:end) + ROOT_STRUCT.remoteTimeOffset;
                
                err.message = 'skipped frames detected on remote client';
                err.remoteTimeOffset = ROOT_STRUCT.remoteTimeOffset;
                err.remoteTimestamp = nums(1);
                err.skipRemoteTimestamps = nums(3:2:end);
                err.skipInterframeIntervals = nums(2:2:end);

                % save timestamps and frame intervals in ROOT_STRUCT
                ROOT_STRUCT.error = ...
                    cat(1, ROOT_STRUCT.error, {GetSecs, err});
            end

            % huhya!
            return
        else
            % yield CPU to OS
            WaitSecs(0.001);
        end
    end
else

    % already got a timestamp since last sendMsgH.
    timestamp_ = ROOT_STRUCT.remoteTimestamp;
end