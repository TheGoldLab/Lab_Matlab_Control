classdef dotsDrawableLines < dotsDrawableVertices
    % @class dotsDrawableLines
    % Draw one or multiple lines at once.
    properties
        % a starting x-coordinate for each line (degrees visual angle,
        % centered)
        xFrom = 0;
        
        % an ending x-coordinate for each line (degrees visual angle,
        % centered)
        xTo = 1;
        
        % a starting y-coordinate for each line (degrees visual angle,
        % centered)
        yFrom = 0;
        
        % an ending y-coordinate for each line (degrees visual angle,
        % centered)
        yTo = 1;
    end
    
    properties (SetAccess = protected)
        % how many vertices make up each line (same for all arcs)
        verticesPerLine = 2;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawableLines()
            self = self@dotsDrawableVertices();
            
            % draw as lines
            self.primitive = 3;
            
            % build lines from default properties
            self.updateLines();
            
            % color in vertices as one group per arc
            self.isColorByVertexGroup = true;
        end
        
        % Keep track of line changes.
        function set.xFrom(self, xFrom)
            self.xFrom = xFrom;
            self.updateLines();
        end
        
        % Keep track of line changes.
        function set.xTo(self, xTo)
            self.xTo = xTo;
            self.updateLines();
        end
        
        % Keep track of line changes.
        function set.yFrom(self, yFrom)
            self.yFrom = yFrom;
            self.updateLines();
        end
        
        % Keep track of line changes.
        function set.yTo(self, yTo)
            self.yTo = yTo;
            self.updateLines();
        end
    end
    
    methods (Access = protected)
        % Arrange line vertex positions to approximate disks.
        function updateLines(self)
            lengths = [ ...
                numel(self.xFrom), ...
                numel(self.xTo), ...
                numel(self.yFrom), ...
                numel(self.yTo)];
            nLines = max(lengths);
            if all((lengths==1) | (lengths==nLines))
                nVertices = nLines*2;
                x = zeros(1, nVertices);
                y = zeros(1, nVertices);
                
                x(1:2:end) = self.xFrom;
                x(2:2:end) = self.xTo;
                y(1:2:end) = self.yFrom;
                y(2:2:end) = self.yTo;
                
                self.x = x;
                self.y = y;
            end
        end
        
        % Get a 1-based line-specific index for each vertex.
        function groupIndices = getVertexGroupIndices(self)
            nVertices = self.getNVertices();
            groupIndices = ceil((1:nVertices)/(self.verticesPerLine));
        end
    end
end