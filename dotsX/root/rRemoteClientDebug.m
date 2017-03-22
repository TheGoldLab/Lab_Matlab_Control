function rRemoteClientDebug
%Start debugging mode for a remote graphics client
%   rRemoteClientDebug
%
%   rRemoteClientDebug will intitialize a DotsX client machine to display
%   stimuli and await UDP messages from e.g. a DotsX server machine.  It
%   behaves just like rRemoteClient.
%
%   Unlike rRemoteClient, rRemoteClientDebug logs every message it receives
%   along with several timestamps taken between each Screen flip.
%   Therefore, it may perform slowly vs rRemoteClient.  The log is
%   stored in the global variable ROOT_STRUCT.clientRecord.
%
%   clientRecord is a n-by-5 cell array where n-1 is the number of times
%   the client has flipped its Screen buffers.  Each row contains three
%   timestamps measured since the previous Screen flip, an m-by-1 cell
%   array of messages received since that flip, and an m-by-1 cell array of
%   evaluation times for each message.  Thus, each row has the form:
%   {   time it took to compute and draw (or blank in drawmode 5) stimuli, ...
%       time since previous flip when blocking on the next flip, ...
%       time since previous flip when next flip returned, ...
%       {1-by-m cell array of messages received since previous flip}, ...
%       {1-by-m cell array of evaluation times for each message} ...
%   }
%
%   The following will use rRemoteClient to display stimuli specified via
%   UDP by a remote server machine running a DotsX script, and display
%   a summary of received messages and drawing timestamps.
%
%   % On one machine, the client, start listening for UDP messages:
%   rRemoteClientDebug;
%
%   % On another connected machine, the server, send some UDP messages:
%   demoDots;
%   rDone(1);
%
%   See also rRemoteClient demoDots, rDone, clientRecordTool

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

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

% allocate a record of process/flip times and associated messages
clientRecord = cell(1e5,5);
cri = 1;
tic;

% execute loop
while continue_flag

    % get remote message
    msg = getMsg;
    if ~isempty(msg)

        % DEBUG .. display message
        %disp(msg)

        % record messages between flips
        clientRecord{cri,4} = cat(1,clientRecord{cri,4},{msg});

        % clear draw_flag; can only be set via msg
        draw_flag = -1;

        % evaluate command within try ... catch
        try
            %t = toc;
            tic
            eval(msg);
            clientRecord{cri,5} = [clientRecord{cri,5};toc];

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
        switch draw_flag

            case 1
                t = toc;
                for dr = ROOT_STRUCT.methods.draw
                    ROOT_STRUCT.(dr{:}) = draw(ROOT_STRUCT.(dr{:}));
                end
                clientRecord{cri,1} = toc-t;

                % record time when ready to wait for flip
                clientRecord{cri,2} = toc;

                WaitSecs(0.001);
                vbl = Screen('Flip', wn, 0, 0);
                lastFlipCleared = true;

                % record time just after we flip, reset timer
                clientRecord{cri,3} = toc;
                tic;
                cri = cri+1;

            case 2
                t = toc;
                for dr = ROOT_STRUCT.methods.draw
                    ROOT_STRUCT.(dr{:}) = draw(ROOT_STRUCT.(dr{:}));
                end
                clientRecord{cri,1} = toc-t;

                % record time when ready to wait for flip
                clientRecord{cri,2} = toc;

                WaitSecs(0.001);
                vbl = Screen('Flip', wn, 0, 1);
                lastFlipCleared = false;

                % record time just after we flip, reset timer
                clientRecord{cri,3} = toc;
                tic;
                cri = cri+1;

            case 3
                t = toc;
                for dr = ROOT_STRUCT.methods.draw
                    ROOT_STRUCT.(dr{:}) = draw(ROOT_STRUCT.(dr{:}));
                end
                clientRecord{cri,1} = toc-t;

                % record time when ready to wait for flip
                clientRecord{cri,2} = toc;
                vbl = Screen('Flip', wn, 0, 0);
                draw_flag = 0;
                lastFlipCleared = true;

                % record time just after we flip, reset timer
                clientRecord{cri,3} = toc;
                tic;
                cri = cri+1;

            case 4
                t = toc;
                for dr = ROOT_STRUCT.methods.draw
                    ROOT_STRUCT.(dr{:}) = draw(ROOT_STRUCT.(dr{:}));
                end
                clientRecord{cri,1} = toc-t;

                % record time when ready to wait for flip
                clientRecord{cri,2} = toc;

                vbl = Screen('Flip', wn, 0, 1);
                draw_flag = 0;
                lastFlipCleared = false;

                % record time just after we flip, reset timer
                clientRecord{cri,3} = toc;
                tic;
                cri = cri+1;

            case 5

                % record time when ready to wait for flip
                clientRecord{cri,2} = toc;

                vbl = Screen('Flip', wn, 0, 0);
                if ~lastFlipCleared
                    vbl = Screen('Flip', wn, 0, 0);
                end

                % record time just after we flip, reset timer
                clientRecord{cri,3} = toc;
                tic;
                cri = cri+1;

                % in draw mode 5, clock blank(), not draw()
                t = toc;
                for bl = ROOT_STRUCT.methods.blank
                    ROOT_STRUCT.(bl{:}) = blank(ROOT_STRUCT.(bl{:}));
                end
                clientRecord{cri,1} = toc-t;

                draw_flag = 0;
                lastFlipCleared = true;
        end

        if flipTime_flag
            % send the v-blank time of first flip
            sendMsg(sprintf('%0.4f', vbl));
            flipTime_flag = false;
        end

    else
        % Would be nice to loop and check for messages like a mofo
        % but that boggs the sys and makes for slow.  So, as long as
        % it won't interfere with stim presentation, sleep a little
        WaitSecs(0.0015);
    end
end

% put message log into global variable
ROOT_STRUCT.clientRecord = clientRecord(1:cri,:);

% Don't rDone. It may destroy evidence after an error.
Screen('CloseAll')

% show performance summary
clientRecordTool