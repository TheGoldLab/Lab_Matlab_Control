classdef dotsClientEnsemble < topsEnsemble
    % @class dotsClientEnsemble
    % Aggregate objects into an ensemble for remote batch opertaions.
    % @details
    % dotsClientEnsemble is intended as a drop-in substitue for
    % topsEnsemble.  Instead of interacting with objects locally,
    % dotsClientEnsemble acts as a proxy for an ensemble object which it
    % creates in another Matlab instance, via dotsEnsembleUtilities and
    % dotsEnsembleServer.
    % @details
    % dotsClientEnsemble defines some static methods which can be invoked
    % without creating an instance, for example to issue a reset command to
    % a dotsEnsembleServer.
    
    properties
        % seconds to allow for network communications
        timeout = 5.0;
        
        % whether to use strong (true) or weak (false) synchrony
        isSynchronized = false;
    end
    
    properties (SetAccess = protected)
        % IP address of the Snow Dots client
        clientIP;
        
        % network port of the Snow Dots client
        clientPort;
        
        % IP address of the dotsEnsembleServer
        serverIP;
        
        % network port of the dotsEnsembleServer
        serverPort;
        
        % socket identifier for communictions
        socket;
        
        % whether or not this ensemble connected to its server
        isConnected = false;
        
        % status of the most recent transaction
        txnStatus;
        
        % data from the most recent transaction
        txnData;
        
        % whether or not to invoke the Matlab profiler during transactions
        isProfiling = false;
        
        % data returned from the Matlab profiler
        profilingInfo;
    end
    
    methods
        % Constuct with network addresses optional.
        % @param name unique name for this object
        % @param clientIP string IP address of the Snow Dots client
        % @param clientPort network port number of the Snow Dots client
        % @param serverIP string IP address of the ensemble server
        % @param serverPort netowrk port number of the ensemble server
        % @details
        % @a name should be a unique name for this ensemble.  If @a name is
        % provided, assigns @a name to this object.
        % @details
        % If @a clientIP, @a clientPort, @a serverIP, and @a serverPort are
        % provided, attempts to connect to a server using the given
        % addresses.  Otherwise,  uses default provided by
        % dotsTheMessenger.
        function self = dotsClientEnsemble( ...
                name, clientIP, clientPort, serverIP, serverPort)
            
            mc = dotsTheMachineConfiguration.theObject();
            mc.applyClassDefaults(self, mc.defaultGroup);
            
            if nargin >= 1
                self.name = name;
            end
            
            if nargin >= 5
                % open a socket for the given addresses
                self.setAddresses( ...
                    clientIP, clientPort, serverIP, serverPort);
            else
                % allow default addresses
                self.setAddresses();
            end
            
            % tell the server to mirror of this ensemble
            [status, txn] = self.requestServerCounterpart();
            self.txnStatus = status;
            self.txnData = txn;
            self.isConnected = status >= 0;
        end
        
        % Use the given network addresses for messages.
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
        
        
        % Start invoking the Matlab profiler during transactions.
        % @param varargin optional configuraiton arguments to pass to
        % profile()
        % @details
        % startProfiling() clears any old results from the Matlab
        % profiler and sets isProfiling to true.  If provided, @a
        % varargin is passed to the built in profile() for configuration.
        % @details
        % While isProfiling is true, this client ensemble will invoke the
        % Matalb profiler and append data specific to remote transactions.
        function startProfiling(self, varargin)
            self.isProfiling = true;
            profile('on');
            profile('off');
            if nargin > 1
                profile(varargin{:});
            end
        end
        
        % Stop invoking the Matlab profiler during transactions.
        % @details
        % stopProfiling() sets isProfiling to false and stops invoking the
        % Matlab profiler during remote transactions.  Also saves the
        % profiler "info" to profilingInfo.
        function stopProfiling(self)
            self.isProfiling = false;
            profile('off');
            self.profilingInfo = profile('info');
        end
        
        % View Matlab profiler "info" results for transactions.
        % @details
        % viewProfiling() saves any Matlab profiler "info" to profilingInfo
        % and invokes the built-in profview() for viewing
        % the info.
        function viewProfiling(self)
            self.profilingInfo = profile('info');
            profview(0, self.profilingInfo);
        end
        
        % Enable calls to the call list.
        % @details
        % Redefines this topsRunnable list method to work with a remote
        % ensemble server.
        function start(self)
            % invoke start() on the server side
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @start, {}, false);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            self.txnStatus = status;
            self.txnData = txn;
            
            self.start@topsCallList();
        end
        
        % Disable calls to the call list.
        % @details
        % Redefines this topsRunnable method to work with a remote
        % ensemble server.
        function finish(self)
            % invoke finish() on the server side
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @finish, {}, false);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            self.txnStatus = status;
            self.txnData = txn;
            
            self.finish@topsCallList();
        end
        
        % Start running on the server side, until finish().
        % @param duration how long in seconds to keep running
        % @details
        % Redefines this topsConcurrent method to start running on the
        % server side.
        % @details
        % By default, invokes start() on the server side to enable
        % server-side function calls, then returns.  Server-side function
        % calls will continue until finish() is called.
        % @details
        % If @a duration is provided, invokes start() on the
        % server side to enable server-side function calls.  Then blocks
        % for @a duration sectonds.  Once @a duration has elapsed, invokes
        % finish() on the server side to disable server-side function
        % calls, and returns.
        function run(self, duration)
            self.start();
            
            % only block and finish if duration is well-defined
            if nargin >= 2 && ~isempty(duration) && isfinite(duration)
                pause(duration);
                self.finish();
            end
        end
        
        % Invoke active calls on the server side, not the client side.
        % @details
        % Redefines this topsConcurrent method to do nothing on the client
        % side.
        function runBriefly(self)
            % let the server do this
        end
        
        % Add an "fevalable" to the call list.
        % @param fevalable a cell array with contents to pass to feval()
        % @param name unique name to assign to @a fevalable
        % @details
        % Redefines this topsCallList method to work with a remote
        % ensemble server.  @a fevalable should contain primitives, not
        % objects.  The function must be defined and on the path, on the
        % server side.
        function index = addCall(self, varargin)
            isResult = nargout > 0;
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @addCall, varargin, isResult);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            index = txn.result;
            self.txnStatus = status;
            self.txnData = txn;
            
            self.addCall@topsCallList(varargin{:});
        end
        
        % Toggle whether a call is active.
        % @param name given to an fevalable during addCall()
        % @param isActive true or false, whether to invoke the named
        % fevalable during runBriefly()
        % @details
        % Redefines this topsCallList method to work with a remote
        % ensemble server.
        function setActiveByName(self, varargin)
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @setActiveByName, varargin, false);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            self.txnStatus = status;
            self.txnData = txn;
            
            self.setActiveByName@topsCallList(varargin{:});
        end
        
        % Invoke a call now, whether or not it's active.
        % @param name given to an fevalable during addCall()
        % @param isActive whether to activate or un-activate the call at
        % the same time
        % @details
        % Redefines this topsCallList method to work with a remote
        % ensemble server.
        function result = callByName(self, varargin)
            isResult = nargout > 0;
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @callByName, varargin, isResult);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            result = txn.result;
            self.txnStatus = status;
            self.txnData = txn;
            
            % no call on the client side
        end
        
        % Add one object to the ensemble.
        % @param object any object to add to the ensemble
        % @param index optional index where to insert the object
        % @details
        % Redefines this topsEnsemble method to work with a remote
        % ensemble server.
        function index = addObject(self, varargin)
            txn = dotsEnsembleUtilities.makeObjectTransaction( ...
                self, varargin{:});
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            index = txn.result;
            self.txnStatus = status;
            self.txnData = txn;
            
            self.addObject@topsEnsemble(varargin{:});
            
            % transmit the public properties of the new object
            self.updateServerObject(index);
        end
        
        % Remove one or more objects from the ensemble.
        % @param index ensemble object index or indexes
        % @details
        % Redefines this topsEnsemble method to work with a remote
        % ensemble server.
        function object = removeObject(self, varargin)
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @removeObject, varargin, false);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            self.txnStatus = status;
            self.txnData = txn;
            
            % can't transmit object from server
            object = self.removeObject@topsEnsemble(varargin{:});
        end
        
        % Assign one object to a property of one other object.
        % @param innerIndex ensemble index of the object to be assigned
        % @param outerIndex ensemble index of the object that will receive
        % @param varargin asignment specification pased to substruct()
        % @details
        % Redefines this topsEnsemble method to work with a remote
        % ensemble server.
        function assignObject(self, varargin)
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @assignObject, varargin, false);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            self.txnStatus = status;
            self.txnData = txn;
            
            self.assignObject@topsEnsemble(varargin{:});
        end
        
        % Pass one object to a method of another object.
        % @param innerIndex ensemble index of the object to pass
        % @param outerIndex ensemble index of the receiving object
        % @param method function_handle of a receiving object method
        % @param args optional cell array of arguments to pass to @a method
        % @param argIndex optional index into @a args of the object to pass
        % @details
        % Redefines this topsEnsemble method to work with a remote
        % ensemble server.
        function passObject(self, varargin)
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @passObject, varargin, false);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            self.txnStatus = status;
            self.txnData = txn;
            
            % no call on client side
        end
        
        % Set a property for one or more objects.
        % @param property string name of an ensemble object property
        % @param value one value to assign to @a property
        % @param index optional ensemble object index or indexes
        % @details
        % Redefines this topsEnsemble method to work with a remote
        % ensemble server.
        function setObjectProperty(self, varargin)
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @setObjectProperty, varargin, false);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            self.txnStatus = status;
            self.txnData = txn;
            
            self.setObjectProperty@topsEnsemble(varargin{:});
        end
        
        % Get a property value for one or more objects.
        % @param property string name of an ensemble object property
        % @param index optional ensemble object index or indexes
        % @details
        % Redefines this topsEnsemble method to work with a remote
        % ensemble server.
        function value = getObjectProperty(self, varargin)
            isResult = nargout > 0;
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @getObjectProperty, varargin, isResult);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            value = txn.result;
            self.txnStatus = status;
            self.txnData = txn;
            
            % no need to get on client side
        end
        
        % Call a method for one or more objects.
        % @param method function_handle of an ensemble object method
        % @param args optional cell array of arguments to pass to @a method
        % @param index optional ensemble object index or indexes
        % @param isCell optional whether to pass objects in one cell array
        % @details
        % Redefines this topsEnsemble method to work with a remote
        % ensemble server.
        function result = callObjectMethod(self, varargin)
            isResult = nargout > 0;
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @callObjectMethod, varargin, isResult);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            result = txn.result;
            self.txnStatus = status;
            self.txnData = txn;
            
            % no call on client side
        end
        
        % Prepare to repeatedly call a method, for one or more objects.
        % @name name string name given to this automated method call
        % @param method function_handle of an ensemble object method
        % @param args optional cell array of arguments to pass to @a method
        % @param index optional ensemble object index or indexes
        % @param isCell optional whether to pass objects in one cell array
        % @param isActive whether the named method call should be active
        % @details
        % Redefines this topsEnsemble method to work with a remote
        % ensemble server.
        function index = automateObjectMethod(self, varargin)
            isResult = nargout > 0;
            txn = dotsEnsembleUtilities.makeMethodTransaction( ...
                self, @automateObjectMethod, varargin, isResult);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
            index = txn.result;
            self.txnStatus = status;
            self.txnData = txn;
            
            % no automation on client side
        end
    end
    
    methods (Access = protected)
        % Get a socket for messages.
        function openSocket(self)
            % delete any stale socket
            m = dotsTheMessenger.theObject();
            m.closeSocket(self.socket);
            
            if isempty(self.serverIP) || isempty(self.serverPort) ...
                    || isempty(self.clientIP) || isempty(self.clientPort)
                % use default addresses
                self.socket = m.openDefaultClientSocket();
                
            else
                % use addresses assigned to properties
                self.socket = m.openSocket( ...
                    self.clientIP, self.clientPort, ...
                    self.serverIP, self.serverPort);
            end
        end
        
        % Tell the server to create a mirror of this ensemble.
        function [status, txn] = requestServerCounterpart(self)
            txn = dotsEnsembleUtilities.makeEnsembleTransaction(self);
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, self.socket, self.timeout, self.isProfiling);
        end
        
        % Update the indexed object, from client to server.
        % @param index ensemble object index
        % @details
        % Iterates the public properties of the indexed object and sends
        % them one at a time to the server side.  If any transaction fails,
        % returns immediately with the failure status.  Check txnStatus and
        % txnData for details of the bad transaction.
        function status = updateServerObject(self, index)
            % resolve the indexed object
            object = self.getObject(index);
            
            % get public properties of the object
            state = dotsEnsembleUtilities.getManyObjectProperties(object);
            props = fieldnames(state);
            nFields = numel(props);
            status = 0;
            for ii = 1:nFields
                % send each property value to the server
                p = props{ii};
                self.setObjectProperty(p, state.(p), index);
                
                % fail as soon as the first property fails
                status = self.txnStatus;
                if status < 0
                    return;
                end
            end
        end
    end
    
    methods (Static)
        % Tell an ensemble server to reset.
        % @param timeout time in seconds to keep running
        % @param clientIP string IP address of the Snow Dots client
        % @param clientPort network port number of the Snow Dots client
        % @param serverIP string IP address of the ensemble server
        % @param serverPort netowrk port number of the ensemble server
        % @details
        % Commands a remote dotsEnsembleServer to reset.  If @a clientIP,
        % @a clientPort, @a serverIP, and @a serverPort are provided,
        % attempts to connect to the server using the given addresses.
        % Otherwise, uses default addresses provided by dotsTheMessenger.
        % @deatils
        % If @a timeout is provided, waits for that many seconds for the
        % server to report that it's done resetting.  Otherwise uses the
        % default timeout from dotsTheMessenger.  If the sever never
        % reports, returns a negative status.
        % @details
        % Also returns as a second output a struct with details about the
        % remote transaction.
        function [status, txn] = resetServer( ...
                timeout, clientIP, clientPort, serverIP, serverPort)
            
            if nargin < 1 || isempty(timeout)
                timeout = 5.0;
            end
            
            % specified or default server?
            m = dotsTheMessenger.theObject();
            if nargin >= 5
                % socket for the specified addresses
                sock = m.openSocket( ...
                    clientIP, clientPort, serverIP, serverPort);
                
            else
                % socket for default addresses
                sock = m.openDefaultClientSocket();
            end
            
            % prepare a "reset" transaction and send it to the server
            txn = dotsEnsembleUtilities.makeResetTransaction();
            [status, txn] = ...
                dotsClientEnsemble.doSynchronousTransaction( ...
                txn, sock, timeout);
        end
        
        % Block while doing a transaction with an ensemble server.
        % @param txn formatted transaction struct
        % @param socket socket identifier for dotsTheMessenger
        % @param timeout time in seconds to keep running
        % @param isProfiling whether or not to invoke the Matlab profiler
        % @details
        % Does the transaction specified in the given @a txn, with the
        % ensemble server connected to the given @a socket.  @a txn should
        % have the format provided by dotsEnsembleUtilities.
        % @details
        % If @a timeout is provided, allows that many seconds to finish
        % communicating with the server.  Otherwise uses the
        % default timeout from dotsTheMessenger.
        % @details
        % If @a isProfiling is provided and true, invokes the Matlab
        % profiler before starting the transaction, and turns off the
        % profiler afterwards.
        % @details
        % Returns a non-negative status if communication finished within
        % the given @a timeout.  Fills in @a txn with timing details and
        % data received from the server, and returns the updated @a txn as
        % a second output.
        function [status, txn] = doSynchronousTransaction( ...
                txn, socket, timeout, isProfiling)
            
            if nargin >= 4 && isProfiling
                profile('resume');
            end
            
            % mark when the transaction started
            m = dotsTheMessenger.theObject();
            txn.startTime = feval(m.clockFunction);
            
            % send the message on the given socket
            command = dotsEnsembleUtilities.getTransactionParts(txn);
            [status, ackTime] = m.sendMessageFromSocket(command, socket);
            
            % need to wait for results or synchronous behavior?
            if (status > 0) && (txn.isSynchronized || txn.isResult)
                % wait until the server says it's done
                [result, status] = m.receiveMessageAtSocket( ...
                    socket, timeout);
                
                % replace txn with filled-in version from on the server
                if status >= 0
                    txn = dotsEnsembleUtilities.setTransactionParts( ...
                        txn, [], result);
                end
            end
            
            % fill in the last timing details
            txn.acknowledgeTime = ackTime;
            txn.finishTime = feval(m.clockFunction);
            
            if nargin >= 4 && isProfiling
                profile('off');
            end
        end
    end
end
