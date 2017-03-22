classdef dotsEnsembleServer < handle
    % @class dotsEnsembleServer
    % Mirrors dotsClientEnsemble objects from another instance of Matlab.
    % @details
    % dotsEnsembleServer opens a socket and checks for messages sent from
    % dotsClientEnsemble objects created in another Matlab instance.  It
    % creates topsEnsemble objects on the server which mirror the client
    % ensembles.  It can call methods on server objects and return results
    % to the client objects.
    % @details
    % Client-server interactions must be initiated on the client side.  For
    % basic method calls, the client is expected to wait until
    % dotsEnsembleServer reports that it's finished with each action and
    % returns any results.
    % @details
    % dotsEnsembleServer also continuously invokes runBriefly() on those
    % ensemble objects that have isRunning set to true.  This allows client
    % and server ensembles to run concurrent behaviors across Matlab
    % instances.  Invoking run() or start(), and finish(), on a client
    % ensembl controls isRunning for the mirrored server ensemble.
    % @details
    % The runBriefly() behavior of each server ensemble depends on which of
    % its calls are active.  Invoking setActiveByName() or callByName(),
    % with the isActive flag, from the client side controls the behavior of
    % the mirrored server ensemble.
    properties
        % seconds to allow for network communications
        timeout = 1.0;
        
        % seconds to yield periodically to the operating system
        waitTime = 0.0001;
        
        % function that returns the current time as a number
        clockFunction;
    end
    
    properties (SetAccess = protected)
        % IP address of the Snow Dots client
        clientIP;
        
        % network port of the Snow Dots client
        clientPort;
        
        % IP address of this dotsEnsembleServer
        serverIP;
        
        % network port of this dotsEnsembleServer
        serverPort;
        
        % socket identifier for communictions
        socket;
        
        % server side ensemble instances
        ensembles;
        
        % cache ensembles in a cell array for faster access
        ensembleCell;
    end
    
    methods
        % Create an ensemble server with optional network addresses.
        % @param clientIP string IP address of the Snow Dots client
        % @param clientPort network port number of the Snow Dots client
        % @param serverIP string IP address of the ensemble server
        % @param serverPort netowrk port number of the ensemble server
        % @details
        % If @a clientIP, @a clientPort, @a serverIP, and @a serverPort are
        % provided, attempts to connect to a client using the given
        % addresses.  Otherwise,  uses default provided by
        % dotsTheMessenger.
        function self = dotsEnsembleServer( ...
                clientIP, clientPort, serverIP, serverPort)
            
            mc = dotsTheMachineConfiguration.theObject();
            mc.applyClassDefaults(self, mc.defaultGroup);
            
            if nargin >= 4
                % open a socket for the given addresses
                self.setAddresses( ...
                    clientIP, clientPort, serverIP, serverPort);
            else
                % allow default addresses
                self.setAddresses();
            end
            
            % prepare ensembles Map to use string keys
            self.ensembles = containers.Map( ...
                'a', 1, 'uniformValues', false);
            self.ensembles.remove(self.ensembles.keys);
            self.ensembleCell = self.ensembles.values;
        end
        
        % Use the given network addresses for messages.
        % @param clientIP string IP address of the Snow Dots client
        % @param clientPort network port number of the Snow Dots client
        % @param serverIP string IP address of the ensemble server
        % @param serverPort netowrk port number of the ensemble server
        % @details
        % If @a clientIP, @a clientPort, @a serverIP, and @a serverPort are
        % provided, attempts to connect to a client using the given
        % addresses.  Otherwise,  uses default provided by
        % dotsTheMessenger.
        function setAddresses( ...
                self, clientIP, clientPort, serverIP, serverPort)
            if nargin >= 5
                self.clientIP = clientIP;
                self.clientPort = clientPort;
                self.serverIP = serverIP;
                self.serverPort = serverPort;
            end
            self.openSocket();
        end
        
        % Run the server with optional duration.
        % @param duration how long to keep running
        % @details
        % Starts the server running, responding to messages from the client
        % side and invoking runBriefly() on server-side ensembles that have
        % isRunning set to true.
        % @details
        % If @duration is provided, runs for that long, in units of
        % clockFunction, then returns.  By default, runs forever.
        function run(self, duration)
            if nargin < 2
                duration = inf;
            end
            
            wt = self.waitTime;
            cf = self.clockFunction;
            endTime = duration + feval(cf);
            while feval(cf) < endTime
                % Do all pending transactions.
                %   Doing multiple transactions now means the next
                %   runEnsemblesBriefly() will be as up to date as
                %   possible.  This should make ensemble states more
                %   consistent and prevent things like partially updated
                %   graphics.
                status = 1;
                while status > 0
                    status = self.doNextTransaction();
                end
                
                % let ensembles do concurrent behaviors
                self.runEnsemblesBriefly()
                
                % yield time to the operating system
                mglWaitSecs(wt)
            end
        end
        
        % Return to a like-new state.
        % @details
        % Removes all ensembles, and with them all server-side objects.
        % Also re-opens network sockets.  Reset may be invoked directly on
        % the server side, or remotely from the client side, via the
        % appropriate transaction.  Note that the server will reply to the
        % "reset" transaction just before resetting itself.  The server may
        % be unresponsive for a short time after it reposnds.
        function reset(self)
            % Delete existing ensembles.
            self.ensembles.remove(self.ensembles.keys);
            self.ensembleCell = self.ensembles.values;
            
            % Make a fresh socket for messaging.
            self.openSocket();
        end
    end
    
    methods (Access = protected)
        % Get a socket for messages.
        function openSocket(self)
            % delete any stale socket
            m = dotsTheMessenger.theObject();
            m.closeSocket(self.socket);
            
            % default addresses or given addresses?
            if isempty(self.serverIP) || isempty(self.serverPort) ...
                    || isempty(self.clientIP) || isempty(self.clientPort)
                
                self.socket = m.openDefaultServerSocket();
                
            else
                self.socket = m.openSocket( ...
                    self.serverIP, self.serverPort, ...
                    self.clientIP, self.clientPort);
            end
        end
        
        % Do a transaction on self, or delegate a named ensemble.
        % @details
        % This most important method for dotsEnsembleServer.  It checks for
        % a client message, and if there is a message, it carries out the
        % indicated transaction.  The transaction may be one of a few
        % types, related to the server itself, or the ensembles it
        % contains.
        % @details
        % After carrying out a transaction, the server sends a reply to the
        % client (which the client should be waiting for).  The reply
        % contains the original transaction data, plus any data requested
        % in the transaction, plus timing data about the server's behavior.
        % @details
        % Returns the message status from dotsTheMessenger, which is
        % positive there was a transaction to carry out.
        function status = doNextTransaction(self)
            
            % get a message from the client, if any
            m = dotsTheMessenger.theObject();
            [command, status] = m.receiveMessageAtSocket(self.socket);
            
            if status > 0
                
                % put the command in a standard transaction struct
                txn = dotsEnsembleUtilities.getTransactionTemplate();
                txn = dotsEnsembleUtilities.setTransactionParts( ...
                    txn, command);
                
                %disp(txn)
                %disp(' ');
                
                % mark when the server got this transaction
                txn.serverStartTime = feval(self.clockFunction);
                
                isReset = false;
                switch txn.type
                    case 'reset'
                        % defer reset() until after replying to message
                        isReset = true;
                        
                    case 'ensemble'
                        ensemble = topsEnsemble(txn.target);
                        self.ensembles(txn.target) = ensemble;
                        self.ensembleCell = self.ensembles.values;
                        
                    case 'object'
                        % evaluate object factory or constructor
                        object = feval(txn.method);
                        
                        % add the new object to the ensemble
                        %   expect the client to update object state later
                        ensemble = self.ensembles(txn.target);
                        index = ensemble.addObject(object, txn.args);
                        txn.result = index;
                        
                    case 'method'
                        ensemble = self.ensembles(txn.target);
                        if txn.isResult
                            txn.result = feval( ...
                                txn.method, ensemble, txn.args{:});
                        else
                            feval(txn.method, ensemble, txn.args{:});
                        end
                end
                
                % mark when the server finsihed with this transaction
                txn.serverFinishTime = feval(self.clockFunction);
                
                % is client expecting data in reply?
                if (txn.isSynchronized || txn.isResult)
                    [command, result] = ...
                        dotsEnsembleUtilities.getTransactionParts(txn);
                    [status, time] = m.sendMessageFromSocket( ...
                        result, self.socket, self.timeout);
                end
                
                % reset, including sockets, after replying to message
                if isReset
                    self.reset();
                end
            end
        end
        
        % Let each ensemble that isRunning runBriefly().
        function runEnsemblesBriefly(self)
            nEnsembles = numel(self.ensembleCell);
            for ii = 1:nEnsembles
                if self.ensembleCell{ii}.isRunning;
                    self.ensembleCell{ii}.runBriefly();
                end
            end
        end
    end
    
    methods (Static)
        % Create an ensemble server and start it running.
        % @param duration time in seconds to keep running
        % @param clientIP string IP address of the Snow Dots client
        % @param clientPort network port number of the Snow Dots client
        % @param serverIP string IP address of the ensemble server
        % @param serverPort netowrk port number of the ensemble server
        % @details
        % Creates an instance of dotsEnsembleServer and lets it run. If @a
        % duration is provided, runs for that many seconds, otherwise runs
        % forever.
        % @details
        % If @a clientIP, @a clientPort, @a serverIP, and @a serverPort are
        % provided, attempts to connect to a client using the given
        % addresses.  Otherwise, uses default addresses provided by
        % dotsTheMessenger.
        % @deatils
        % runNewServer() will block, busying its Matlab instance, until
        % the server is done running, if ever.
        function runNewServer( ...
                duration, clientIP, clientPort, serverIP, serverPort)
            
            if nargin < 1 || isempty(duration)
                duration = inf;
            end
            
            % attempt to free stale network resources
            evalin('base', 'clear classes');
            evalin('base', 'clear mex');
            
            if nargin >= 5
                % connect to client using given addresses
                server = dotsEnsembleServer( ...
                    clientIP, clientPort, serverIP, serverPort);
            else
                % connect to client using default addresses
                server = dotsEnsembleServer();
            end
            
            disp(' ')
            disp('DOTS ENSEMBLE SERVER IS RUNNING...')
            disp(' ')
            server.run(duration);
        end
    end
end