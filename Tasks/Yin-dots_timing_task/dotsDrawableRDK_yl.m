classdef dotsDrawableRDK_yl < dotsDrawable
    % @class dotsDrawableRDK_yl
    % Animate random dots that carry a motion signal.
    % updated 2010/10/28 yl
    
    properties (SetObservable = true)
        % the x-coordinate of the center of the dot field (degrees visual
        % angle, centered)
        x = 0;
        
        % the y-coordinate of the center of the dot field (degrees visual
        % angle, centered)
        y = 0;
        
        % the size of dots in the kinetogram (pixels)
        dotSize = 3;
        
        % one color for all dots in the field. (scalar clut index, [LA],
        % [RGB], or [RGBA], each value 0-255)
        color = [255 255 255];
        
        % the shape for all dots (integer, where 0 means filled square, 1
        % means filled circle, and 2 means filled circle with high-quality
        % anti-aliasing)
        shape = 0;
        
        % percentage of dots that carry the intended motion signal
        coherence = 50;
        
        % density of dots in the kinetogram (dots per degree-visual-angle^2
        % per second)
        density = 16.7;
        
        % The direction of the motion signal, or an array of directions to
        % be picked at random by directionWeights (degrees,
        % counterclockwise, 0 = rightward)
        direction = 0;
        
        % when direction is an array, the relative frequency of each
        % direction (the pdf).  If directionWeights is incomplete, defaults
        % to equal weights.
        directionWeights = 1;
        
        % diameter of the circular aperture through which dots are shown
        % (degrees visual angle)
        diameter = 5;
        
        % fraction of diameter that determines the width of the field of
        % moving dots.  When fieldScale > 1, some dots will be hidden
        % behind the aperture.
        fieldScale = 1.1;
        
        % width of angular error to add to each dot's motion (degrees)
        drunkenWalk = 0;
        
        % speed of each dot's motion (degrees visual angle per second)
        speed = 3;
        
        % number disjoint sets of dots to interleave frame-by-frame
        interleaving = 3;
        
        % how to move coherent dots: as one rigid unit (true), or each dot
        % independently (false)
        isMovingAsHerd = false;
        
        % how to move non-coherent dots: by replotting from scratch (true),
        % or by local increments (false)
        isFlickering = true;
        
        % how to move dots near the edges: by wrapping to the other side
        % (true), or by replotting from scratch (false)
        isWrapping = true;
        
        % how to pick coherent dots: favoring recently non-coherent dots
        % (true), or indiscriminately (false)
        isLimitedLifetime = true;
        
        % flag for circular aperture
        apertureFlag = true;
        
        % random number seed ... default to empty, which means do not seed
        %   'c' means seed with clock
        %   otherwise seed with given value
        seed = [];
        
        % random number stream.. putting here because might want to get it
        % from somewhere else
        randStream;
        
        % start time of prepareToDrawInWindow
        t_init = [];
        
        % keeps track of frames
        frameTime = [];

        % number of dots in the kinetogram, includes all interleaving
        % frames.
        nDots;
        
        % 2xn matrix of dot x and y coordinates, (normalized units, from
        % top-left of kinetogram)
        normalizedXY;
        
     end
    
    properties (Hidden, SetObservable = false)%(Hidden, SetObservable = false)
       % scale factor from kinetogram normalized units to pixels
        pixelScale;
        
        % 2xn matrix of dot x and y coordinates, (pixels, from top-left of
        % kinetogram)
        pixelXY;
        
        % center of the kinetogram (pixels, from the top-left of the
        % window)
        pixelOrigin;
        
        % Psychtoolbox Screen texture index for the dot field aperture mask
        maskTexture;
        
        % [x,y,x2,y2] rect, where to draw the dot field aperture mask,
        % (pixels, from the top-left of the window)
        maskDestinationRect;
        
        % [x,y,x2,y2] rect, spanning the entire dot field aperture mask,
        % (pixels, from the top-left of the window)
        maskSourceRect;
        
        % lookup table to pick random dot direction by directionWeights
        directionCDFInverse;
        
        % resolution of directionCDFInverse
        directionCDFSize = 1e3;
        
        % counter to keep track of interleaving frames
        frameNumber = 0;
        
        % logical array to select dots for a frame
        frameSelector;
        
        % count of how many consecutive frames each dot has moved
        % coherently
        dotLifetimes;
        
        % radial step size for dots moving by local increments (normalized
        % units)
        deltaR;
    end
    
    methods
        function self = dotsDrawableRDK_yl
            self            = self@dotsDrawable;
            self.color      = self.foregroundColor;
            self.randStream = RandStream.create('mt19937ar', 'seed', sum(100*clock));
        end
        
        function prepareToDrawInWindow(self)
            if isempty(self.t_init)
                self.t_init = tic;
            end
