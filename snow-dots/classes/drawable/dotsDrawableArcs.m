classdef dotsDrawableArcs < dotsDrawable
   % @class dotsDrawableArcs
   % Draw one or multiple arcs at once.
   % @details
   % uses Screen 'DrawArc', 'FillArc', and 'FrameArc' commands
   
   properties
      
      % colors: scalar or [r g b] or [r g b a]
      colors = [1 0 0];

      % Center x position
      xCenter = 0;
      
      % Center y position
      yCenter = 0;
      
      % Width of drawing rect
      width = [];
      
      % Height of drawing rect
      height = [];
      
      % pen width, in pixels, for FrameRect and FrameOval
      penWidth = 1;
      
      % pen height, in pixels, for FrameOval
      penHeight = 1;
      
      % Clockwise, from vertical (in degrees)
      startAngle = 0;
      
      % Clockwise, from vertical (in degrees)
      sweepAngle = 0;
      
      % (string) type: 'DrawArc', 'FillArc', or 'FrameArc'
      arcType = 'DrawArc';
   end
    
   methods
      % Constructor takes no arguments.
      function self = dotsDrawableArcs()
         self = self@dotsDrawable();
      end
      
      % draw it
      function draw(self)
         
         % Use screen with type and collected arguments
         theScreen = dotsTheScreen.theObject();
         rect      = theScreen.getRect(self.xCenter, self.yCenter, ...
            self.width, self.height);
         
         switch(self.arcType)
            
            case 'DrawArc'
               Screen('DrawArc', theScreen.windowPointer, ...
                  self.colors, rect, ...
                  self.startAngle, self.sweepAngle);
            
            case 'FrameArc'
               Screen('FrameArc', theScreen.windowPointer, ...
                  self.colors, rect, ...
                  self.startAngle, self.sweepAngle, ...
                  self.penWidth, self.penHeight);
            
            case 'FillArc'
               Screen('FillArc', theScreen.windowPointer, ...
                  self.colors, rect, ...
                  self.startAngle, self.sweepAngle);
         end
      end
   end
end