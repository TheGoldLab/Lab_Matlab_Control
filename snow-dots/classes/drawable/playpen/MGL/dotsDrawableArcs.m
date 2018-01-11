classdef dotsDrawableArcs < dotsDrawableVertices
    % @class dotsDrawableArcs
    % Draw one or multiple arcs at once.
    % @details
    % dotsDrawableArcs uses an OpenGL utility ("GLU") to approximate arcs
    % which fall along the circumference of a circle.
    properties
        % x-coordinate for the center of each arc's circles (degrees visual
        % angle, centered)
        xCenter = 0;
        
        % y-coordinate for the center of each arc's circles (degrees visual
        % angle, centered)
        yCenter = 0;
        
        % radius of each arc's inner circle (degrees visual angle)
        rInner = 4;
        
        % radius of each arc's outer circle (degrees visual angle)
        rOuter = 5;
        
        % where each arc starts along its circle (degrees
        % counterclockwise from rightward)
        startAngle = 0;
        
        % how far all each arc sweeps along its circle (degrees
        % counterclockwise from rightward)
        sweepAngle = 2*pi;
        
        % how many segments make up each arc (same for all arcs)
        nPieces = 30;
    end
    
    properties (SetAccess = protected)
        % how many vertices make up each arc (same for all arcs)
        verticesPerDisk;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawableArcs()
            self = self@dotsDrawableVertices();
            
            % draw as quads
            self.primitive = 8;
            
            % build quads from default properties
            self.updateDisks();
            
            % color in vertices as one group per arc
            self.isColorByVertexGroup = true;
        end
        
        % Keep track of disk changes.
        function set.xCenter(self, xCenter)
            self.xCenter = xCenter;
            self.updateDisks();
        end
        
        % Keep track of disk changes.
        function set.yCenter(self, yCenter)
            self.yCenter = yCenter;
            self.updateDisks();
        end
        
        % Keep track of disk changes.
        function set.rInner(self, rInner)
            self.rInner = rInner;
            self.updateDisks();
        end
        
        % Keep track of disk changes.
        function set.rOuter(self, rOuter)
            self.rOuter = rOuter;
            self.updateDisks();
        end
        
        % Keep track of disk changes.
        function set.startAngle(self, startAngle)
            self.startAngle = startAngle;
            self.updateDisks();
        end
        
        % Keep track of disk changes.
        function set.sweepAngle(self, sweepAngle)
            self.sweepAngle = sweepAngle;
            self.updateDisks();
        end
        
        % Keep track of disk changes.
        function set.nPieces(self, nPieces)
            self.nPieces = nPieces;
            self.updateDisks();
        end
    end
    
    methods (Access = protected)
        % Calculate quad vertex positions to approximate disks.
        function updateDisks(self)
            [x, y, indices] = makeDisks(self.xCenter, self.yCenter, ...
                self.rInner, self.rOuter, ...
                self.startAngle, self.sweepAngle, self.nPieces);
            if ~isempty(x)
                self.x = x(:);
                self.y = y(:);
                
                % shift indices from 1-based to 0-based
                self.indices = indices(:) - 1;
                
                % account for vertices used in each arc
                self.verticesPerDisk = size(x, 1);
            end
        end
        
        % Get a 1-based arc-specific index for each vertex.
        function groupIndices = getVertexGroupIndices(self)
            nVertices = self.getNVertices();
            groupIndices = ceil((1:nVertices)/(self.verticesPerDisk));
        end
    end
end