%             disp(['stim.prepareToDrawInWindow() datestr(now)']);
            
            % initialize the random number stream
            if self.seed == 'c' % flag for clock
                reset(self.randStream,sum(100*clock));
            elseif ~isempty(self.seed)
                reset(self.randStream,self.seed);
            end
            
            % size the dot field and the aperture circle
            fieldWidth = self.diameter*self.fieldScale;
            fieldPixels = ceil(fieldWidth * self.pixelsPerDegree);
            
            % count dots
            self.nDots = ceil(self.density * fieldWidth^2 ...
                / self.windowFrameRate);
            self.frameSelector = false(1, self.nDots);
            self.dotLifetimes = zeros(1, self.nDots);
            
            % account for speed as step per interleaved frame
            self.deltaR = self.speed / self.diameter ...
                * (self.interleaving / self.windowFrameRate);
            
            % account for pixel real estate
            self.pixelScale = fieldPixels;
            self.pixelOrigin(1) = self.windowRect(3)/2 ...
                + (self.x * self.pixelsPerDegree) - fieldPixels/2;
            self.pixelOrigin(2) = self.windowRect(4)/2 ...
                - (self.y * self.pixelsPerDegree) - fieldPixels/2;
            
            % build a lookup table to pick weighted directions from a
            % uniform random variable.
            if ~isequal(size(self.directionWeights), size(self.direction))
                self.directionWeights = ones(1, length(self.direction));
            end
            
            directionCDF = cumsum(self.directionWeights) ...
                / sum(self.directionWeights);
            self.directionCDFInverse = ones(1, self.directionCDFSize);
            probs = linspace(0, 1, self.directionCDFSize);
            for ii = 1:self.directionCDFSize
                nearest = find(directionCDF >= probs(ii), 1, 'first');
                self.directionCDFInverse(ii) = self.direction(nearest);
            end
            
            % pick random start positions for all dots
            self.normalizedXY = rand(self.randStream, 2, self.nDots);
            
            % if appropriate, build a Psychtoolbox Screen texture to mask the dots
            %   a large rectangle for the entire dots field
            %   with a hole in the middle for the dots viewing aperture
            if self.apertureFlag
                
                maskPixels               = fieldPixels + self.dotSize;
                self.maskSourceRect      = [0 0, maskPixels, maskPixels];
                self.maskDestinationRect = self.maskSourceRect ...
                    + self.pixelOrigin([1 2 1 2]) - self.dotSize/2;
                
                center      = exp(linspace(-1, 1, maskPixels).^2);
                field       = center'*center;
                if self.fieldScale > 1
                    marginWidth  = (self.fieldScale - 1) * self.diameter / 2;
                    marginPixels = ceil(marginWidth * self.pixelsPerDegree);
                    threshold    = center(marginPixels);
                else
                    threshold    = center(1);
                end
                aperture    = field > threshold;
                mask        = zeros(maskPixels, maskPixels, 4);
                mask(:,:,1) = self.backgroundColor(1);
                mask(:,:,2) = self.backgroundColor(2);
                mask(:,:,3) = self.backgroundColor(3);
                mask(:,:,4) = 255*aperture;
                self.maskTexture = Screen('MakeTexture', ...
                    self.windowNumber, ...
                    mask);
            end
        end
        
        function computeNextFrame(self)
            % cache some properties as local variables because it's faster
            nFrames = self.interleaving;
            frame = self.frameNumber;
            frame = 1 + mod(frame, nFrames);
            self.frameNumber = frame;
            
            thisFrame = self.frameSelector;
            thisFrame(thisFrame) = false;
            thisFrame(frame:nFrames:end) = true;
            self.frameSelector = thisFrame;
            nFrameDots = sum(thisFrame);
            
