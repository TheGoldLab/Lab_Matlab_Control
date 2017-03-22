classdef topsRegion
    % @class topsRegion
    % Represents a region in a discrete, finite, rectangular space.
    % Provides utilities for working defining and combining regions in the
    % same space.
    % @details
    % topsRegion objects are meant to start out simple and then combine in
    % order to define complex regions.  A simple region partitions its
    % space once, along just one dimension.  Multiple regions can be
    % combined with different logical flavors to produce arbitrary regions.
    % @details
    % For example, a topsRegion might need to represent an rectangle in x-y
    % space.  The rectangle would be a complex region, combining four
    % simple regions:
    %   - an upper partition for the x dimension
    %   - an upper partition for the y dimension
    %   - a lower partition for the x dimension
    %   - a lower partition for the y dimension
    %   .
    % Combining these four regions by intersection would result in a new,
    % complex region with rectanglular shape.

    properties
        % string name to describe the region
        name = '';
    end
    
    properties (SetAccess = protected)
        % space object in which to define a region
        space;
        
        % name of the partitioned dimension of space.
        partitionDimension = '';
        
        % value where the dimension of space is partitioned.
        partitionValue = [];
        
        % comparison operator used to partition the dimension of space.
        partitionComparison = '';
        
        % string describing how the region was formed
        description = '';
        
        % number of points in the region
        nPoints = 0;
        
        % logical index for the region
        selector;
    end
    
    methods
        % Construct a region.
        % @param name a descriptive name for the space
        % @param space a topsSpace object
        % @details
        % All parameters are optional.  If provided, asigns the given @a
        % name and @a space to the new region.
        function self = topsRegion(name, space)
            if nargin >= 1
                self.name = name;
            end
            
            if nargin >= 2
                self = self.setSpace(space);
            end
        end
        
        % Assign the space in which this region lives.
        % @param space a topsSpace object
        % @details
        % Sets the given @a space to this region and does related
        % bookkeeping.  Clears any existing partition.  Returns the updated
        % region object.
        function self = setSpace(self, space)
            self.space = space;
            self.nPoints = 0;
            self.selector = false([space.nDimPoints]);
            self.partitionDimension = '';
            self.partitionValue = [];
            self.partitionComparison = '';
            self.description = '';
        end
        
        % Make a simple partition.
        % @param dimName name of the dimension to partition
        % @param value where along the dimension to place the partition
        % @param comparision how to partition the dimension at @a value
        % @details
        % Based on the given @a dimName, @a value, and @a comparison, fills
        % in the selector for this region.  For example, if @a dimName were
        % 'x', @a value were 0, and @a comparison were ">=", then the
        % selector would be set to true for all points in space where x is
        % greater than or equal to zero.
        % @details
        % @a comparison must be one of the following strings:
        %   - '>': set true for points greater than @a value
        %   - '<': set true for points less than @a value
        %   - '>=': set true for points greater than or equal to @a value
        %   - '<=': set true for points less than or equal to @a value
        %   - '==': set true for points exactly equal to @a value
        %   - '!=': set true for points unequal to @a value
        %   .
        % @details
        % Returns the updated region object. description will be filled in
        % with a description of how the partition was formed.
        function self = setPartition(self, dimName, value, comparison)
            dimInd = strcmp(dimName, self.space.dimNames);
            if ~any(dimInd)
                disp(sprintf('space has no dimension named %s', dimName))
                return;
            end
            dimInd = find(dimInd, 1, 'first');
            
            % remember partition specification
            self.partitionDimension = dimInd;
            self.partitionValue = value;
            self.partitionComparison = comparison;
            
            % locate the partion along the specified dimension
            dimPoints = self.space.dimensions(dimInd).points;
            dimSelector = false(size(dimPoints));
            switch comparison
                case '<'
                    dimSelector = dimPoints < value;
                case '>'
                    dimSelector = dimPoints > value;
                case '<='
                    dimSelector = dimPoints <= value;
                case '>='
                    dimSelector = dimPoints >= value;
                case '=='
                    dimSelector = dimPoints == value;
                case '!='
                    dimSelector = dimPoints ~= value;
            end
            
            % set points in the logical selector
            self.selector(:) = false;
            if any(dimSelector)
                % set partitioned region to true
                spaceInds = {self.space.dimensions.indices};
                spaceInds{dimInd} = find(dimSelector);
                asignStruct = substruct('()', spaceInds);
                self.selector = subsasgn(self.selector, asignStruct, true);
            end
            
            % describe this partition
            valStr = sprintf('%.2g\n', value);
            self.description = [dimName comparison valStr];
            self.nPoints = sum(self.selector(:));
        end
        
        % Combine regions into a complex region.
        % @param regions scalar or array of dotsRegion objects
        % @param operator string indicating how to combine regions
        % @param isInverted whether or not to invert combination results
        % @details
        % Makes one or more @a regions into a single complex object.  @a
        % operator specifies how to combine the selectors of the given @a
        % regions.  @a operator must be one of the following strings:
        %   - 'intersection' combine selectors by logical AND
        %   - 'union' combine selectors by logical OR
        %   .
        % @details
        % @a isInverted is optional.  If @a isInverted is provided and
        % true, the results of the intersection or union will be inverted
        % by a logical NOT.
        % @details
        % Returns a new region object. description will be filled in
        % with a description of how the complex region was formed.
        function complex = combine(regions, operator, isInverted)
            if nargin < 3 || isempty(isInverted)
                isInverted = false;
            end
            
            % use the first region as a template for the complex region
            complex = regions(1);
            
            % clear simple partition info
            complex.partitionDimension = '';
            complex.partitionValue = [];
            complex.partitionComparison = '';
            
            % concatenate selectors along a higher dimension
            grandN = 1 + numel(complex.space.dimensions);
            grandSelector = cat(grandN, regions.selector);
            
            % collapse along the higher dimension to with specified logic
            switch operator
                case 'intersection'
                    complex.selector = all(grandSelector, grandN);
                    format = '%s&';
                    
                case 'union'
                    complex.selector = any(grandSelector, grandN);
                    format = '%s|';
                    
                otherwise
                    disp(sprintf('unknown operator "%s"', operator))
                    return;
            end
            
            % invert the combination results?
            if isInverted
                complex.selector = not(complex.selector);
            end
            
            % describe the combination
            complex.nPoints = sum(complex.selector(:));
            nameCat = sprintf(format, regions.name);
            if isInverted
                complex.description = sprintf('!(%s)', nameCat(1:end-1));
            else
                complex.description = sprintf('(%s)', nameCat(1:end-1));
            end
        end
        
        % Make rectangular partitions.
        % @param xName name of the x/width dimension
        % @param yName name of the y/height dimension
        % @param rect matrix of the form [x y width height], where to place
        % the rectangle in the x-y plane
        % @param inOut string indicating whether to use the inside
        % (default) or outside of @a rect.
        % @details
        % Combines multiple partitions in order to define the specified
        % rectangular region.  @a xName and @a yName must be the names of
        % dimensions in space.  @a rect specifies the borders of the
        % rectangle in the x-y plane.  @inOut must be one of the following
        % strings:
        %	- 'in': set true for points that fall within @a rect or on the
        %	border of @a rect
        %	- 'out': set true for points that fall outside of @a rect
        %   .
        % The default is 'in'.
        % @details
        % Although the rectangle is defined in a plane, the partitioned
        % space may have any number of other dimensions.  In that case, the
        % region will have a higher-dimensional volume and will look like a
        % rectangle in cross-section.
        % @details
        % Returns the updated region object.  description will be filled in
        % with a description of how the rectangle was formed.
        function self = setRectangle(self, xName, yName, rect, inOut)
            % create a partition for each rectangle bound
            xGE = self.setPartition(xName, rect(1), '>=');
            xLE = self.setPartition(xName, rect(1)+rect(3), '<=');
            yGE = self.setPartition(yName, rect(2), '>=');
            yLE = self.setPartition(yName, rect(2)+rect(4), '<=');
            
            % combine the partitions into one region
            regions = [xGE, xLE, yGE, yLE];
            isInverted = nargin >= 5 && strcmp(inOut, 'out');
            self = regions.combine('intersection', isInverted);
            
            rectName = num2str(rect);
            if isInverted
                self.description = sprintf('out[%s]', rectName);
            else
                self.description = sprintf('in[%s]', rectName);
            end
        end
    end
end