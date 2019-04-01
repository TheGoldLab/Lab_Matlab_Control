classdef topsTreeNode < topsRunnableComposite
   % @class topsTreeNode
   % A tree-like way to organize an experiment.
   % @details
   % topsTreeNode gives you a uniform, tree-like framework for organizing
   % the different components of an experiment.  All levels of
   % organization--trials, sets of trials, tasks, paradigmns, whole
   % experiments--can be represented by interconnected topsTreeNode
   % objects, as one large tree.
   % @details
   % Every node may have other topsTreeNode objects as "children".  You
   % start an experiment by calling run() on the topmost node.  It invokes
   % a "start" function and then calls run() each of its child nodes.
   % Each child does the same, invoking its own "start" function and then
   % invoking run() on each of its children.
   % @details
   % This flow of "start" and run() continues until it reaches the bottom
   % of the tree where there is a node that has no children.  The
   % bottom nodes might be topsRunnable objects of any type, not just
   % topsTreeNode.
   % @details
   % Then it's back up the tree.  On the way up, each child may invoke its
   % "finish" function before passing control back to the node above it.
   % Once a higher node finishes calling run() all of its children, it may
   % invoke its own "finish" function, and so one, until the flow reaches
   % the topmost node again.  At that point the experiment is done.
   % @details
   % topsTreeNode only treats the structure of an experiment.  The details
   % have to be defined elsewhere, as in specific "start" and "finish"
   % functions, and with bottom nodes of various topsRunnable subclasses.
   % @details
   % Many psychophysics experiments use a tree structure implicitly, along
   % with a similar down-then-up flow of behavior.  topsTreeNode makes
   % the stucture and flow explicit, which offers some advantages:
   %   - You can extend your task structure arbitrarily, without running
   %   out of vocabulary words or hard-coded concepts like "task" "block",
   %   "subblock", "trial", "intertrial", etc.
   %   - You can visualize the structure of your experiment using the
   %   topsTreeNode.gui() method.
   
   properties (SetObservable)
      
      % number of times to run through this node's children
      iterations = 1;
      
      % count of iterations while running
      iterationCount = 0;
      
      % how to run through this node's children--'sequential' or
      % 'random' order
      iterationMethod = 'sequential';
      
      % For any node-specific data
      nodeData = [];
            
      % The helpers
      helpers = struct();
      
      % Flag indicating whether to inherit all helpers from parent
      inheritHelpers = 'all';
      
      % List of helper types
      helperTypes = {'drawable', 'playable', 'readable', 'writable', 'general'};
   end
     
   methods
      
      % Constuct with name optional.
      % @param name optional name for this object
      % @details
      % If @a name is provided, assigns @a name to this object.
      function self = topsTreeNode(varargin)
         
         % ---- Construct with defaults
         %
         self = self@topsRunnableComposite(varargin{:});
         self.iterations = 1; % Go once through the set of tasks

         % ---- Use default snow-dots clock
         %
         if exist('dotsTheMachineConfiguration', 'file')
            self.clockFunction=dotsTheMachineConfiguration.getDefaultValue('clockFunction');
         end
         
         % ---- Create topsCallLists for start/update/finish fevalables
         %
         % These can be filled in by various configuration
         %  subroutines so we don't need to know where what has and has not been
         %  added/configured.
         self.startFevalable = topsCallList.makeFevalable();
         
         % NOTE that the finishFevalables will run in reverse order!!!!!
         self.finishFevalable = topsCallList.makeFevalable(true);
      end
      
      % Create a new topsTreeNode child and add it beneath this node.
      % @param name optional name for the new child node
      % @details
      % Returns a new topsTreeNode which is a child of this node.
      function child = newChildNode(self, varargin)
         child = topsTreeNode(varargin{:});
         self.addChild(child);
      end
      
      % Add a child and process inheritance
      function addChild(self, child)
         
         % Call superclass addChild method
         addChild@topsRunnableComposite(self, child);
         
         % Process child's inheritance: give 'em helpers
         if isa(child, 'topsTreeNode') && ~isempty(child.inheritHelpers)
            
            % Get the list of helpers to inherit
            if ischar(child.inheritHelpers) && strcmp(child.inheritHelpers, 'all')
               inheritedHelpers = fieldnames(self.helpers)';
            else
               inheritedHelpers = makeCellString(child.inheritHelpers);
            end
            
            % Loop through and make copies (remember these are handles)
            for hh = inheritedHelpers               
               if isfield(self.helpers, hh{:})
                  child.helpers.(hh{:}) = self.helpers.(hh{:});
               end
            end
         end
      end

      % Convenient routine to abort running self and children
      function abort(self)
         
         self.isRunning = false;
         
         % Stop children from running any further
         for ii = 1:length(self.children)
            if isa(self.children{ii}, 'topsTreeNode')
               self.children{ii}.abort();
            else
               self.children{ii}.isRunning = false;
            end
         end
      end
      
      % Add fevalable to the start/finish fevalable call list. It's a
      % little bit complicated because you can optionally send in an object
      % to use as the first argument of the fevalabe. This is useful for
      % "binding" helper objects to particular nodes. See topsTaskHelper
      % for examples.
      %
      %  'tag'       ... 'start' or 'finish'
      %  fevalable 	... a cell array that is sent to feval
      %  name        ... string name (default is the current time, to
      %                    ensure uniqueness
      %  theObject   ... optional argument that can be sent as the first
      %                    argument to the function to feval
      function addCall(self, tag, fevalable, name, theObject)
         
         % Check args
         if nargin < 3 || isempty(fevalable)
            return
         end
         
         if strcmp(tag, 'finish')
            theCallList = self.finishFevalable{2};
         else
            theCallList = self.startFevalable{2};
         end
         
         if nargin < 4 || isempty(name)
            name = num2str(datenum(clock));
         end
                
         % Check for object -- if it is here, needs to be put as the second
         %  entry in each fevalable cell array
         if nargin < 5 || isempty(theObject)
            theObject = {};
         else
            theObject = {theObject};
         end
         
         % Add call(s) to start/finish fevalable
         if iscell(fevalable{1})    
            
            % Add many
            for ii = 1:length(fevalable)
               theCallList.addCall(cat(2, fevalable{ii}(1), theObject, ...
                  fevalable{ii}(2:end)), [name num2str(ii)]);
            end
         else
            
            % Add one
            theCallList.addCall(cat(2, fevalable(1), theObject, ...
               fevalable(2:end)), name);
         end
      end         
      
      % Add helper(s) to the node
      %
      % Call with no arguments to add default helpers for the given node,
      % based on properties named in the 'helperTypes' list
      %
      % Otherwise call with the name of the constructor and args, which are
      % sent to topsTaskHelper.makeHelpers
      %
      function theHelpers = addHelpers(self, constructor, varargin)
         
         % Add defaults
         if nargin < 2
            
            % Loop though node-specific specs, making helpers
            for hh = self.helperTypes
               if any(strcmpi(properties(self), hh{:}))
                  self.addHelpers(hh{:}, self.(hh{:}));
               end
            end
            return
         end
         
         % Make the helpers
         theHelpers = topsTaskHelper.makeHelpers(constructor, varargin{:});
         
         % Loop through to save the helpers
         for ff = fieldnames(theHelpers)'
            if isfield(self.helpers, ff{:})
               fprintf('topsTreeNode <%s> overwriting helper <%s>', self.name, ff{:})
            end
            self.helpers.(ff{:}) = theHelpers.(ff{:});
         end
      end
      
      % Find a helper of the named class
      %
      function helper = getHelperByClassName(self, name)
         for ff = fieldnames(self.helpers)'
            if ~isempty(self.helpers.(ff{:}).theObject) && ...
                  isa(self.helpers.(ff{:}).theObject, name)
               helper = self.helpers.(ff{:});
               return
            end
         end
         helper = [];
      end
      
      % Recursively run(), starting with this node.
      % @details
      % Begin traversing the tree with this node as the topmost node.
      % The sequence of events should go like this:
      %   - This node executes its startFevalable
      %   - This node does zero or more "iterations":
      %       - This node calls run() on each of its children,
      %       in an order determined by this node's iterationMethod.
      %       Each child then performs the same sequence of actions as
      %       this node.
      %   - This node executes its finishFevalable
      %   .
      % Note that the sequence of events is recursive.  Thus, the
      % behavior of run() depends on this node as well as its children,
      % their children, etc.
      % @details
      % Also note that the recursion happens in the middle of the
      % sequence of events.  Thus, startFevalables will tend
      % to happen first, with higher node starting before their children.
      % Then finishFevalables will tend to happen last, with children
      % finishing before higher nodes.
      function run(self)
         
         % Check for valid iterations -- we might set this to 0 to abort
         if self.iterations <= 0
            return
         end
         
         % Run the start fevalable
         self.start();
         
         % recursive
         try
            nChildren = length(self.children);
            ii = 0;
            while ii < self.iterations && self.isRunning
               ii = ii + 1;
               self.iterationCount = ii;
               
               switch self.iterationMethod
                  case 'random'
                     childSequence = randperm(nChildren);
                     
                  otherwise
                     childSequence = 1:nChildren;
               end
               
               % Loop through the children
               for jj = childSequence
                  
                  % jig added condition so abort happens gracefully
                  if self.isRunning
                     
                     % disp(sprintf('topsTreeNode: Running <%s> child <%s>, isRunning=%d, iterations=%d', ...
                     %   self.name, self.children{jj}.name, self.isRunning, self.iterations))
                     self.children{jj}.caller = self;
                     self.children{jj}.run();
                     self.children{jj}.caller = [];
                  end
               end
            end
            
         catch recurErr
            
            % Give an error
            warning(recurErr.identifier, ...
               '%s named "%s" failed:\n\t%s', ...
               class(self), self.name, recurErr.message);
            
            % Attempt to clean up despite error
            try
               self.finish();
               
            catch finishErr
               
               % Didn't work
               warning(finishErr.identifier, ...
                  '%s named "%s" failed to finish:\n\t%s', ...
                  class(self), self.name, finishErr.message);
            end
            rethrow(recurErr);
         end
         
         % Run the finish fevalable
         self.finish();
      end
   end
end