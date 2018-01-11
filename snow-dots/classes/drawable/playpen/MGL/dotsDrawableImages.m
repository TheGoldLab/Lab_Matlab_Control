classdef dotsDrawableImages < dotsDrawableTextures
    % @class dotsDrawableImages
    % Draw images from files.
    % @details
    % dotsDrawableImages works the same way as its superclass,
    % dotsDrawableTextures, except that instead of specifying a
    % textureMakerFevalable, users specify a cell array of image file
    % names. dotsDrawableImages uses an internal textureMakerFevalable
    % which reads the image files and creates a texture for each one.
    % @details
    % dotsDrawableImages automatically fills in pixelHeights, pixelWidths,
    % and pixelColors, during prepareToDrawInWindow();
    % @details
    % Each file name and image file must be readable by Matlab's builtin
    % imread() function.  File names may include paths.
    properties
        % cell array of image file names
        fileNames = {};
        
        % pixel height of each image
        pixelHeights;
        
        % pixel width of each image
        pixelWidths;
        
        % number of colors per pixel for each image
        pixelColors;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawableImages
            self = self@dotsDrawableTextures;
        end
        
        % Make a new texture(s) with textureMakerFevalable.
        function prepareToDrawInWindow(self)
            % point textureMakerFevalable at imageTextureMakerFunction(),
            % then delegate to superclass.
            self.textureMakerFevalable = ...
                {@dotsDrawableImages.imageTextureMakerFunction};
            self.prepareToDrawInWindow@dotsDrawableTextures();
        end
    end
    
    methods (Static)
        % Read each image file and create a texture for each.
        function textureInfo = imageTextureMakerFunction(self)
            nImages = numel(self.fileNames);
            textureList = cell(1, nImages);
            self.pixelHeights = zeros(1, nImages);
            self.pixelWidths = zeros(1, nImages);
            self.pixelColors = zeros(1, nImages);
            if nImages > 0
                for ii = 1:numel(self.fileNames)
                    try
                        imageData = imread(self.fileNames{ii});
                        
                    catch readError
                        warning(readError.message);
                        continue
                    end
                    
                    if ~isempty(imageData)
                        self.pixelHeights(ii) = size(imageData, 1);
                        self.pixelWidths(ii) = size(imageData, 2);
                        self.pixelColors(ii) = size(imageData, 3);
                        textureList{ii} = mglCreateTexture( ...
                            double(flipdim(imageData, 1)));
                    end
                end
                textureInfo = [textureList{:}];
            else
                textureInfo = [];
            end
        end
    end
end