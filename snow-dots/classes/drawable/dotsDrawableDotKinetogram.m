classdef dotsDrawableDotKinetogram < dotsDrawable
   % @class dotsDrawableDotKinetogram
   % Animate random dots that carry a motion signal.
   properties
      % the x-coordinate of the center of the dot field (degrees visual
      % angle, centered)
      xCenter = 0;
      
      % the y-coordinate of the center of the dot field (degrees visual
      % angle, centered)
      yCenter = 0;
      
      % percentage of dots that carry the intended motion signal
      coherence = 50;
      
      % density of dots in the kinetogram (dots per degree-visual-angle^2
      % per second)
      density = 16.7;
      
      % size of each dot, in pixels
      pixelSize = 3;
      
      % The direction of the motion signal, or an array of directions to
      % be picked at random by directionWeights (degrees counterclockwise
      % from rightward)
      direction = 0;
      
      % when direction is an array, the relative frequency of each
      % direction (the pdf).  If directionWeights is incomplete, defaults
      % to equal weights.
      directionWeights = 1;
      
      % diameter of the circular aperture through which dots are shown
      % (degrees visual angle)
      diameter = 5;
      
      % Color map to use for vertices [r g b a; r g b a; etc.]'
      %   Each vertex takes its color from one of the columns of colors.
      colors = [1 1 1]';
      
      % background color ... defaults to screen background
      backgroundColor = [];
      
      % fraction of diameter that determines the width of the underlying
      % dot field.  When fieldScale > 1, the underlying dot field will be
      % wider than the aperture.
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
      
      % OpenGL stencil to use for the circular aperture
      stencilNumber = 2;
      
      % flag for PTB:
      %  0 (default) and 4 draw square dots
      %  1, 2 and 3 draw round dots (circles) with anti-aliasing
      %     - 1 favors performance
      %     - 2 tries to use high-quality anti-aliasing,
      %     - 3 Uses a builtin shader-based implementation.
      isSmooth = 0;
   end
   
   properties (SetAccess = protected)
      
      % dot x-positions
      x = 0;
      
      % vertex y-positions
      y = 0;
      
      % number of dots in the kinetogram, includes all interleaving
      % frames.
      nDots;
      
      % 2xn matrix of dot xCenter and yCenter coordinates
      % @details
      % In normalized units, from top-left of kinetogram.
      normalizedXY;
      
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
      
      % radial step pixelSize for dots moving by local increments (normalized
      % units)
      deltaR;
      
      % aperture rect
      apRect = [];
   end
   
   methods
      % Constructor takes no arguments.
      function self = dotsDrawableDotKinetogram()
         self = self@dotsDrawable();
      end
      
      % Compute some parameters and create a circular aperture texture.
      function prepareToDrawInWindow(self)
         
         % access info about the drawing window
         screen = dotsTheScreen.theObject();
         
         % gross accounting for the underlying dot field
         fieldWidth = self.diameter*self.fieldScale;
         self.nDots = ceil(self.density * fieldWidth^2 ...
            / screen.windowFrameRate);
         self.frameSelector = false(1, self.nDots);
         self.dotLifetimes = zeros(1, self.nDots);
         
         % treat speed as step-per-interleaved-frame
         self.deltaR = self.speed / self.diameter ...
            * (self.interleaving / screen.windowFrameRate);
         
         %             % draw into an OpenGL stencil to make the circular aperture
         %             mglStencilCreateBegin(self.stencilNumber);
         %             sizeStencil = self.diameter*[1 1];
         %             mglFillOval(self.xCenter, self.yCenter, sizeStencil);
         %             mglStencilCreateEnd();
         %             mglClearScreen();
         
         % build a lookup table to pick weighted directions
         %   based on a uniform random variable.
         if ~isequal( ...
               numel(self.directionWeights), numel(self.direction))
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
         self.normalizedXY = rand(2, self.nDots);
         
         % check color array -- make sure one per dot
         num_colors = size(self.colors,2);
         if num_colors > 1
            % special case, assume vector given as row
            if (num_colors==3 || num_colors==4) && size(self.colors,1)==1
               self.colors = self.colors';
            elseif num_colors > self.nDots
               self.colors = self.colors(:,self.nDots);
            elseif num_colors < self.nDots
               reps  = floor(self.nDots/num_colors);
               extra = mod(self.nDots, num_colors);
               self.colors = cat(2, ...
                  repmat(self.colors, 1, reps), ...
                  self.colors(:, 1:extra));
            end
         end
         
         % add alpha!
         if size(self.colors,1) == 3
            self.colors = cat(1, self.colors, ...
               ones(1, size(self.colors,2)));
         end
         
         % for backwards compatibility -- this could be a logical
         self.isSmooth = double(self.isSmooth);
         
         % compute the aperture rect
         self.apRect = screen.getRect(self.xCenter, self.yCenter, ...
            self.diameter, self.diameter);
         
         % conditionally set background color to screen background
         if isempty(self.backgroundColor)
            self.backgroundColor = screen.backgroundColor;
         end
         if length(self.backgroundColor)==1
            self.backgroundColor = parula(self.backgroundColor);
         elseif length(self.backgroundColor)==4
            self.backgroundColor = self.backgroundColor(1:3);
         end
      end
      
      % Compute dot positions for the next frame of animation.
      function computeNextFrame(self)
         
         % cache some properties as local variables because it's faster
         nFrames = self.interleaving;
         frame   = self.frameNumber;
         frame   = 1 + mod(frame, nFrames);
         self.frameNumber = frame;
         
         % deselect dots from the last frame, select new dots
         thisFrame = self.frameSelector;
         thisFrame(thisFrame) = false;
         thisFrame(frame:nFrames:end) = true;
         self.frameSelector = thisFrame;
         nFrameDots = sum(thisFrame);
         
         % pick coherent dots
         cohSelector = false(1, numel(thisFrame));
         cohCoinToss = 100*rand(1, nFrameDots) < self.coherence;
         nCoherentDots = sum(cohCoinToss);
         nNonCoherentDots = nFrameDots - nCoherentDots;
         lifetimes = self.dotLifetimes;
         if self.isLimitedLifetime
            % would prefer not to call sort
            %   should be able to do accounting as we go
            [~, frameOrder] = sort(lifetimes(thisFrame));
            isDueForCoh = false(1, nFrameDots);
            isDueForCoh(frameOrder(1:nCoherentDots)) = true;
            cohSelector(thisFrame) = isDueForCoh;
            
         else
            cohSelector(thisFrame) = cohCoinToss;
         end
         lifetimes(cohSelector) = ...
            lifetimes(cohSelector) + 1;
         
         % account for non-coherent dots
         nonCohSelector = false(1, numel(thisFrame));
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
               floor(rand(1, nDirections)*(self.directionCDFSize));
            degrees = self.directionCDFInverse(CDFIndexes);
         end
         
         if self.drunkenWalk > 0
            % jitter the direction from a uniform distribution
            degrees = degrees + ...
               self.drunkenWalk * (rand(1, nDirections) - .5);
         end
         
         % move the coherent dots
         XY       = self.normalizedXY;
         R        = self.deltaR;
         radians  = pi*degrees/180;
         deltaX   = R*cos(radians);
         deltaY   = R*sin(radians);
         XY(1,cohSelector) = XY(1,cohSelector) + deltaX;
         XY(2,cohSelector) = XY(2,cohSelector) + deltaY;
         
         % move the non-coherent dots
         if self.isFlickering
            XY(:,nonCohSelector) = rand(2, nNonCoherentDots);
            
         else
            radians = 2*pi*rand(1, nNonCoherentDots);
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
            wrapRands = rand(1, sum(componentOverrun(1:end)));
            XY(componentOverrun([2,1],:)) = wrapRands;
            
         else
            % randomize both components when either overruns
            overrun = any(componentOverrun, 1);
            XY([1,2],overrun) = rand(2, sum(overrun));
         end
         
         self.normalizedXY = XY;
         self.x = (XY(1, thisFrame)-0.5)*self.diameter + self.xCenter;
         self.y = (XY(2, thisFrame)-0.5)*self.diameter + self.yCenter;
      end
      
      % Draw the next frame of animated dots in a cirular aperture.
      function draw(self)
         
         % First update the frame
         self.computeNextFrame;

         % get windowPointer
         theScreen = dotsTheScreen.theObject();

         % draw the aperture in two parts, no blending
         [sourceFactorOld, destinationFactorOld] = ...
            Screen('BlendFunction', theScreen.windowPointer, ...
            GL_ONE, GL_ZERO);
         
         % first the whole mask
         Screen('FillRect', theScreen.windowPointer, ...
            [self.backgroundColor 1], self.apRect);
         
         % then open the visible part
         Screen('FillOval', theScreen.windowPointer, ...
            [self.backgroundColor 0], ...
            self.apRect);
         
         % now re-set the blending 
         Screen('BlendFunction', theScreen.windowPointer, ...
            GL_ONE_MINUS_DST_ALPHA, GL_DST_ALPHA);
         
         % possible return arguments:
         %  minSmoothPointSize
         %  maxSmoothPointSize
         %  minAliasedPointSize
         %  maxAliasedPointSize
         Screen('DrawDots', theScreen.windowPointer, ...
            [self.x; -self.y].*theScreen.pixelsPerDegree, ...
            self.pixelSize, ...
            self.colors, ...
            [theScreen.xScreenCenter, theScreen.yScreenCenter], ...
            self.isSmooth);
         
         % restore blend mode
         Screen('BlendFunction', theScreen.windowPointer, ...
            sourceFactorOld, destinationFactorOld);
      end
   end
end