classdef dotsDrawableTextures < dotsDrawable
    % @class dotsDrawableTextures
    % Make and draw OpenGL textures.
    % @details
    % dotsDrawableTextures creates one or more multiple textures during
    % prepareToDrawInWindow(), then displays them one at a time during
    % successive calls to draw().
    % @details
    % prepareToDrawInWindow() invokes textureMakerFevalable in order to
    % create new textures.  textureMakerFevalable should expect the
    % dotsDrawableText object as the first argument and return a struct
    % array of texture information with one element per texture.
    properties
        % x-coordinate of the center of the drawn texture (degrees
        % visual angle, centered in window)
        x = 0;
        
        % y-coordinate of the center of the drawn texture (degrees
        % visual angle, centered in window)
        y = 0;
        
        % width of the drawn texture (degrees visual angle, centered in
        % window, defaults to unstretched and unflipped)
        width = [];
        
        % height of the drawn texture (degrees visual angle, centered
        % in window, defaults to unstretched and unflipped)
        height = [];

        % index for which texture to draw(), like a slide show
        slideNumber = 1;

        % whether or not to stretch textures by interpolation (logical)
        isSmooth = false;
        
        % wheter or not to flip the texture horizontally
        isFlippedHorizontal = false;
        
        % wheter or not to flip the texture vertically
        isFlippedVertical = false;
        
        % degrees counterclockwise to rotate the texture about its center
        rotation = 0;
        
        % fevalable cell array for creating arbitrary textures
        % @details
        % The function should expect the dotsDrawableTextures object as the
        % first argument.  Any other arguments in the cell array will be
        % passed to the function starting at the second place.
        % @details
        % The function should return a struct array of texture information
        % as with one element per texture.  It may also set properties of
        % the dotsDrawableTextures object.  Aside from its the returned
        % struct array value and any property setting, the
        % dotsDrawableTextures object should not need to "know" anything
        % about how textureMakerFevalable works.
        % @details
        % textureMakerFevalable should work in units of pixels.  If width
        % and height are non-empty, the texture will be stretched to these
        % dimensions, in degrees of visual angle.
        textureMakerFevalable = {};
    end
    
    properties (SetAccess = protected)
        % struct array of texture information returned from
        % textureMakerFevalable.
        textureInfo = [];
        
        % number of texture indexes to interleave
        nTextures = 0;
        
        % whether or not the OpenGL texture needs updating
        isTextureStale = true;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawableTextures()
            self = self@dotsDrawable();
        end
        
        % Keep track of required texture updates.
        function set.textureMakerFevalable(self, textureMakerFevalable)
            self.textureMakerFevalable = textureMakerFevalable;
            self.isTextureStale = true;
        end
        
        % Make a new texture(s) with textureMakerFevalable.
        function prepareToDrawInWindow(self)
            if isstruct(self.textureInfo)
                for ii = 1:self.nTextures
                    mglDeleteTexture(self.textureInfo(ii));
                end
            end
            self.textureInfo = [];
            
            % get textures from black-box texture maker function
            if isempty(self.textureMakerFevalable)
                self.nTextures = 0;
                
            else
                self.textureInfo = feval( ...
                    self.textureMakerFevalable{1}, ...
                    self, ...
                    self.textureMakerFevalable{2:end});
                self.nTextures = numel(self.textureInfo);
                
                % OpenGL texture is ready to go
                self.isTextureStale = false;
            end
        end
        
        % Draw textures that were made by textureMakerFevalable.
        function draw(self)
            % make sure the OpenGL texture is up to date
            if self.isTextureStale
                self.prepareToDrawInWindow();
            end
            
            if self.slideNumber > 0 && self.slideNumber <= self.nTextures
                
                if isempty(self.width) && isempty(self.height)
                    position = [self.x self.y];
                    
                else
                    if self.isFlippedHorizontal
                        w = -self.width;
                    else
                        w = self.width;
                    end
                    
                    if self.isFlippedVertical
                        h = -self.height;
                    else
                        h = self.height;
                    end
                    
                    position = [self.x self.y, w, h];
                end
                
                dotsMglSmoothness('textures', double(self.isSmooth));
                mglBltTexture( ...
                    self.textureInfo(self.slideNumber), ...
                    position, ...
                    0, ...
                    0, ...
                    self.rotation);
            end
        end
        
        % Shorthand to increment slideNumber, up to nTextures.
        function next(self)
            if self.slideNumber < self.nTextures
                self.slideNumber = self.slideNumber + 1;
            end
        end
        
        % Shorthand to decrement slideNumber, down to zero.
        function previous(self)
            if self.slideNumber > 1
                self.slideNumber = self.slideNumber - 1;
            end
        end
    end
end