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
end