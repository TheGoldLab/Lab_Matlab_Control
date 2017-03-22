classdef topsDrillDownPanel < topsTreePanel
    % Show an item and sub elements, fields, and properties as a tree.
    % @details
    % topsDrillDownPanel shows tree that can drill down into a given "base
    % item".  The user can view and select struct fields, object
    % properties, and cell array elements, to arbitrary depth.  Each
    % selection updates the "current item" of a Tower of Psych GUI.

    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsDrillDownPanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        % @details
        function self = topsDrillDownPanel(varargin)
            self = self@topsTreePanel(varargin{:});
        end
        
        % Create new child nodes for an expanded node.
        % @param tree uitree object or a "peer" object
        % @param value value associated with the expanding node
        % @details
        % Creates new uitreenode objects for a node that is currently
        % expanding, based on the value of baseItem, the sub-path for the
        % expanding node, and any sub-items beneath the expanding node.
        function nodes = childNodesForExpand(self, tree, value)
            % value contains a sub-path for the expanding node
            itemPath = value;
            item = self.subItemFromPath(itemPath);
            
            % drill into the sub-item based on its class and size
            if isstruct(item)
                if numel(item) > 1
                    % for a struct array, break out each element
                    nodes = self.nodesForElements(item, itemPath);
                else
                    % for a struct, break out each field
                    nodes = self.nodesForNamedFields(item, itemPath);
                end
                
            elseif isobject(item)
                if numel(item) > 1
                    % for an object array, break out each element
                    nodes = self.nodesForElements(item, itemPath);
                else
                    % for an object, break out each property
                    nodes = self.nodesForNamedFields(item, itemPath);
                end
                
            elseif iscell(item)
                % for a cell array, break out each element
                nodes = self.nodesForCellElements(item, itemPath);
                
            else
                % for a primitive, make a leaf node
                nodes = self.leafNodeForPrimitive(item, itemPath);
            end
        end
    end
    
    methods (Access = protected)
        
        % Make uitreenode nodes for a scalar struct or object.
        function nodes = nodesForNamedFields(self, item, itemPath)
            % get named sub-fields
            if isstruct(item)
                fields = fieldnames(item);
            else
                fields = properties(item);
            end
            
            % build a node for each named field
            %   and append the drill-down path
            nNodes = numel(fields);
            nodeCell = cell(1, nNodes);
            for ii = 1:nNodes
                subItem = item.(fields{ii});
                subPath = sprintf('.%s', fields{ii});
                fullPath = [itemPath subPath];
                nodeCell{ii} = self.nodeForItem( ...
                    subItem, subPath, fullPath);
            end
            nodes = [nodeCell{:}];
        end
        
        % Make uitreenode nodes for an array.
        function nodes = nodesForElements(self, item, itemPath)
            % build a node for each indexed element
            %   and append the drill-down path
            nNodes = numel(item);
            nodeCell = cell(1, nNodes);
            for ii = 1:nNodes
                subItem = item(ii);
                subPath = sprintf('(%d)', ii);
                fullPath = [itemPath subPath];
                nodeCell{ii} = self.nodeForItem( ...
                    subItem, subPath, fullPath);
            end
            nodes = [nodeCell{:}];
        end
        
        % Make uitreenode nodes for a cell array.
        function nodes = nodesForCellElements(self, item, itemPath)
            % build a node for each indexed cell element
            %   and append the drill-down path
            nNodes = numel(item);
            nodeCell = cell(1, nNodes);
            for ii = 1:nNodes
                subItem = item{ii};
                subPath = sprintf('{%d}', ii);
                fullPath = [itemPath subPath];
                nodeCell{ii} = self.nodeForItem( ...
                    subItem, subPath, fullPath);
            end
            nodes = [nodeCell{:}];
        end
        
        % Make a uitreenode node for a basic item.
        function node = leafNodeForPrimitive(self, item, subPath)
            name = topsGUIUtilities.makeSummaryForItem( ...
                item, self.parentFigure.colors);
            name = sprintf('<HTML>%s</HTML>', name);
            node = uitreenode('v0', subPath, name, [], true);
        end
    end
end