function rRemoteClient
%Start normal running mode for a remote graphics client
%   rRemoteClient
%
%   rRemoteClient will intitialize a DotsX client machine to display
%   stimuli and await UDP messages from e.g. a DotsX server machine.
%
%   When rRemoteClient receives a UDP message, it will try to evaluate it
%   as a string sent to MATLAB's eval() function.
%
%   If the message contains a stimulus drawing command, rRemoteClient will
%   send a return UDP message which contains the stimulus onset time
%   obtained from Screen('Flip', ...).  It will also send a handshake
%   message: the string, 'received'.
%
%   If the message contains no drawing command, rRemoteClient will send one
%   return message: the string, 'handshake'.
%
%   The following sequence illustrates these two types of handshaking
%
%   client receives message with a draw command...
%       evaluates message
%       draws to screen and flips buffers
%       sends return message containing stimulus onset time
%       sends handshake message, 'received'
%   ...
%    client receives a message with no drawing command...
%       evaluates message
%       sends handshake message, 'handshake'
%   ...
%
%   The following will use rRemoteClient to display stimuli specified via
%   UDP by a remote server machine running a DotsX script.
%
%   % On one machine, the client, start listening for UDP messages:
%   rRemoteClient;
%
%   % On another connected machine, the server, send some UDP messages:
%   demoDots;
%
%   See also rInit, demoDots, rRemoteClientDebug, rRemoteClientSimpleHand

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania

% We thought of two approaches to drawing stimuli: a simple frame-by
% frame approach and a more efficient, paired-frame approach:

% Frame-by-frame (what this client does):
% after previous vblank,
% get messages and eval them
% draw stimuli
% flush GL and block until next vblank
% send back timestamp for this frame

% this approach allows timestamp return messages to reflect the flip
% that occurred as a consequence of the most recent messages.  This is
% intuitive and easy to handle on the server side.  But since evaling,
% drawing, and GL flushing happen during the same frame, the CPU and
% GPU must operate in series and we only get about 10ms of eval time per
% 16.7ms frame.  After 10ms, we must wait for an additional vblank.

% Paired-frames
% flush GL with drawings from previous frame
% get messages and eval them
% draw stimuli for this frame
% block until next vblank
% send back timestamp for previous frame

% this approach lets GPU and CPU to operate in parallel, thereby
% allowing ~16ms of eval time per 16.7ms frame.  But since the CPU and
% GPU can't process the same data at the same time, the GPU must
% process data that are one frame old.  Thus, the server's timestamp
% accounting must me more complicated.

% When eval times are less than 10ms, frame-byframe is nicer.
% When eval times are betwen 10ms and 16ms, paired frames is faster and
%   more predictable.
% When eval times are greater than 16ms, both approaches skip frames.

global ROOT_STRUCT

%   Since clients run in 'screen' mode as far as graphics objects are
% concerned, and since we might want to run a client in 'debug' mode,
% there's no call to add 'remoteScreen' mode (and 'remoteScreenDebug').
%   But, since getMsg() and sendMsg() require that a udp socket be open,
% clients must rAdd a dXudp instance.  The instance will be cleaned up with
% its batchable 'done' method.

try
    rInit('local', 'dXudp');
catch
    disp('Failed to initialize rRemoteClient')
    evalin('base', 'e = lasterror')
    Screen('CloseAll')
end

% a handy flag, esp for rGroup
ROOT_STRUCT.isClient = true;

% initialize flags used in loop
draw_flag       = 0;
continue_flag   = true;
flipTime_flag	= false;
lastFlipCleared	= false;

% needed below, possibly before adding draw classes
ROOT_STRUCT.methods.draw = {};
wn = ROOT_STRUCT.windowNumber;

% check on frame timing, especially for continuous drawing mode
%   frame intervals > 105% are deemed skipped
frameLength = 1.05/rGet('dXscreen', 1, 'frameRate');

% keep track of one interframe interval at a time+
vbl     = nan;
lastVbl = nan;

% append a string list of large frame intervals
frameErrorMsg = '';

