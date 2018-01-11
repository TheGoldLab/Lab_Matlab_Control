classdef dotsDrawableTargets < dotsDrawableVertices
    % @class dotsDrawableTargets
    % Draw one or multiple polygon target at once.
    properties
        % an x-coordinate for each target (degrees visual angle, centered)
        xCenter = 0;
        
        % a y-coordinate for each target (degrees visual angle, centered)
        yCenter = 0;
        
        % the width of each target (degrees visual angle)
        width = 1;
        
        % the height of each target (degrees visual angle)
        height = 1;
        
        % the number of sides for each target polygon (at least 3)
        nSides = 30;
        
        % whether polygons are inscribed(true) or circumscribed(false)
        isInscribed = true;
    end
    
    properties (SetAccess = protected)
        % how many vertices make up each target (same for all targets)
        verticesPerTarget;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawableTargets()
            self = self@dotsDrawableVertices();
            
            % draw as triangles
            self.primitive = 6;
            
            % build triangles from default properties
            self.updatePolygons();
            
            % color in vertices as one group per arc
            self.isColorByVertexGroup = true;
        end
        
        % Keep track of polygon changes.
        function set.xCenter(self, xCenter)
            self.xCenter = xCenter;
            self.updatePolygons();
        end
        
        % Keep track of polygon changes.
        function set.yCenter(self, yCenter)
            self.yCenter = yCenter;
            self.updatePolygons();
        end
        
        % Keep track of polygon changes.
        function set.width(self, width)
            self.width = width;
            self.updatePolygons();
        end
        
        % Keep track of polygon changes.
        function set.height(self, height)
            self.height = height;
            self.updatePolygons();
        end
        
        % Keep track of polygon changes.
        function set.nSides(self, nSides)
            self.nSides = max(nSides, 3);
            self.updatePolygons();
        end
        
        % Keep track of polygon changes.
        function set.isInscribed(self, isInscribed)
            self.isInscribed = isInscribed;
            self.updatePolygons();
        end
    end
    
    methods (Access = protected)
        % Calculate triangle vertex positions to make up polygons.
        function updatePolygons(self)
            [x, y, indices] = makePolygons(self.xCenter, self.yCenter, ...
                self.width, self.height, self.nSides, self.isInscribed);
            if ~isempty(x)
                self.x = x(:);
                self.y = y(:);
                
                % shift indices from 1-based to 0-based
                self.indices = indices(:) - 1;
                
                % account for vertices used in each arc
                self.verticesPerTarget = self.nSides;
            end
        end
        
        % Get a 1-based target-specific index for each vertex.
        function groupIndices = getVertexGroupIndices(self)
            nVertices = self.getNVertices();
            groupIndices = ceil((1:nVertices)/(self.verticesPerTarget));
        end
    end
end