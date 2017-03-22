classdef topsSpace
    % @class topsSpace
    % Represents a discrete, finite, rectangular space, of multiple
    % dimensions.  Provides utilities for working with the space.
    % @details
    % Each topsSpace object represents a finite, discrete rectangular
    % space.
    
    properties
        % string name to describe the space
        name = '';
    end
    
    properties (SetAccess = protected)
        % set of dimensions that make up the space
        dimensions;
        
        % number of points in the whole space
        nPoints = 0;
        
        % number of points in each dimension
        nDimPoints;
        
        % name of each dimension
        dimNames;
        
        % subscript coefficients for each dimension
        subscriptCoefs;
        
        % minumum value for each dimension
        minimums;
        
        % maximum value for each dimension
        maximums;
        
        % granularity for each dimension
        granularities;
    end
    
    methods
        % Construct a space.
        % @param name a descriptive name for the space
        % @param dimensions array of topsDimension objects
        % @details
        % All parameters are optional.  If provided, asigns the given @a
        % name and @a dimensions to the new space.
        function self = topsSpace(name, dimensions)
            if nargin >= 1
                self.name = name;
            end
            
            if nargin >= 2
                self = self.setDimensions(dimensions);
            end
        end
        
        % Assign the set of dimensions that make up the space.
        % @param dimensions array of topsDimension objects
        % @details
        % Assigns the given @a dimensions to this object and does realted
        % bookkeeping.
        % @details
        % Returns the updated topsSpace object.
        function self = setDimensions(self, dimensions)
            self.dimensions = dimensions;
            self.nPoints = prod([self.dimensions.nPoints]);
            
            % Cache arrays of dimension properties for access speed
            self.nDimPoints = [self.dimensions.nPoints];
            self.dimNames = {self.dimensions.name};
            self.subscriptCoefs = ...
                cumprod([1, self.dimensions(1:end-1).nPoints]);
            self.minimums = [self.dimensions.minimum];
            self.maximums = [self.dimensions.maximum];
            self.granularities = [self.dimensions.granularity];
        end
        
        % Get dimension subscripts from raw values.
        % @param values array with one value per dimension
        % @details
        % @a values must contain one value for each dimension in the space.
        % Returns an array of subscripts with one subscript per dimension.
        % The subscript for each dimension is the index into that dimension
        % of the point closes to the given value.  Subscripts range from 1
        % to nPoints for each dimension.
        function subscripts = subscriptsForValues(self, values)
            % convert raw values to index integers linearly
            subscripts = ...
                1 + round((values - self.minimums) ./ self.granularities);
            
            % clip subscripts at 1 and nPoints for each dimension
            isHigh = subscripts > self.nDimPoints;
            subscripts(isHigh) = self.nDimPoints(isHigh);
            isLow = subscripts < 1;
            subscripts(isLow) = 1;
        end
        
        % Get dimension values from subscripts.
        % @param subscripts array with one subscript per dimension
        % @details
        % @a subscripts must contain one value for each dimension in the
        % space.  Each subscript should be in the range 1 through nPoints
        % for that dimension.  Returns an array of values values with one
        % point from each dimension.
        function values = valuesForSubscripts(self, subscripts)
            values = ...
                self.minimums + ((subscripts - 1) .* self.granularities);
        end
        
        % Get a grand space index from dimension subscripts.
        % @param subscripts array with one subscript per dimension
        % @details
        % @a subscripts must contain one value for each dimension in the
        % space.  Each subscript should be in the range 1 through nPoints
        % for that dimension.  Returns the grand index computed from all of
        % the subscripts.  The grand index will be in the range 1 through
        % nPoints.
        function grandIndex = indexForSubscripts(self, subscripts)
            grandIndex = 1 + sum((subscripts-1) .* self.subscriptCoefs);
        end
        
        % Get dimension subscripts from a grand space index.
        % @param grandIndex a grand index into the space
        % @details
        % @a grandIndex must be a one-dimensional index into the space, in
        % the range 1 through nPoints.  Returns subscripts for indivudual
        % dimensions, corresponding to @a grandIndex.  Each subscript will
        % be in the range 1 through nPoints, for that dimension.
        function subscripts = subscriptsForIndex(self, grandIndex)
            remainders = floor((grandIndex - 1) ./ self.subscriptCoefs);
            subscripts = 1 + mod(remainders, self.nDimPoints);
        end
    end
end