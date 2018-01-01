classdef dotsDrawableText < dotsDrawable
   % @class dotsDrawableText
   % Display a string graphically.
   % @details
   % Displays text by converting string into a texture.  Invoke
   % prepareToDrawInWindow() after changing properties like string, color
   % and fontName
   properties
      % x-coordinate for the center of the text (degrees visual
      % angle, centered in window)
      x = 0;
      
      % y-coordinate for the center of the text (degrees visual
      % angle, centered in window)
      y = 0;
      
      % string to render as graphical text
      string = '';
      
      % [RGB] color of the displayed text
      color = [1 1 1]';
      
      % [RGB] background color
      backgroundColor = [];
      
      % degrees counterclockwise to rotate the entire text
      rotation = 0;
      
      % wheter or not to flip the text horizontally
      % BUGGY!!!!
      isFlippedHorizontal = false;
      
      % wheter or not to flip the text vertically
      % BUGGY!!!!
      isFlippedVertical = false;
      
      % string name of the typeface to render
      typefaceName = 'Helvetica';
      
      % point size of the font to render
      fontSize = 48;
      
      % whether or not to render the font in @b bold
      isBold = false;
      
      % whether or not to render the font with @em emphasis
      isItalic = false;
      
      % whether or not to render the font with an a line under it
      isUnderline = false;
      
      % whether or not to render the font as outlines
      isOutline = false;
      
      % whether or not to render the font in condensed format
      isCondensed = false;
      
      % whether or not to render the font in extended format
      isExtended = false;
      
      % whether or not to prepare first
      prepareBeforeDraw = true;
   end
   
   properties (SetAccess = protected)
      
      % Style (bitwise) flag
      % 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend
      styleFlag = 0;
   end
   
   methods
      
      % Constructor takes no arguments.
      function self = dotsDrawableText()
         self = self@dotsDrawable();
      end
      
      % Keep track of required texture updates.
      function set.isBold(self, isBold)
         self.isBold    = isBold;
         self.styleFlag = bitset(self.styleFlag, 1, isBold);
      end
      
      % Keep track of required texture updates.
      function set.isItalic(self, isItalic)
         self.isItalic = isItalic;
         self.styleFlag = bitset(self.styleFlag, 2, isItalic);
      end
      
      % Keep track of required texture updates.
      function set.isUnderline(self, isUnderline)
         self.isUnderline = isUnderline;
         self.styleFlag = bitset(self.styleFlag, 4, isUnderline);
      end
      
      % Keep track of required texture updates.
      function set.isOutline(self, isOutline)
         self.isOutline = isOutline;
         self.styleFlag = bitset(self.styleFlag, 8, isOutline);
      end
      
      % Keep track of required texture updates.
      function set.isCondensed(self, isCondensed)
         self.isCondensed = isCondensed;
         self.styleFlag = bitset(self.styleFlag, 32, isCondensed);
      end
      
      % Keep track of required texture updates.
      function set.isExtended(self, isExtended)
         self.isExtended = isExtended;
         self.styleFlag = bitset(self.styleFlag, 64, isExtended);
      end
      
      % Draw the text string, centered on x and y.
      function draw(self)
         
         % Get the current windowPtr
         theScreen = dotsTheScreen.theObject();
         
         % Convert x,y to pixels -- pen start location
         rect = theScreen.getRect(self.x, self.y, 0, 0);
         
         % check for special formatting
         if self.rotation ~= 0 || self.isFlippedHorizontal || self.isFlippedVertical
            
            % Yes, this is all pretty slow... shouldn't be used if you care
            %  about precise timing...
            % Open off-screen window to draw text and get bounding box
            tmpWindowPtr = Screen('OpenOffscreenWindow', ...
               theScreen.displayIndex);
            
            % Set the text size for this texture
            Screen('TextSize', tmpWindowPtr, self.fontSize);
            
            % set font, style
            Screen('TextFont', tmpWindowPtr, ...
               self.typefaceName, self.styleFlag);
            
            % Draw the text to the middle of the texture, get bounds
            [~, ~, textBounds] = DrawFormattedText(tmpWindowPtr, ...
               self.string, 'center', 'center', self.color, ...
               [], ...           % could add wrapat
               self.isFlippedHorizontal, ...
               self.isFlippedVertical);
            
            % close the offscreen window
            Screen('Close', tmpWindowPtr);
            
            % Destination rect is slightly larger
            destinationRect = [rect(1) rect(2) ...
               rect(1) + ceil((textBounds(3) - textBounds(1)) * 1.1) ...
               rect(2) + ceil((textBounds(4) - textBounds(2)) * 1.1)];
            
            % Open texture with slightly larger bounds
            % FOR NOW ASSUMES BACKGROUND IS BLACK
            textureBackground = zeros(ceil(RectHeight(destinationRect)), ...
               ceil(RectWidth(destinationRect)));
            
            % make the texture
            textTexture = Screen('MakeTexture', ...
               theScreen.windowPointer, textureBackground);
            
            % Set the text size for this texture
            Screen('TextSize', textTexture, self.fontSize);
            
            % set font, style
            Screen('TextFont', textTexture, ...
               self.typefaceName, self.styleFlag);
            
            % Draw the text to the middle of the texture, get bounds
            DrawFormattedText(textTexture, ...
               self.string, 'center', 'center', self.color, ...
               [], ...           % could add wrapat
               self.isFlippedHorizontal, ...
               self.isFlippedVertical);
            
            % now draw the texture to the screen
            Screen('DrawTexture', ...
               theScreen.windowPointer, ...
               textTexture, ...
               [], ...
               destinationRect, ...
               self.rotation);
         else
            
            % Set the style (bitwise)
            Screen('TextFont', theScreen.windowPointer, ...
               self.typefaceName, self.styleFlag);
            
            % Set font size
            Screen('TextSize', theScreen.windowPointer, ...
               self.fontSize);
            
            % call Screen 'DrawText' command
            % can return: [newX, newY, textHeight]=
            Screen('DrawText', ...
               theScreen.windowPointer, ...
               self.string, ...
               rect(1), ...
               rect(2), ...
               self.color, ...
               self.backgroundColor);
            % [,yPositionIsBaseline] [,swapTextDirection]);
         end
      end
      
      % get bounding box for current text string
      function [normBoundsRect, offsetBoundsRect, textHeight, xAdvance] = ...
            getTextBounds(self)
         
         [normBoundsRect, offsetBoundsRect, textHeight, xAdvance] = ...
            Screen('TextBounds', self.windowPointer, self.string, ...
            self.xPTB, self.yPTB); %[,yPositionIsBaseline] [,swapTextDirection]);
      end
   end
end