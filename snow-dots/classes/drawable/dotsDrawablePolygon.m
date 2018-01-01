classdef dotsDrawablePolygon < dotsDrawable
   % @class dotsDrawablePolygon
   % Draw a polygon using Screen utilities with PTB
   
   properties
      
      % Colors, n columns x <scalar or [r g b] or [r g b a]>
      color = [1 0 0];
      
      % Array of x values
      x = 0;
      
      % Array of y values
      y = 0;
      
      % pen width, in pixels, for FrameRect and FrameOval
      penWidth = 1;
      
      % for FillPoly
      isConvex = true;
      
      % (string) type: 'FramePoly' or 'FillPoly'
      polyType = 'FillPoly';
   end
   
   methods

      % Constructor takes no arguments.
      function self = dotsDrawablePolygon()
         self = self@dotsDrawable();
      end

      % draw it
      function draw(self)
         
         % Need the windowPointer from theScreen object
         theScreen = dotsTheScreen.theObject();

         switch(self.polyType)
           
            case 'FramePoly'
               Screen('FramePoly', theScreen.windowPointer, ...
                  self.color, [self.x(:) self.y(:)], self.penWidth);
            
            case 'FillPoly'
               Screen('FillPoly', theScreen.windowPointer, ...
                  self.color, [self.x(:) self.y(:)], self.isConvex);
         end         
      end
   end
end
