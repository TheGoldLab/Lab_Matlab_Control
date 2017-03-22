classdef topsDimension
    % @class topsDimension
    % Represents a discrete, finite spatial dimension.
    % @details
    % Each topsDimension object represents one dimension of a finite,
    % discrete space.  It has evenly spaced points which define the
    % dimension itself, and a descriptive name.

    properties
        % string name to describe the dimension
        name = '';
    end
    
    properties (SetAccess = protected)
        % ordered set of points along the dimension
        points = [];
        
        % number of points along the dimension
        nPoints = 0;
        
        % indexes along the dimension, 1 through nPoints
        indices = [];
        
        % the smallest value
        minimum = 0;
        
        % the largest value
        maximum = 0;
        
        % mean interval between neighboring points
        granularity = 1;
    end
    
    methods
        % Construct a topsDimension with linearly spaced values.
        % @param name a descriptive name for the dimension
        % @param minimum the least value along the dimension
        % @param maximum the greatest value along the dimension
        % @param nPoints the number of values along the dimension
        % @details
        % All parameters are optional.  If @a name is provided, the object
        % will have the given @a name.  If @a minumum, @a maximum, and @a
        % nPoints are provided, the object will have linearly spaced points
        % filled in, spanning @a minumum and @a maximum, inclusive.
        % Otherwise, the object will have no points filled in.
        function self = topsDimension(name, minimum, maximum, nPoints)
            if nargin >= 1
                self.name = name;
            end
            
            if nargin >= 4
                self = self.setPoints(minimum, maximum, nPoints);
            end
        end
        
        % Assign the ordered set of points along this dimension.
        % @param minimum the least value along the dimension
        % @param maximum the greatest value along the dimension
        % @param nPoints the number of values along the dimension
        % @details
        % Computes @a nPoints linearly spaced points, spanning @a minumum
        % and @a maximum, inclusive.  Also does realted bookkeeping.
        % @details
        % Returns the updated topsDimension object.
        function self = setPoints(self, minimum, maximum, nPoints)
            self.points = linspace(minimum, maximum, nPoints);
            self.nPoints = nPoints;
            self.indices = 1:nPoints;
            if self.nPoints > 1
                self.minimum = minimum;
                self.maximum = maximum;
                self.granularity = (maximum - minimum) / (nPoints - 1);
            else
                self.minimum = self.points(1);
                self.maximum = self.points(1);
                self.granularity = 1;
            end
        end
    end
end