%             %-- start YL addition : rehcheck position of the stimulus
%             % size the dot field and the aperture circle
%             fieldWidth = self.diameter*self.fieldScale;
%             fieldPixels = ceil(fieldWidth * self.pixelsPerDegree);
% 
%             % account for pixel real estate
%             self.pixelScale = fieldPixels;
%             self.pixelOrigin(1) = self.windowRect(3)/2 ...
%                 + (self.x * self.pixelsPerDegree) - fieldPixels/2;
%             self.pixelOrigin(2) = self.windowRect(4)/2 ...
%                 - (self.y * self.pixelsPerDegree) - fieldPixels/2;
%             
%             % re-assess the aperture
%             if self.apertureFlag
%             
%                 maskPixels               = fieldPixels + self.dotSize;
%                 self.maskSourceRect      = [0 0, maskPixels, maskPixels];
%                 self.maskDestinationRect = self.maskSourceRect ...
%                     + self.pixelOrigin([1 2 1 2]) - self.dotSize/2;
%                 
%                 center      = exp(linspace(-1, 1, maskPixels).^2);
%                 field       = center'*center;
%                 if self.fieldScale > 1
%                     marginWidth  = (self.fieldScale - 1) * self.diameter / 2;
%                     marginPixels = ceil(marginWidth * self.pixelsPerDegree);
%                     threshold    = center(marginPixels);
%                 else
%                     threshold    = center(1);
%                 end
%                 aperture    = field > threshold;
%                 mask        = zeros(maskPixels, maskPixels, 4);
%                 mask(:,:,1) = self.backgroundColor(1);
%                 mask(:,:,2) = self.backgroundColor(2);
%                 mask(:,:,3) = self.backgroundColor(3);
%                 mask(:,:,4) = 255*aperture;
%                 self.maskTexture = Screen('MakeTexture', ...
%                     self.windowNumber, ...
%                     mask);
%             end
%             %-- end YL addition
           
            
            % pick coherent dots
            cohSelector = false(size(thisFrame));
            cohCoinToss = 100*rand(self.randStream, 1, nFrameDots) < self.coherence;
            nCoherentDots = sum(cohCoinToss);
            nNonCoherentDots = nFrameDots - nCoherentDots;
            lifetimes = self.dotLifetimes;
            if self.isLimitedLifetime
                % would prefer not to call sort
                %   should be able to do accounting as we go
                [frameSorted, frameOrder] = ...
                    sort(lifetimes(thisFrame));
                isInFrameAndShortLifetime = false(1, nFrameDots);
                isInFrameAndShortLifetime(frameOrder(1:nCoherentDots)) = true;
                cohSelector(thisFrame) = isInFrameAndShortLifetime;
                
            else
                cohSelector(thisFrame) = cohCoinToss;
            end
            lifetimes(cohSelector) = ...
                lifetimes(cohSelector) + 1;
            
            % account for non-coherent dots
            nonCohSelector = false(size(thisFrame));
            nonCohSelector(thisFrame) = true;
            nonCohSelector(cohSelector) = false;
            lifetimes(nonCohSelector) = 0;
            self.dotLifetimes = lifetimes;
            
            % pick motion direction(s) for coherent dots
            if self.isMovingAsHerd
                nDirections = 1;
            else
                nDirections = nCoherentDots;
            end
            
            if numel(self.direction) == 1
                % use the one constant direction
                degrees = self.direction(1) * ones(1, nDirections);
                
            else
                % pick from the direction distribution
                CDFIndexes = 1 + ...
                    floor(rand(self.randStream, 1, nDirections)*(self.directionCDFSize));
                degrees = self.directionCDFInverse(CDFIndexes);
            end
            
            if self.drunkenWalk > 0
                % jitter the direction from a uniform distribution
                degrees = degrees + ...
                    self.drunkenWalk * (rand(self.randStream, 1, nDirections) - .5);
            end
            
            % move the coherent dots
            XY = self.normalizedXY;
            R = self.deltaR;
            radians = pi*degrees/180;
            deltaX = R*cos(radians);
            deltaY = R*sin(radians);
            XY(1,cohSelector) = XY(1,cohSelector) + deltaX;
            XY(2,cohSelector) = XY(2,cohSelector) - deltaY;
            
            % move the non-coherent dots
            if self.isFlickering
                XY(:,nonCohSelector) = rand(self.randStream, 2, nNonCoherentDots);
                
            else
                radians = 2*pi*rand(self.randStream, 1, nNonCoherentDots);
                deltaX = R*cos(radians);
                deltaY = R*sin(radians);
                XY(1,nonCohSelector) = XY(1,nonCohSelector) + deltaX;
                XY(2,nonCohSelector) = XY(2,nonCohSelector) - deltaY;
            end
            
            % keep dots from moving out of the field
            tooBig = XY > 1;
            tooSmall = XY < 0;
            componentOverrun = tooBig | tooSmall;
            if self.isWrapping
                % wrap the overrun component
                %   carry the overrun to prevent striping
                XY(tooBig) = XY(tooBig) - 1;
                XY(tooSmall) = XY(tooSmall) + 1;
                
                % randomize the other component
                wrapRands = rand(self.randStream, 1, sum(componentOverrun(1:end)));
                XY(componentOverrun([2,1],:)) = wrapRands;
                
            else
                % randomize both components when either overruns
                overrun = any(componentOverrun, 1);
                XY([1,2],overrun) = rand(self.randStream, 2, sum(overrun));
            end
            
            self.normalizedXY = XY;
            self.pixelXY = XY*self.pixelScale;
        end
        
        function draw(self)
            self.frameTime = [self.frameTime toc(self.t_init)];
            self.computeNextFrame;
            
            Screen('DrawDots', ...
                self.windowNumber, ...
                self.pixelXY(:,self.frameSelector), ...
                self.dotSize, ...
                self.color, ...
                self.pixelOrigin, ...
                self.shape);
            
            if self.apertureFlag
                Screen('DrawTexture', ...
                    self.windowNumber, ...
                    self.maskTexture, ...
                    self.maskSourceRect, ...
                    self.maskDestinationRect);
            end
        end
    end
end