% execute loop
while continue_flag

    % get remote message
    msg = getMsg;
    if ~isempty(msg)

        % DEBUG .. display message
        %disp(msg)

        % clear draw_flag; can only be set via msg
        draw_flag = -1;

        % evaluate command within try ... catch
        try
            eval(msg);
        catch

            % display bad command
            disp(sprintf('msg is <%s>', msg))

            % clue is in about the prob
            evalin('base', 'e = lasterror')

            continue_flag = false;
        end

        % If we got a draw_flag=0 message,
        %   sleep briefly to give time to the OS
        if wn<=0 || draw_flag == 0
            WaitSecs(0.002);
            draw_flag = 0;
        elseif draw_flag == -1
            draw_flag = 0;
        end

        % handshake here if not return flag ...
        %   note that if return_flag is true, we
        %   send a "flipped" message below before
        %   sending the handshake..
        % jig 7/27/06 moved below draw_flag conditions
        % jig 8/01/06 added ~draw_flag condition, to send both
        %       return flag and handshake here if return_flag but
        %       no draw_flag

        % bsh 2/14/07 no more return_flag or 'handshake'--just timestamps
        if ~draw_flag
            % send the local 'now' time
            sendMsg(sprintf('%0.4f', GetSecs));
        else
            % send a timestamp after drawing
            flipTime_flag = true;
        end
    end

    % draw ... drawFlag determines behavior
    %   drawFlag = 0 ... no draw, sleep a little
    %   drawFlag = 1 ... draw, clear buffer
    %   drawFlag = 2 ... draw, do NOT clear buffer
    %   drawFlag = 3 ... draw ONCE, clear buffer
    %   drawFlag = 4 ... draw ONCE, do NOT clear buffer
    %   drawFlag = 5 ... flip/clear buffers, call blank
    if wn>0 && draw_flag

        % call class-specific draw methods
        % call Screen('Flip'...)

        % account for vbl timing
        lastVbl = vbl;
        switch draw_flag

            case 1
                for dr = ROOT_STRUCT.methods.draw
                    ROOT_STRUCT.(dr{:}) = draw(ROOT_STRUCT.(dr{:}));
                end
                WaitSecs(0.001);
                vbl = Screen('Flip', wn, 0, 0);
                lastFlipCleared = true;

            case 2
                for dr = ROOT_STRUCT.methods.draw
                    ROOT_STRUCT.(dr{:}) = draw(ROOT_STRUCT.(dr{:}));
                end
                WaitSecs(0.001);
                vbl = Screen('Flip', wn, 0, 1);
                lastFlipCleared = false;

            case 3
                for dr = ROOT_STRUCT.methods.draw
                    ROOT_STRUCT.(dr{:}) = draw(ROOT_STRUCT.(dr{:}));
                end
                vbl = Screen('Flip', wn, 0, 0);
                draw_flag = 0;
                lastFlipCleared = true;

            case 4
                for dr = ROOT_STRUCT.methods.draw
                    ROOT_STRUCT.(dr{:}) = draw(ROOT_STRUCT.(dr{:}));
                end
                vbl = Screen('Flip', wn, 0, 1);
                draw_flag = 0;
                lastFlipCleared = false;

            case 5
                vbl = Screen('Flip', wn, 0, 0);
                if ~lastFlipCleared
                    % the previous flip left graphics onscreen
                    %   this is the real stimulus offset time
                    vbl = Screen('Flip', wn, 0, 0);
                end
                for bl = ROOT_STRUCT.methods.blank
                    ROOT_STRUCT.(bl{:}) = blank(ROOT_STRUCT.(bl{:}));
                end
                draw_flag = 0;
                lastFlipCleared = true;
        end

        if flipTime_flag
            % send the v-blank time of first flip
            %   append any error times
            sendMsg(sprintf('%0.4f%s', vbl, frameErrorMsg));
            frameErrorMsg = '';
            flipTime_flag = false;

        elseif vbl - lastVbl > frameLength

            % account for vbl, possible frame skips
            %   only meaningful during continuous drawing (flags 1 and 2)
            frameErrorMsg = cat(2, frameErrorMsg, ...
                sprintf('/%0.4f@%0.4f', vbl-lastVbl, GetSecs));
        end

    else
        % Would be nice to loop and check for messages like a mofo
        % but that boggs the sys and makes for slow.  So, as long as
        % it won't interfere with stim presentation, sleep a little
        WaitSecs(0.002);
    end
end

% Don't rDone. It may destroy evidence after an error.
Screen('CloseAll')