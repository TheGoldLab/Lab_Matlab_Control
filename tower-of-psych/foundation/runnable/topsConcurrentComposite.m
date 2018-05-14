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
      
      % logical array indicating whether each child is active
      childIsActive = false(0,0);
      
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
      function addChild(self, child, isActive)
         if isa(child, 'topsConcurrent')
            self.addChild@topsRunnableComposite(child);
            
            % set active flag
            if nargin < 3 || isempty(isActive)
               isActive = true;
            end
            self.childIsActive = cat(2, self.childIsActive, isActive);
         else
            warning('%s cannot add child of class %s', ...
               class(self), class(child));
         end
      end
      
      % Remove a child... need this to update childIsActive array
      function removeChild(self, child)
         index = self.getChildIndex(child);
         if ~isempty(index)
            self.removeChild@topsRunnableComposite(child);
            self.childIsActive(index) = [];
         end
      end
      
      % Get index of given child
      function index = getChildIndex(self, child)
         Lchildren = self.isChild(child);
         if any(Lchildren)
            index = find(Lchildren);
         else
            index = [];
         end
      end
      
      % Get childIsActive flag
      function isActiveFlag = getChildIsActive(self, child)
         isActiveFlag = self.childIsActive(self.getChildIndex(child));
      end
      
      % Set childIsActive flag
      function setChildIsActive(self, child, isActiveFlag)
         if nargin < 2 || isempty(isActiveFlag)
            isActiveFlag = true;
         end
         
         % Get the index
         index = self.getChildIndex(child);
         
         % Set the flag
         self.childIsActive(index) = isActiveFlag;
         
         % Make sure to set the child's isRunning flag according
         %  to the local logical array
         child.isRunning = self.childIsRunning(index);
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
      %
      % 5/8/18 jig added iterations to specify number of times to
      %  iterate through the children while running briefly
      function run(self, iterations)
         
         % check arg
         if nargin < 2 || isempty(iterations)
            iterations = inf;
         end         

         % Run start processes
         self.start();
         self.startChildren();
         self.runBrieflyCount = 0;
         
         % Iterate Run Briefly calls for each child
         while any(self.childIsActive) && self.isRunning && ...
               self.runBrieflyCount < iterations
            self.runBrieflyCount = self.runBrieflyCount + 1;
            self.runChildren();
         end
                                   
         % Run finish processes
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
      % 5/7/18 jig added childIsActive condition
      function runChildren(self)
         nComponents = length(self.children);
         if nComponents > 0
            for ii = 1:nComponents
               if self.childIsActive(ii)
                  self.children{ii}.runBriefly;
                  self.childIsRunning(ii) = ...
                     self.children{ii}.isRunning;
               end
            end
            self.isRunning = all(self.childIsRunning(self.childIsActive));
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