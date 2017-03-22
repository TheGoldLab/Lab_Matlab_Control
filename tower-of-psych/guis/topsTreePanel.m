classdef topsTreePanel < topsPanel
    % Show an collection of items with a tree browser.
    % @details
    % topsTreePanel shows tree that can browse items connected to baseItem.
    % The user can select individual nodes of the tree to set the
    % currentItem for a Tower of Psych GUI.
    
    properties
        % how far to expand the tree automatically when building it
        autoExpandDepth = 1;
    end
    
    properties (SetAccess = protected)
        % the uitree for displaying items connected to baseItem
        tree;
        
        % the graphical container of the tree
        treeContainer;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsTreePanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        % @details
        function self = topsTreePanel(varargin)
            self = self@topsPanel(varargin{:});
            self.isLocked = true;
        end
        
        % Set the GUI current item from a selected node.
        % @param tree uitree object or a "peer" object
        % @param event event object related to the selection
        % @details
        % Sets the value of the current item for the parent figure, based
        % on the selected node.
        function selectItem(self, tree, event)
            % the current node's value contains a sub-path path
            %   from baseItem to the expanding node
            node = event.getCurrentNode();
            subPath = node.getValue();
            item = self.subItemFromPath(subPath);
            name = sprintf('%s%s', self.baseItemName, subPath);
            self.parentFigure.setCurrentItem(item, name);
        end
        
        % Create new child nodes for an expanded node.
        % @param tree uitree object or a "peer" object
        % @param value value associated with the expanding node
        % @details
        % Must create new uitreenode objects for a node that is currently
        % expanding, based on the value of baseItem, and the sub-path
        % contained by the expanding node.
        function nodes = childNodesForExpand(self, tree, value)
            nodes = [];
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            % put a self reference in the uipanel UserData
            %   this avoids handle references in uitree callbacks
            set(self.pan, 'UserData', self);
            
            % a placeholder root node for uitree creation to succeed
            rootNode = uitreenode('v0', '', 'root', [], true);
            
            % the new tree gets wired up to call panel methods
            [self.tree, self.treeContainer] =...
                self.parentFigure.makeUITree( ...
                self.pan, ...
                rootNode, ...
                {@topsTreePanel.treeExpandCallback, self.pan}, ...
                {@topsTreePanel.treeSelectCallback, self.pan});
            
            % update the tree to use baseItem
            self.updateContents();
        end
        
        % Refresh the panel's contents.
        function updateContents(self)
            % represent baseItem at the uitree root
            rootNode = self.nodeForItem(self.baseItem, ...
                self.baseItemName, '');
            self.tree.setRoot(rootNode);
            
            %expand some nodes right away
            self.expandToDepth(rootNode, self.autoExpandDepth);
        end
        
        % Expand tree nodes to the given depth.
        % @param node a uitree node in the tree
        % @param depth how far down to expand the tree
        % @details
        % Recursively expands all tree nodes, starting with the given @a
        % node, as far down as the given @a depth.  If @a node is the root
        % node, the entire tree can be expanded.  If @a depth is zero, no
        % nodes will be expanded.  If @a depth is one, only the given @a
        % node will be expanded.  If depth is inf, all nodes beneath @a
        % node will be expanded.
        function expandToDepth(self, node, depth)
            if depth > 0
                % expand this node and allow Matlab to update it
                self.tree.expand(node);
                drawnow();
                
                % recur to expand child nodes
                jVector = node.children();
                while jVector.hasMoreElements()
                    child = jVector.nextElement();
                    self.expandToDepth(child, depth - 1);
                end
            end
        end
        
        % Make a new tree node to represent the given item.
        % @param item any item
        % @param name string name for the item
        % @param subPath string sub-path path from baseItem to @a item
        % @details
        % Makes a new uitreenode to represent the given @a item.  @a
        % subPath must be a string to pass to eval(), which contains a
        % reference from baseItem to this item.  For example, if @a item
        % is located in a field of baseItem named 'data', subPath might be
        % '.data', '(1).data', or similar.
        function node = nodeForItem(self, item, name, subPath)
            % display a summary of the item
            name = topsGUIUtilities.makeTitleForItem(item, name, ...
                self.parentFigure.midgroundColor);
            name = sprintf('<HTML>%s</HTML>', name);
            node = uitreenode('v0', subPath, name, [], false);
        end
    end
    
    methods (Static)
        function nodes = treeExpandCallback(tree, event, pan)
            % get the self reference from the uipanel UserData
            %   placed there during initialize()
            self = get(pan, 'UserData');
            
            % go ahead and invoke the "real" expand callback
            nodes = self.childNodesForExpand(tree, event);
        end
        
        function treeSelectCallback(tree, event, pan)
            % get the self reference from the uipanel UserData
            %   placed there during initialize()
            self = get(pan, 'UserData');
            
            % go ahead and invoke the "real" select callback
            self.selectItem(tree, event);
        end
    end
end