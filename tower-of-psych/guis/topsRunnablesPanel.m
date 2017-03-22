classdef topsRunnablesPanel < topsTreePanel
    % Show the high-level structure of a task/game.
    % @details
    % topsRunnablesPanel shows an expanded tree which summarizes all the
    % topsRunnable objects that make up an experiment or game.  The user
    % can select each runnable to view more details about it, and set the
    % curent item of the Tower of Psych GUI.
    
    properties
        % filename for icon that represents topsConcurrent objects
        concurrentIconFile = 'filmIcon.gif';
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsRunnablesPanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        % @details
        function self = topsRunnablesPanel(varargin)
            self = self@topsTreePanel(varargin{:});
            self.autoExpandDepth = inf;
        end
        
        % Create new child nodes for an expanded node.
        % @param tree uitree object or a "peer" object
        % @param value value associated with the expanding node
        % @details
        % Creates new uitreenode objects for a node that is currently
        % expanding, based on the value of the baseItem topsRunnable, the
        % sub-path for the expanding node, and any children beneath the
        % expanding node's runable.
        function nodes = childNodesForExpand(self, tree, value)
            % value contains a sub-path for the expanding node
            itemPath = value;
            runnable = self.subItemFromPath(itemPath);
            nodes = self.nodesForRunnableChildren(runnable, itemPath);
        end
    end
    
    methods (Access = protected)
        % Make uitreenode nodes for a runnable's children, if any.
        function nodes = nodesForRunnableChildren(self, runnable, itemPath)
            if isa(runnable, 'topsRunnableComposite')
                
                % make a node for each child runnable
                nChildren = numel(runnable.children);
                nodeCell = cell(1, nChildren);
                for ii = 1:nChildren
                    child = runnable.children{ii};
                    subPath = sprintf('.children{%d}', ii);
                    fullPath = [itemPath subPath];
                    nodeCell{ii} = self.nodeForRunnable(child, fullPath);
                end
                nodes = [nodeCell{:}];
                
            else
                % no children
                nodes = [];
            end
        end
        
        % Make a uitreenode to represent a topsRunnable object.
        % @param runnable a topsRunnableObject
        % @param name string name for the item
        % @param subPath string sub-path path from baseItem to @a runnable
        % @details
        % Makes a new uitreenode to represent the given @a runnable.
        % Different topsRunnable subclasses may have special formatting.
        function node = nodeForRunnable(self, runnable, subPath)
            % display a summary of the item
            name = topsGUIUtilities.makeTitleForItem( ...
                runnable, runnable.name, self.parentFigure.midgroundColor);
            name = sprintf('<HTML>%s</HTML>', name);
            
            % will this node need to be expanded?
            isParent = isa(runnable, 'topsRunnableComposite') ...
                && numel(runnable.children) > 0;
            
            % what icon should represent this kind of runnable?
            if isa(runnable, 'topsConcurrent')
                iconFile = which(self.concurrentIconFile);
            else
                iconFile = [];
            end
            
            node = uitreenode('v0', subPath, name, iconFile, ~isParent);
        end
    end
end