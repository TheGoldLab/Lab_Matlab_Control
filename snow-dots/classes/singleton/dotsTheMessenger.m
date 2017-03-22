classdef dotsTheMessenger < dotsAllSingletonObjects
    % @class dotsTheMessenger
    % Singleton to handle socket communications.
    % @details
    % dotsTheMessenger uses an instance of dotsAllSocketObjects to do
    % communications between Matlab instances (or looped-back
    % communictaions to the same Matlab instance).  Both Matlab instances
    % are expected to be using dotsTheMessenger.
    % @details
    % dotsTheMessenger improves on basic socket messaging in three ways:
    %   - It isolates the caller from platform-specific details.
    %   - It reduces message shuffling and collisions by waiting for
    %   message acknowledgement codes.
    %   - It reduces message loss by re-sending unacknowledged messages.
    %   .
    %
    
    properties
        % topsGroupedList of info about opened sockets
        socketsInfo;
        
        % any function that returns the current time as a number
        clockFunction;
        
        % time in seconds to wait to receive a message
        % @details
        % Automatically gets the machine-specific default from
        % dotsTheMachineConfiguration.
        receiveTimeout;
        
        % time in seconds to wait for acknowledgement of a sent message
        % @details
        % Automatically gets the machine-specific default from
        % dotsTheMachineConfiguration.
        ackTimeout;
        
        % number of times to resend unacknowledged messages
        % @details
        % Automatically gets the machine-specific default from
        % dotsTheMachineConfiguration.
        sendRetries;
        
        % class name of a dotsAllSocketObjects subclass
        % @details
        % Instantiates an instance of socketClassName to use for opening
        % and closing sockets, and sending and receiving messages.  The
        % named dotsAllSocketObjects subclass should be appropriate for the
        % local hardware, operating system, etc.
        % @details
        % Automatically gets the machine-specific default from
        % dotsTheMachineConfiguration.
        socketClassName;
        
        % string IP address that could be used for a client-side socket
        % @details
        % Automatically gets the machine-specific default from
        % dotsTheMachineConfiguration.
        defaultClientIP;
        
        % string IP address that could be used for a server-side socket
        % @details
        % Automatically gets the machine-specific default from
        % dotsTheMachineConfiguration.
        defaultServerIP;
        
        % port number that could be used for a client-side socket
        % @details
        % Automatically gets the machine-specific default from
        % dotsTheMachineConfiguration.
        defaultClientPort;
        
        % port number that could be used for a server-side socket
        % @details
        % Automatically gets the machine-specific default from
        % dotsTheMachineConfiguration.
        defaultServerPort;
        
        % status code indicating a send message was never acknowqledged
        notAcknowledgedStatus = -111;
        
        % status code indicating no message was received
        notReceivedStatus = -222;
    end
    
    properties (SetAccess = protected)
        % an instance of socketClassName
        % @details
        % The instance of socketClassName that dotsTheMessenger is using
        % for opening and closing sockets, and sending and receiving
        % messages.
        socketObject;
        
        % 1-byte prefix for the previous sent message
        sentPrefix;
        
        % 1-byte prefixs for the previous received message at each socket
        receivedPrefix;
        
        % roll-over value for 1-byte message prefixes
        % @details
        % prefixModulus wants to be 256, but because of Matlab clips
        % integers rather than rolling them over, 255 is easier to work
        % with.  Consider that 255+1 equals 255, not 0.
        prefixModulus = 255;
    end
    
    methods (Access = private)
        % Constructor is private.
        % @details
        % dotsTheMessenger is a singleton object, so its constructor is not
        % accessible.  Use dotsTheMessenger.theObject() to access the
        % current instance.
        function self = dotsTheMessenger(varargin)
            mc = dotsTheMachineConfiguration.theObject();
            mc.applyClassDefaults(self);
            mc.applyClassDefaults(self, mc.defaultGroup);
            self.set(varargin{:});
            self.initialize();
        end
    end
    
    methods (Access = protected)
        % Keep track of the last message prefix received at a socket.
        function setSocketReceivedPrefix(self, sock, prefix)
            ii = sock+1;
            if ii > 0
                self.receivedPrefix(ii) = prefix;
                %disp(sprintf('set receivedPrefix(%d) = %d', ...
                %    ii, self.receivedPrefix(ii)))
            end
        end
        
        % Get the last message prefix received at a socket.
        function prefix = getSocketReceivedPrefix(self, sock)
            ii = sock+1;
            if ii > 0 && ii <= length(self.receivedPrefix)
                prefix = self.receivedPrefix(ii);
            else
                prefix = self.prefixModulus;
            end
        end
    end
    
    methods (Static)
        % Access the current instance.
        function obj = theObject(varargin)
            persistent self
            if isempty(self) || ~isvalid(self)
                constructor = str2func(mfilename);
                self = feval(constructor, varargin{:});
            else
                self.set(varargin{:});
            end
            obj = self;
        end
        
        % Restore the current instance to a fresh state.
        function reset(varargin)
            factory = str2func([mfilename, '.theObject']);
            self = feval(factory, varargin{:});
            self.initialize();
        end
        
        % Launch a graphical interface for messenger properties
        function g = gui()
            self = dotsTheMessenger.theObject;
            g = topsGUIUtilities.openBasicGUI(self);
            set(g.fig, 'Name', mfilename());
        end
        
        % Describe an IP address and socket with one string.
        % @param IP string IP address like '127.0.0.1'
        % @param numeric port number
        % @details
        % Concatnates @a IP and @a port into a single descriptive string,
        % with a colon delimiter between @a IP and @a port.
        function description = describeAddress(IP, port)
            description = sprintf('%s:%d', IP, port);
        end
    end
    
    methods
        % Restore the current instance to a fresh state.
        function initialize(self)
            if isobject(self.socketObject)
                self.socketObject.closeAll();
            end
            self.initializeLists({'socketsInfo'});
            
            self.socketObject = feval(self.socketClassName);
            self.socketObject.closeAll();
            
            self.sentPrefix = uint8(self.prefixModulus);
            self.receivedPrefix = uint8(self.prefixModulus);
        end
        
        % Send a message from the given socket.
        % @param msg variable to send as a message
        % @param sock numeric identifier for a socket, as returned by
        % openSocket()
        % @param ackTimeout seconds to wait for message acknowledgement
        % @param sendRetries number of times to resend if unacknowledged
        % @details
        % Converts @a msg to an array of bytes and sends the bytes from @a
        % sock, to whatever address and port were specified in the call to
        % openSocket().  @a msg must be one of the following variable
        % types:
        %   - double
        %   - char
        %   - logical
        %   - cell
        %   - struct
        %   - function_handle
        %   .
        % If @a msg is a cell or struct, it must compose elements of these
        % types.  Nested cells and structs are supported.  Any @a msg or
        % element that is an array, including cell arrays, should be at
        % most two-dimensional (mxn).  struct arrays should be
        % one-dimenstional (1xn) but may have any number of fields.
        % @details
        % If @a ackTimeout is non-negative, waits for the receiver to send
        % back an acknowledgement of @a msg.  If no acknowledgement arrives
        % within @a ackTimeout seconds, re-sends @a msg.  Waits and
        % re-sends up to @a sendRetries times.  If @a ackTimeout is
        % negative, does not wait for any ancknowledgement.  @a ackTimeout
        % and @a sendRetries may be omitted, in which case the ackTimeout
        % and sendRetries properties are used.
        % @details
        % Returns a status code.  May return notAcknowledgedStatus if the
        % message was sent but never acknowledged. Other negative status
        % indicates an error and that @a msg may not have been sent.
        % @details
        % Also returns as a second output the amount of time spent waiting
        % for message acknowledgement, whether or not it was ever
        % acknowledged, in units of clockFunction.
        function [status, ackTime] = sendMessageFromSocket( ...
                self, msg, sock, ackTimeout, sendRetries)
            
            if nargin < 4 || isempty(ackTimeout)
                ackTimeout = self.ackTimeout;
            end
            
            if nargin < 5 || isempty(sendRetries)
                sendRetries = self.sendRetries;
            end
            
            startTime = feval(self.clockFunction);
            ackTime = 0;
            
            % serialize the message
            [bytes, status] = mxGram('mxToBytes', msg);
            if status < 0
                return;
            end
            
            % send the message prefixed with a 1-byte ack code
            prefix = mod(1+self.sentPrefix, self.prefixModulus);
            self.sentPrefix = prefix;
            prefixedBytes = cat(2, prefix, bytes);
            
            % send and wait for ack code up to (sendRetries + 1) times
            nTries = 0;
            while nTries <= sendRetries
                % send to receiver
                status = self.socketObject.writeBytes(sock, prefixedBytes);
                if status < 0 || ackTimeout < 0
                    return;
                end
                nTries = nTries + 1;
                
                % wait for a reply from the receiver
                hasReply = self.socketObject.check(sock, ackTimeout);
                
                % is the correct ack code waiting at the socket?
                while hasReply
                    reply = self.socketObject.readBytes(sock);
                    if (numel(reply) == 1) && (reply == prefix)
                        % got ack code, all done
                        ackTime = feval(self.clockFunction) - startTime;
                        return;
                    end
                    hasReply = self.socketObject.check(sock, 0);
                end
            end
            
            % never got an acknowledgement
            status = self.notAcknowledgedStatus;
            ackTime = feval(self.clockFunction) - startTime;
        end
        
        % Receive any message that arrived at the given socket.
        % @param sock a numeric identifier for a socket, as returned by
        % openSocket()
        % @param receiveTimeout seconds to wait for a message to arrive
        % @details
        % Waits up to @a receiveTimeout seconds for a message to arrive at
        % the given @a sock.  If a message arrives (or had already
        % arrived), returns the message variable.  Otherwise, returns [].
        % @a receiveTimeout may be omitted, in which case the
        % receiveTimeout property is used.
        % @details
        % Also returns a status code as a second output.  May return
        % notReceivedStatus if no message was available.  May return other
        % negative status codes if there was an error reading from @a sock
        % or decoding message bytes into a variable.
        function [msg, status] = receiveMessageAtSocket( ...
                self, sock, receiveTimeout)
            
            if nargin < 3 || isempty(receiveTimeout)
                receiveTimeout = self.receiveTimeout;
            end
            
            % wait for a message
            recentPrefix = self.getSocketReceivedPrefix(sock);
            while self.socketObject.check(sock, receiveTimeout);
                % read the next message
                %   it must be the right type
                %   it must not have a recent ack code prefix
                % otherwise ignore it
                prefixedBytes = self.socketObject.readBytes(sock);
                if isa(prefixedBytes, 'uint8') ...
                        && numel(prefixedBytes) > 1 ...
                        && prefixedBytes(1) ~= recentPrefix
                    % this is a substantial message
                    
                    % reply with the ack code to the sender
                    self.socketObject.writeBytes(sock, prefixedBytes(1));
                    self.setSocketReceivedPrefix(sock, prefixedBytes(1));
                    
                    % decode the message
                    [msg, status] = ...
                        mxGram('bytesToMx', prefixedBytes(2:end));
                    return;
                end
            end
            
            % never got a message
            status = self.notReceivedStatus;
            msg = [];
        end
        
        % Open a socket for communicating via Ethernet and UDP.
        % @param localIP string IP address for this machine
        % @param localPort integer port number to go with the local IP
        % address
        % @param remoteIP string IP address for this or another machine
        % @param remotePort integer port number to go with the remote IP
        % address
        % @details
        % Opens a network socket connection between ports at two IP
        % addresses. The IP addresses may be the same or different.  @a
        % localIP should be the address of this machine, and may be the
        % "loopback" address, '127.0.0.1'.  The port numbers must be
        % different.
        % @details
        % Returns a numeric identifier for the new UDP connection, suitable
        % for use with sendMessageFromSocket(), receiveMessageAtSocket(),
        % and waitForMessageAtSocket();
        % @details
        % Stores information about each opened socket in socketsInfo
        function sock = openSocket( ...
                self, localIP, localPort, remoteIP, remotePort)
            
            % describe the local and remote addresses
            localName = dotsTheMessenger.describeAddress( ...
                localIP, localPort);
            remoteName = dotsTheMessenger.describeAddress( ...
                remoteIP, remotePort);
            
            % reuse an existing socket that matches
            if self.socketsInfo.containsMnemonicInGroup( ...
                    remoteName, localName)
                sock = self.socketsInfo.getItemFromGroupWithMnemonic( ...
                    localName, remoteName);
                return;
            end
            
            % create a new socket
            sock = self.socketObject.open( ...
                localIP, localPort, ...
                remoteIP, remotePort);
            
            if sock >= 0
                self.socketsInfo.addItemToGroupWithMnemonic( ...
                    sock, localName, remoteName);
                
                self.setSocketReceivedPrefix(sock, self.prefixModulus);
                
            else
                ID = sprintf('%s:%s', class(self), 'openSocket');
                warning(ID, 'failed(%d) to open socket from %s: to %s', ...
                    sock, localName, remoteName);
            end
            
            %disp(sprintf('%d: %s -> %s', sock, localName, remoteName));
        end
        
        % Close a socket.
        % @param sock a numeric identifier for a socket, as returned by
        % openSocket()
        % @details
        % Frees the resources associeted with @a sock.
        % @details
        % Returns a status code.  A negative status code probably indicates
        % that @a sock is not a valid socket identifier.
        % @details
        % Searches socketsInfo for @a sock and removes all instances it
        % finds.
        function status = closeSocket(self, sock)
            if isempty(sock) || sock < 0
                status = 0;
            else
                status = self.socketObject.close(sock);
                self.setSocketReceivedPrefix(sock, self.prefixModulus);
            end
            
            % search for sock and remove it
            groups = self.socketsInfo.groups;
            nGroups = numel(groups);
            for ii = 1:nGroups
                self.socketsInfo.removeItemFromGroup(sock, groups{ii});
            end
        end
        
        % Clear any data messages and inernal accounting for a socket.
        % @param sock a numeric identifier for a socket, as returned by
        % openSocket()
        % @details
        % Reads from @a sock until it has no queued messages and resets
        % dotsTheMessenger's internal accounting for @a sock, but does not
        % close the @a sock.
        % @details
        % Returns a status code.  A negative status code probably indicates
        % that @a sock is not a valid socket identifier.
        function status = flushSocket(self, sock)
            status = 0;
            try
                while self.socketObject.check(sock);
                    self.socketObject.readBytes(sock);
                end
            catch err
                disp(err.message);
                status = -1;
            end
            self.setSocketReceivedPrefix(sock, self.prefixModulus);
        end
        
        % Open a socket with some default "server" properties.
        function sock = openDefaultServerSocket(self)
            sock = self.openSocket( ...
                self.defaultServerIP, self.defaultServerPort, ...
                self.defaultClientIP, self.defaultClientPort);
        end
        
        % Open a socket with some default "client" properties.
        function sock = openDefaultClientSocket(self)
            sock = self.openSocket( ...
                self.defaultClientIP, self.defaultClientPort, ...
                self.defaultServerIP, self.defaultServerPort);
        end
    end
end