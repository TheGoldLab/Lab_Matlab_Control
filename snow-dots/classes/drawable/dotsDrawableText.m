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
      color = [255 255 255];
      
      % degrees counterclockwise to rotate the entire text
      rotation = 0;
      
      % wheter or not to flip the text horizontally
      isFlippedHorizontal = false;
      
      % wheter or not to flip the text vertically
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
      
      % whether or not to render the font with a line through it
      isStrikethrough = false;
   end
   
   properties (SetAccess = protected)
      % struct of information about the text's OpenGL texture
      textureInfo;
      
      % whether or not the OpenGL texture needs updating
      isTextureStale = true;
   end
   
   methods
      % Constructor takes no arguments.
      function self = dotsDrawableText()
         self = self@dotsDrawable();
      end
      
      % Keep track of required texture updates.
      function set.typefaceName(self, typefaceName)
         self.typefaceName = typefaceName;
         self.isTextureStale = true;
      end
      
      % Keep track of required texture updates.
      function set.fontSize(self, fontSize)
         self.fontSize = fontSize;
         self.isTextureStale = true;
      end
      
      % Keep track of required texture updates.
      function set.color(self, color)
         self.color = color;
         self.isTextureStale = true;
      end
      
      % Keep track of required texture updates.
      function set.isFlippedHorizontal(self, isFlippedHorizontal)
         self.isFlippedHorizontal = isFlippedHorizontal;
         self.isTextureStale = true;
      end
      
      % Keep track of required texture updates.
      function set.isFlippedVertical(self, isFlippedVertical)
         self.isFlippedVertical = isFlippedVertical;
         self.isTextureStale = true;
      end
      
      % Keep track of required texture updates.
      function set.isBold(self, isBold)
         self.isBold = isBold;
         self.isTextureStale = true;
      end
      
      % Keep track of required texture updates.
      function set.isItalic(self, isItalic)
         self.isItalic = isItalic;
         self.isTextureStale = true;
      end
      
      % Keep track of required texture updates.
      function set.isUnderline(self, isUnderline)
         self.isUnderline = isUnderline;
         self.isTextureStale = true;
      end
      
      % Keep track of required texture updates.
      function set.isStrikethrough(self, isStrikethrough)
         self.isStrikethrough = isStrikethrough;
         self.isTextureStale = true;
      end
      
      % Keep track of required texture updates.
      function set.string(self, string)
         self.string = string;
         self.isTextureStale = true;
      end
      
      % Prepare the text texture to be drawn.
      function prepareToDrawInWindow(self)
         if isstruct(self.textureInfo)
            mglDeleteTexture(self.textureInfo);
         end
         self.textureInfo = [];
         
         % take over the global text settings
         mglTextSet( ...
            self.typefaceName, ...
            self.fontSize, ...
            self.color, ...
            double(self.isFlippedHorizontal), ...
            double(self.isFlippedVertical), ...
            0, ...
            double(self.isBold), ...
            double(self.isItalic), ...
            double(self.isUnderline), ...
            double(self.isStrikethrough));
         
         % create a new texture for use in draw()
         self.textureInfo = mglText(self.string);
         
         % OpenGL texture is ready to go
         self.isTextureStale = false;
      end
      
      % Draw the text string, centered on x and y.
      function draw(self)
         % make sure the OpenGL texture is up to date
         if self.isTextureStale
            self.prepareToDrawInWindow();
         end
         
         % draw the texture created in prepareToDrawInWindow()
         mglBltTexture( ...
            self.textureInfo, [self.x, self.y], 0, 0, self.rotation);
      end
   end
   
   methods (Static)
      
      % Utility to show text strings using the given ensemble.
      %
      % Inputs:
      %  textEnsemble  ... topsEnsemble holding the text object(s)
      %  textStrings   ... cell array of strings; any can be empty to skip.
      %                     rows are done in separate screens
      %                     columns should correspond to the # of text objects in
      %                     the ensemble to show at once
      %  useDefaultSpacing ... space along y axis
      %  showDuration  ... Time (in sec) to show the text
      %  pauseDuration ... Time (in sec) to pause after showing the text
      %
      function ret = drawEnsemble(textEnsemble, textStrings, ...
            useDefaultSpacing, showDuration, pauseDuration)
         
         % Check ensemble
         if isempty(textEnsemble)
            return
         end
         
         % ---- Turn off "extra" objects
         %
         extraObjectIndices = (size(textStrings,2)+1):length(textEnsemble.objects);
         if length(extraObjectIndices) > 1
            textEnsemble.setObjectProperty('isVisible', false, extraObjectIndices);
         end
         
         % ---- Possibly set up default spacing
         %
         if nargin >= 3 && useDefaultSpacing
            
            ys = (0:4:4*(size(textStrings,2)-1));
            ys = -(ys - mean(ys));
            for ii = 1:size(textStrings, 2)
               textEnsemble.setObjectProperty('y', ys(ii), ii);
            end
         end

         % ---- Loop through each set
         %
         for ii = 1:size(textStrings, 1)
            
            % Set text strings in the given set
            for jj = 1:size(textStrings, 2) % many possible text objects
               if isempty(textStrings{ii,jj})
                  textEnsemble.setObjectProperty('isVisible', false, jj);
               else
                  textEnsemble.setObjectProperty('string', textStrings{ii,jj}, jj);
                  textEnsemble.setObjectProperty('isVisible', true, jj);
               end
            end
            
            % ---- Draw, wait, blank
            %
            % Call runBriefly for the instruction ensemble
            ret = textEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
            
            % If more args given, wait..
            if nargin >= 4 && ~isempty(showDuration)
               
               % Wait while showing
               pause(showDuration);
               
               % Set visible flags to false
               textEnsemble.setObjectProperty('isVisible', false);
               
               % Draw again to blank screen
               textEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
               
               % Wait again
               if nargin>5 && ~isempty(pauseDuration)
                  pause(pauseDuration);
               end
            end
         end
      end
      
      % function ensemble = makeEnsemble(name, num, yOffset, screenEnsemble)
      %
      % Convenient utility for combining a bunch of dotsDrawableText objects that
      %  will show vertically positioned strings into an ensemble
      %
      % Aguments:
      %  name           ... optional <string> name of the ensemble/composite
      %  num            ... number of objects to make
      %  yOffset        ... vertical separation beween text strings on the screen
      %  screenEnsemble ... ensemble containing the screen object, which we use
      %                       to determine client/server behavior
      %
      function ensemble = makeEnsemble(name, num, yOffset, screenEnsemble)
         
         if nargin < 1 || isempty(name)
            name = 'textEnsemble';
         end
         
         if nargin < 2 || isempty(num)
            num = 2;
         end
         
         if nargin < 3 || isempty(yOffset)
            yOffset = 3;
         end
         
         % If no screen ensemble given, assume this is local
         if nargin < 4 || isempty(screenEnsemble) || ...
               ~isa(screenEnsemble, 'dotsClientEnsemble')
            remoteInfo = {false};
         else
            remoteInfo = {true, ...
               screenEnsemble.clientIP, ...
               screenEnsemble.clientPort, ...
               screenEnsemble.serverIP, ...
               screenEnsemble.serverPort};
         end
         
         % create the ensemble
         ensemble = dotsEnsembleUtilities.makeEnsemble([name 'Ensemble'], remoteInfo{:});
         
         offsets = (0:num-1).*yOffset;
         offsets = -(offsets - (offsets(end)-offsets(1))/2);
         % make and add the objects
         for ii = 1:num
            text = dotsDrawableText();
            text.y = offsets(ii);
            ensemble.addObject(text);
         end
      end
   end
end