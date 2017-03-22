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
    end
    
    properties (Hidden)
        % cell array of strings for supported iterationMethods
        validIterationMethods = {'sequential', 'random'};
    end
    
    methods
        % Constuct with name optional.
        % @param name optional name for this object
        % @details
        % If @a name is provided, assigns @a name to this object.
        function self = topsTreeNode(varargin)
            self = self@topsRunnableComposite(varargin{:});
        end

        % Create a new topsTreeNode child and add it beneath this node.
        % @param name optional name for the new child node
        % @details
        % Returns a new topsTreeNode which is a child of this node.
        function child = newChildNode(self, varargin)
            child = topsTreeNode(varargin{:});
            self.addChild(child);
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
                    
                    for jj = childSequence
                        self.children{jj}.caller = self;
                        self.children{jj}.run();
                        self.children{jj}.caller = [];
                    end
                end
                
            catch recurErr
                warning(recurErr.identifier, ...
                    '%s named "%s" failed:\n\t%s', ...
                    class(self), self.name, recurErr.message);
                
                % attempt to clean up despite error
                try
                    self.finish;
                    
                catch finishErr
                    warning(finishErr.identifier, ...
                        '%s named "%s" failed to finish:\n\t%s', ...
                        class(self), self.name, finishErr.message);
                end
                rethrow(recurErr);
            end
            
            self.finish();
        end
    end
end