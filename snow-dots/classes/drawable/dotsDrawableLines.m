classdef dotsDrawableLines < dotsDrawable
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
      
      % Line width: a scalar with the global width for all lines in
      %   pixels (default is 1), or a vector with one separate width
      %   value for each separate line
      width = 1;
      
      % color: a single global color argument for all lines, or an
      %   array of rgb or rgba color values for each line, where each
      %   column corresponds to the color of the corresponding line
      %   start or endpoint in the xy position argument. If you specify
      %   different colors for the start- and endpoint of a line
      %   segment, PTB will generate a smooth transition of colors
      %   along the line via linear interpolation. The default color
      %   is white if colors is omitted.
      colors = [1 0 0];
      
      % flag that determines whether lines should be smoothed:
      %   0 (default) no smoothing
      %   1 smoothing (with anti-aliasing)
      %   2 high quality smoothing.
      % Depends on blending mode
      smooth = 0;
   end
   
   properties (SetAccess = protected)
      
      % for Screen: a two-row vector containing the x and y
      %    coordinates of the line segments: Pairs of consecutive
      %    columns define (x,y) positions of the starts and
      %    ends of line segments
      xy = [];
   end
   
   methods
      % Constructor takes no arguments.
      function self = dotsDrawableLines()
         self = self@dotsDrawable();
         
         % initalize
         self.updateLines();
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
      
      % draw it!
      function draw(self)
         
         % get the window pointer
         theScreen = dotsTheScreen.theObject();
         
         % Call the Screen command
         Screen('DrawLines', theScreen.windowPointer, ...
            self.xy, ...
            self.width, ...
            self.colors, ...
            [theScreen.xScreenCenter, theScreen.yScreenCenter], ...
            self.smooth);
      end
   end
   
   methods (Access = protected)
      
      % Arrange line vertex positions.
      function updateLines(self)
         
         % check for appropriate length vectors
         lengths = [ ...
            numel(self.xFrom), ...
            numel(self.xTo), ...
            numel(self.yFrom), ...
            numel(self.yTo)];
         nLines = max(lengths);
         if all((lengths==1) | (lengths==nLines))
            
            % format as required by DrawLines
            self.xy = zeros(2, nLines*2);
            self.xy(1,1:2:end) = self.xFrom;
            self.xy(1,2:2:end) = self.xTo;
            self.xy(2,1:2:end) = self.yFrom;
            self.xy(2,2:2:end) = self.yTo;

            % get the screen, convert to pixels
            theScreen = dotsTheScreen.theObject();
            self.xy = self.xy.*theScreen.pixelsPerDegree;
         end
      end
   end
end