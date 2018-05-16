classdef topsConcurrentComposite < topsRunnableComposite
    % @class topsConcurrentComposite
    % Composes topsConcurrent objects and runs them concurrently.
    % @details
    % topsConcurrentComposite objects may contain topsConcurrent objects
    % and run them concurrently.  When a topsConcurrentComposite run()s, it
    % invokes runBriefly() sequentially and repeatedly for each of its
    % component objects.  The topsConcurrentComposite will stop running as
    % soon as one of its children has isRunning equal to false.

    properties
        % logical array reflecting isRunning for each child object
        childIsRunning;
        
        % count of child runBriefly() invocations during the current run()
        runBrieflyCount;

        % string name for topsDataLog entries about runBriefly invokations
        runBrieflyString = 'runBriefly count';
    end
    
    methods
        % Constuct with name optional.
        % @param name optional name for this object
        % @details
        % If @a name is provided, assigns @a name to this object.
        function self = topsConcurrentComposite(varargin)
            self = self@topsRunnableComposite(varargin{:});
        end

        % Add a topsConcurrent child beneath this object.
        % @param child a topsConcurrent to add beneath this object.
        % @details
        % Extends the addChild() method of topsRunnableComposite to verify
        % that @a child is a topsConcurrent (or subclass) object.
        function addChild(self, child)
            if isa(child, 'topsConcurrent')
                self.addChild@topsRunnableComposite(child);
            else
                warning('%s cannot add child of class %s', ...
                    class(self), class(child));
            end
        end
        
        % Interleave runBriefly() behavior of child objects.
        % @details
        % Calls start() for each child object, sets each child's caller
        % to this object, then calls runBriefly() repeatedly and
        % sequentially for each child, until at least one child has
        % isRunning equal to false, then calls finish() for each child and
        % sets each child's caller to be empty.
        % @details
        % The since all the child objects should runBriefly() the same
        % number of times and in an interleaved fashion, they should all
        % appear to run() concurrently.
        function run(self)
            self.start();
            self.startChildren();
            self.runBrieflyCount = 0;
            
            while self.isRunning
                self.runBrieflyCount = self.runBrieflyCount + 1;
                self.runChildren();
            end
            
            self.finishChildren();
            self.finish();
        end
        
        
        % Do a little flow control with each child object.
        % @details
        % Calls runBriefly() once, sequentually, for each child object.
        % @details
        % If any of the child objects has isRunning equal to false, this
        % topsConcurrentComposite object will set its own isRunning to false (and
        % therefore it should stop running).
        function runChildren(self)
            nComponents = length(self.children);
            if nComponents > 0
                for ii = 1:nComponents
                    self.children{ii}.runBriefly;
                    self.childIsRunning(ii) = ...
                        self.children{ii}.isRunning;
                end
                self.isRunning = all(self.childIsRunning);
            else
                self.isRunning = false;
            end
        end
        
        % Prepare each child object to do flow control.
        % @details
        % Calls start() once, sequentually, for each child object.  Sets
        % the caller of each child to this object.
        function startChildren(self)
            for ii = 1:length(self.children)
                self.children{ii}.caller = self;
                self.children{ii}.start;
            end
            self.childIsRunning = true(size(self.children));
        end
        
        % Let each child object finish doing flow control.
        % @details
        % Calls finish() once, sequentually, for each child object.   Sets
        % the caller of each child to be empty.
        function finishChildren(self)
            for ii = 1:length(self.children)
                self.children{ii}.finish;
                self.children{ii}.caller = [];
            end
            self.childIsRunning = false(size(self.children));
        end
        
        % Log action and finish doing flow control.
        % @details
        % Extends the finish() method of topsRunnable to also log the
        % count of runBriefly() invocations.
        function finish(self)
            self.logAction(self.runBrieflyString, self.runBrieflyCount);
            self.finish@topsRunnable;
        end
    end
end