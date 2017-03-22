classdef dotsEnsembleUtilities
    % @class dotsEnsembleUtilities
    % Static utility methods for working with ensembles.
    % @details
    % dotsEnsembleUtilities provides static methods which can be invoked
    % from either the client or server side.  Some methods define
    % behaviors and conventions that the client and server need to "agree"
    % on.  Others are just utilities for users to call.
    methods (Static)
        % Get an ensemble for local behavior or client behavior.
        % @param name unique name for the new ensemble
        % @param isClient whether or not to make a client-type ensemble
        % @param clientIP string IP address of the Snow Dots client
        % @param clientPort network port number of the Snow Dots client
        % @param serverIP string IP address of the ensemble server
        % @param serverPort netowrk port number of the ensemble server
        % @details
        % Returns a new topsEnsemble object, or a subclass which can act as
        % a client for remote behaviors.  makeEnsemble() is intended to be
        % a "one-liner" which makes it easy for user code to "drop in" one
        % type of of ensemble or the other.
        % @details
        % The new ensemble will use the given @a name.  If @a isClient is
        % provided and true, attempts to return a client-type ensemble.  If
        % @a clientIP, @a clientPort, @a serverIP, and @a serverPort are
        % provided, attempts to connect the client ensemble to a server
        % using the given addresses. Otherwise, uses default addresses
        % provided by dotsTheMessenger.
        % @details
        % If a client ensemble fails to connect to a server, makeEnsemble()
        % issues a warning and returns a basic topsEnsemble object instead.
        % Returns @a isClient as a second argument, updated to match the
        % type of ensemble returned.
        function [ensemble isClient] = makeEnsemble( ...
                name, isClient, clientIP, clientPort, serverIP, serverPort)
            
            if nargin < 2
                isClient = false;
            end
            
            if isClient
                if nargin >= 6
                    % custom addresses
                    ensemble = dotsClientEnsemble( ...
                        name, clientIP, clientPort, serverIP, serverPort);
                else
                    % default addresses
                    ensemble = dotsClientEnsemble(name);
                end
                
                % fall back after failed connection
                if ~ensemble.isConnected
                    isClient = false;
                    ensemble = topsEnsemble(name);
                    warning('dotsEnsembleUtilities:makeEnsemble', ...
                        'Client ensemble could not connect to a server');
                end
            else
                % basic local-only ensemble
                ensemble = topsEnsemble(name);
            end
        end
        
        % Get a struct with a standard transaction format.
        % @details
        % Always returns the same struct, which has all of the correct
        % field names to facilitate communication between a client ensemble
        % and an ensemble server.  All fields start out empty.
        function txn = getTransactionTemplate()
            persistent theTxn
            if isempty(theTxn)
                theTxn = struct( ...
                    'type', '', ...
                    'target', '', ...
                    'method', [], ...
                    'args', {{}}, ...
                    'isResult', false, ...
                    'isSynchronized', false, ...
                    ...
                    'serverStartTime', 0, ...
                    'serverFinishTime', 0, ...
                    'result', [], ...
                    ...
                    'startTime', 0, ...
                    'acknowledgeTime', 0, ...
                    'finishTime', 0);
            end
            txn = theTxn;
        end
        
        % Populate a transaction struct with command and result data.
        % @param txn transaction struct, as from getTransactionTemplate()
        % @param command command data, as from getTransactionParts()
        % @param result result data, as from getTransactionParts()
        % @details
        % Fills in the given @a txn with transaction command and result
        % data given in @a command and @a result.  @a command and @a result
        % are both optional.  Returns the updated @a txn.
        function txn = setTransactionParts(txn, command, result)
            % get transaction data in an easy-to-edit form
            txnCell = struct2cell(txn);
            
            if nargin >= 2 && ~isempty(command)
                % fill in command data
                txnCell(1:6) = command(:);
            end
            
            if nargin >= 3 && ~isempty(result)
                % fill in command data
                txnCell(7:9) = result(:);
            end
            
            % update the transaction struct
            txn = cell2struct(txnCell, fieldnames(txn));
        end
        
        % Extract command and result data from a transaction struct.
        % @param txn transaction struct, as from getTransactionTemplate()
        % @details
        % Extracts subsets of data from the given @a txn.  Returns as the
        % first the first output the transaction's command-related data.
        % Returns as a second output the transaction's result-related data.
        function [command, result] = getTransactionParts(txn)
            txnCell = struct2cell(txn);
            command = txnCell(1:6);
            result = txnCell(7:9);
        end
        
        % Make a reset-server transaction.
        % @details
        % Returns a struct which defines a transaction, telling an ensemble
        % server to reset itself.
        function txn = makeResetTransaction()
            txn = dotsEnsembleUtilities.getTransactionTemplate();
            txn.type = 'reset';
        end
        
        % Make a create-ensemble transaction.
        % @param ensemble a client-side ensemble object
        % @details
        % Returns a struct which defines a transaction, telling an ensemble
        % server to add a new ensemble object.  The new server-size object
        % will mirror the given client-side @a ensemble.
        function txn = makeEnsembleTransaction(ensemble)
            txn = dotsEnsembleUtilities.getTransactionTemplate();
            txn.type = 'ensemble';
            txn.target = ensemble.name;
            txn.isSynchronized = ensemble.isSynchronized;
        end
        
        % Make a create-object transaction.
        % @param ensemble a client-side ensemble object
        % @param object a client-size object which belongs to @a ensemble
        % @param index optional index where to add @a object
        % @details
        % Returns a struct which defines a transaction, telling an ensemble
        % server to add a new object to an ensemble on the server side.
        % The server-side ensemble will be the one that mirrors the given
        % @a ensemble.  Likewise, the new server-size object will mirror
        % the given @a object.  If @a index is provided, the server-size
        % object will be added to the server-size ensemble at @a index.
        function txn = makeObjectTransaction(ensemble, object, index)
            
            % check for singletons, to be created with a factory method
            if ismethod(object, 'theObject')
                constructor = str2func([class(object), '.theObject']);
            else
                constructor = str2func(class(object));
            end
            
            % index where to add the object to the ensemble?
            if nargin < 3
                index = [];
            end
            
            % create a new object for given ensemble, optional index
            txn = dotsEnsembleUtilities.getTransactionTemplate();
            txn.type = 'object';
            txn.target = ensemble.name;
            txn.method = constructor;
            txn.args = index;
            txn.isResult = true;
            txn.isSynchronized = ensemble.isSynchronized;
        end
        
        % Make a method-call transaction.
        % @param ensemble a client-side ensemble object
        % @param funciton handle of a method to call on @a ensemble
        % @param args cell array of arguments to pass to @a method
        % @param isReult whether or not to return a result from @a method
        % @details
        % Returns a struct which defines a transaction, telling an ensemble
        % server to call a method on an ensemble on the server side.  The
        % server-side ensemble will be the one that mirrors the given @a
        % ensemble.  The given @a method will be invoked with the given @a
        % args, on the server side.  If @a isResult is true, the server
        % will capture the first output result from @a method and return it
        % to the client side in the struct's result field.
        function txn = makeMethodTransaction( ...
                ensemble, method, args, isResult)
            % call an ensemble method, with arguments
            txn = dotsEnsembleUtilities.getTransactionTemplate();
            txn.type = 'method';
            txn.target = ensemble.name;
            txn.method = method;
            txn.args = args;
            txn.isResult = isResult;
            txn.isSynchronized = ensemble.isSynchronized;
        end
        
        % Get the public properties of an object as a struct.
        % @param object any object
        % @details
        % Returns a struct summarizing the public properties of @a object.
        % In this case, a "public" property has SetAccess and GetAccess
        % both equal to "public".  It does not matter whether a property is
        % Hidden.  Each struct field name will be the name of a public
        % property, and each field will be filled in with the corresponding
        % property value.
        function propStruct = getManyObjectProperties(object)
            % Find the list of object meta-properties
            %   which depends on Matlab version
            mClass = metaclass(object);
            if isprop(mClass, 'PropertyList')
                propList = mClass.PropertyList;
            else
                propList = [mClass.Properties{:}];
            end
            
            % select only the public properties
            isSettable = strcmp({propList.SetAccess}, 'public');
            isGettable = strcmp({propList.GetAccess}, 'public');
            isPublic = isSettable & isGettable;
            
            % create a struct of property names and values
            nPublic = sum(isPublic);
            names = {propList(isPublic).Name};
            values = cell(1, nPublic);
            for ii = 1:nPublic
                values{ii} = object.(names{ii});
            end
            propStruct = cell2struct(values, names, 2);
        end
        
        % Set the public properties of an object from a struct.
        % @param object any object
        % @param propStruct properties and values in struct form
        % @details
        % Assigns the fields of @a propStruct to the corresponding
        % properties of @a object.  Each field name of @a propStruct must
        % match a property of @a object, and each matching property must
        % have SetAccess equal to "public".
        % dotsEnsembleUtilities.getManyObjectProperties() returns such a
        % struct.
        function setManyObjectProperties(object, propStruct)
            props = fieldnames(propStruct);
            nProps = numel(props);
            for ii = 1:nProps
                p = props{ii};
                object.(p) = propStruct.(p);
            end
        end
    end
end