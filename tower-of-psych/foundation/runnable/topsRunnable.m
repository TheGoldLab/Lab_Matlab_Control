classdef topsRunnable < topsFoundation
    % @class topsRunnable
    % Superclass for flow-control classes.
    % @details
    % The topsRunnable superclass provides a common interface for Tower
    % of Psych classes that manage flow control.  They organize function
    % calls and log what they call.  Some can combine with each other to
    % make complex control structures.
    % @details
    % Any topsRunnable can be run(), to begin execution.  Sometimes its
    % caller will be set to another topsRunnable, which invoked run() on
    % it.

    properties
        % optional fevalable cell array to invoke just before running
        startFevalable = {};
        
        % optional fevalable cell array to invoke just after running
        finishFevalable = {};
        
        % true or false, whether this object is currently busy running
        isRunning = false;
        
        % topsRunnable that invoked run() on this object, or empty
        caller;

        % string used for topsDataLog entry just before run()
        startString = 'start';
        
        % string used for topsDataLog entry just after run()
        finishString = 'finish';
    end
    
    methods
        % Constuct with name optional.
        % @param name optional name for this object
        % @details
        % If @a name is provided, assigns @a name to this object.
        function self = topsRunnable(varargin)
            self = self@topsFoundation(varargin{:});
        end
        
        % Do flow control.
        % @details
        % run() should take over flow-control from the caller and do custom
        % behaviors.  When it's done doing custom behaviors, the object
        % should set its isRunning property to false.
        % @details
        % Subclasses should redefine run() to do custom behaviors.
        function run(self)
        end
        
        % Show heirarchy of topsRunnable[Composite] objects.
        function g = gui(self)
            g = topsRunnableGUI(self);
        end

        % Log action and prepare to do flow control.
        % @details
        % Subclasses should extend start() to do initialization before
        % running.
        function start(self)
            self.logAction(self.startString);
            self.logFeval(self.startString, self.startFevalable);
            self.isRunning = true;
        end
        
        % Log, action and finish doing flow control.
        % @details
        % Subclasses should extend finish() to do clean up after running.
        function finish(self)
            self.logAction(self.finishString);
            self.logFeval(self.finishString, self.finishFevalable);
            self.isRunning = false;
        end
        
        % Log an event of interest with topsDataLog.
        % @param actionName string name for any event of interest
        % @param actionData optional data to log along with @a actionName
        % @details
        % logAction is a convenient way to note in topsDataLog that some
        % event of interest has occurred.  The log entry will contain the
        % name of this topsRunnable object, concatenated with @a
        % actionName.  It will store @a actionData, if given.
        function logAction(self, actionName, actionData)
            if nargin < 3 || isempty(actionData)
                actionData = [];
            end
            group = sprintf('%s:%s', self.name, actionName);
            data = struct( ...
                'runnableClass', class(self), ...
                'runnableName', self.name, ...
                'actionName', actionName, ...
                'actionData', actionData);
            topsDataLog.logDataInGroup(data, group);
        end
        
        % Log a function call with topsDataLog.
        % @param fevalName string name to give to a function call
        % @param fevalable fevalable cell array specifying a function call
        % @details
        % logFeval is a convenient way to note in topsDataLog that some
        % funciton call of interest has occurred, and then call the
        % function.  The log entry will contain the name of this
        % topsRunnable object, concatenated with @a fevalName.  It will
        % convert the function handle from the first element of @a
        % fevalable to a string and store the string.
        % @details
        % The log entry will not store any of the arguments from the second
        % or later elements of @a fevalable.  This is because the arguments
        % may be handle objects, and Matlab does a bad job of storing large
        % collections of handle objects--both in memory and in .mat files.
        % @details
        % After making a new entry in topsDataLog, logFeval also invokes @a
        % fevalable with the feval() function.
        function logFeval(self, fevalName, fevalable)
            if ~isempty(fevalable)
                group = sprintf('%s:%s', self.name, fevalName);
                func = fevalable{1};
                if isa(func, 'function_handle')
                    func = func2str(func);
                end
                data = struct( ...
                    'runnableClass', class(self), ...
                    'runnableName', self.name, ...
                    'fevalName', fevalName, ...
                    'fevalFunction', func);
                topsDataLog.logDataInGroup(data, group);
                feval(fevalable{:});
            end
        end
    end
end
