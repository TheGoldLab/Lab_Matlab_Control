classdef dotsAllSocketObjects < handle
    % @class dotsAllSocketObjects
    % An abstract interface for working with sockets.
    % @details
    % dotsAllSocketObjects defines a standard interface for working with
    % network sockets in Snow Dots.  Subclasses of dotsAllSocketObjects are
    % expected to implement a set methods that accomplish socket behaviors.
    % These may be wrappers around mex function calls, for example.
    % @details
    % The purpose of the dotsAllSocketObjects interface is to allow Snow
    % Dots to run on any Matlab platform that has a native sockets
    % implementation.  Each dotsAllSocketObjects subclass must encapsulate
    % the details of the sockets implementation.
    % @details
    % Depending on how socket behaviors are implemented, a subclass may
    % need to define properties, or it may store data with a mex
    % function or elsewhere.  Thus, properties are not expected as part
    % of the dotsAllSocketObjects interface.
    % @details
    % Any Snow Dots function that wants to use network sockets should
    % create an instance of a dotsAllSocketObjects class that is
    % appropriate for the local machine.  The machine-appropriate class
    % should be specified in dotsTheMachineConfiguration, as the default
    % "socketClassName".  This value can be accessed through
    % dotsTheMachineConfiguration.  For example:
    % @code
    % name = dotsTheMachineConfiguration.getDefaultValue('socketClassName')
    % mySocketObject = feval(name);
    % @endcode
    methods (Abstract)
        % Open a new socket and return an identifier for it.
        % @param localIP string IP address to bind on this host
        % @param localPort port number to bind on this host
        % @param remoteIP string IP address to connect to
        % @param remotePort port number to connect to
        % @details
        % Must open an new socket to communicate between the host at @a
        % localIP:@a localPort and @a remoteIP:@a remotePort.
        % @details
        % Must return a nonnegative scalar identifier for the new socket,
        % or a negative scalar to indicate an error.
        id = open(self, localIP, localPort, remoteIP, remotePort);
        
        % Close an open socket.
        % @param id a socket identifier as returned from open()
        % @details
        % Must close a previosuly opened socket and free resources as
        % needed.
        % @details
        % Must return a nonnegative scalar, or a negative scalar to
        % indicate an error.
        status = close(self, id);
        
        % Close all open sockets.
        % @details
        % Must close all sockets that were opened with open() and free all
        % socket resources.
        % @details
        % Must return a nonnegative scalar, or a negative scalar to
        % indicate an error.
        status = closeAll(self);
        
        % Check whether a socket has a packet to read.
        % @param id a socket identifier as returned from open()
        % @param timeoutSecs optional time to wait for a packet
        % @details
        % Must return true if the @a id socket has a data ready to read,
        % or false if it has none.  @a if timeoutSecs is provided, may
        % block, waiting for a packet for that many seconds.  Otherwise,
        % must not block.
        % @details
        % check() must leave any available packet in place, to be consumed
        % during the next read().
        hasData = check(self, id, timeoutSecs);
        
        % Read byte data from a socket.
        % @param id a socket identifier as returned from open()
        % @details
        % Must read, consume, and return data available at the @id socket.
        % The data might have had any type initially, but should be treated
        % here as an array of uint8 (single bytes).
        % @details
        % For UDP sockets, readBytes() should consume one available packet
        % buffered at the socket.
        % @details
        % If the socket has no data, readBytes() shoud return an empty
        % array immediately.  Must not block.
        data = readBytes(self, id);
        
        % Write byte data to a socket.
        % @param id a socket identifier as returned from open()
        % @param data an array of data to send
        % @details
        % Must send @a data from the @id socket to its connected remote
        % host.  @a data might have any type, but should be treated here as
        % an array of uint8 (single bytes).
        % @details
        % For UDP sockets, write() should write the contents of @a data to
        % a single packet and send it immediately.
        % @details
        % Must return a nonnegative scalar, or a negative scalar to
        % indicate an error.  Must not block.
        status = writeBytes(self, id, data);
    end
end