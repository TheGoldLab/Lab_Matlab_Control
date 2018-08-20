classdef dotsDrawableDynamicDotKinetogram < dotsDrawableVertices
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
        
        % fraction of diameter that determines the width of the underlying
        % dot field.  When fieldScale > 1, the underlying dot field will be
        % wider than the aperture.
        fieldScale = 1.1;
        
        % width of angular error to add to each dot's motion (degrees)
        drunkenWalk = 0;
        
        % speed of each dot's motion (degrees visual angle per second)
        speed = 8;
        
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
        
        % time index
        tind = 0;
        
        directionvc = zeros(1,1000);
        
        coherencevc = zeros(1,1000);
        
        stimtime = zeros(1,1000);
        
        H = 0;
        
        nFrameDots = nan;
        nCoherentDots = nan;
        
        randSeed = nan;
        
        direction0 = nan;
        
        windowFrameRate = nan;
        
        stimOnset = nan;
        
        %Justin: for timing
        time_flag = 0;
        time_count = 0
        time_start = [];
        time_end = [];
        
        time_max = nan;
        
        
        duration = nan;
        time_progress = 0;
        coh_high = nan;
        coh_low = nan;
        length_of_drop = nan;
        length_of_drop_inT = nan;
        length_of_high = nan;
        length_of_high_inT = nan;
        TAC = nan;
        direction_array = nan;
        %records last tind the high coherence was active. Neccesary for
        %subsequent linear drop
        high_tind_end = nan;

        
    end
    
    properties (SetAccess = protected)
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
        
        frameH = 0;
        
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawableDynamicDotKinetogram()
            self = self@dotsDrawableVertices();
            
            % draw as points
            self.primitive = 0;
        end
        
        % Compute some parameters and create a circular aperture texture.
        function prepareToDrawInWindow(self)
            % access info about the drawing window
            
            if isnan(self.windowFrameRate)
                screen = dotsTheScreen.theObject();
                self.windowFrameRate = screen.windowFrameRate;
                
            end
            self.time_max = ceil(self.windowFrameRate * self.duration);
            self.length_of_drop_inT = ceil(self.windowFrameRate * self.length_of_drop);
            self.length_of_high_inT = ceil(self.windowFrameRate * self.length_of_high);
            
            %set TAC
            self.direction_array = zeros(1,self.time_max);
            temp = ceil(self.TAC * self.windowFrameRate);
            direction_temp = round(rand)*180;
            self.direction_array(1:(temp)) = direction_temp;
            
            %set changepoint
            direction_temp = mod(direction_temp+180,360);
            temp = temp+1;
            self.direction_array(temp) = direction_temp;
            
            %Let Hazard Rate set the rest of the fields
            flag = 0;
            while(flag == 0)
                temp = temp+1;
                if (rand < (self.H / self.windowFrameRate))
                    direction_temp = mod(direction_temp+180,360);
                end
                self.direction_array(temp) = direction_temp;
                if(temp > self.time_max)   
                    flag = 1;
                end
            end
            self.direction_array = fliplr(self.direction_array);

            
            % gross accounting for the underlying dot field
            fieldWidth = self.diameter*self.fieldScale;
            self.nDots = floor(self.density * fieldWidth^2 ...
                / self.windowFrameRate);
            self.frameSelector = false(1, self.nDots);
            self.dotLifetimes = zeros(1, self.nDots);
            
            % treat speed as step-per-interleaved-frame
            self.deltaR = self.speed / self.diameter ...
                * (self.interleaving / self.windowFrameRate);
            
            % draw into an OpenGL stencil to make the circular aperture
            mglStencilCreateBegin(self.stencilNumber);
            sizeStencil = self.diameter*[1 1];
            mglFillOval(self.xCenter, self.yCenter, sizeStencil);
            mglStencilCreateEnd();
            mglClearScreen();
            
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
   
            self.frameH = self.H / self.windowFrameRate;
            
            if isnan(self.randSeed)
                time = clock;
                self.randSeed = time(6)*10e6;
            end
            
            rng(self.randSeed);
            
            self.direction0 = self.direction;
            
            self.frameNumber = 0;
                     
            % pick random start positions for all dots
            self.normalizedXY = rand(2, self.nDots);
            
            self.stimOnset = mglGetSecs;
            
            
        end
        
        % Compute dot positions for the next frame of animation.
        function computeNextFrame(self)
            % cache some properties as local variables because it's faster
            
            self.tind = self.tind + 1;
            %old method of choosing direction
%             if rand < self.frameH  
%                 self.direction = mod(self.direction+180,360);
%             end

            %new method of choosing direction
            self.direction = self.direction_array(self.tind);
            
            %linear drop
            %high_tind_end sho
            self.time_progress = (self.tind - self.high_tind_end - 1) / (self.length_of_drop_inT);
            
            
            if (self.tind < self.length_of_high_inT)
                self.coherence = self.coh_high;
                self.high_tind_end = self.high_tind_end + 1;
            elseif (self.length_of_drop == 0)
                self.coherence = self.coh_low;
            elseif (self.time_progress < 1)
                self.coherence = self.coh_high - (self.time_progress * (self.coh_high - self.coh_low));
            else
                self.coherence = self.coh_low;
            end
            %for Glaze 2015 
%             if (rand < .25)
%                 self.coherence = 80;
%             else
%                 self.coherence = 11;
%             end
%                 
          
            self.directionvc(self.tind) = self.direction;
            self.stimtime(self.tind) = mglGetSecs;
            
            nFrames = self.interleaving;
            frame = self.frameNumber;
            frame = 1 + mod(frame, nFrames);
            self.frameNumber = frame;
            
            % deselect dots from the last frame, select new dots
            thisFrame = self.frameSelector;
            thisFrame(thisFrame) = false;
            thisFrame(frame:nFrames:end) = true;
            self.frameSelector = thisFrame;
            self.nFrameDots = sum(thisFrame);
            
            % pick coherent dots
            cohSelector = false(1, numel(thisFrame));
            cohCoinToss = 100*rand(1, self.nFrameDots) < self.coherence;
            self.nCoherentDots = sum(cohCoinToss);
            
            %used for recording
            self.coherencevc(self.tind) = self.nCoherentDots / self.nFrameDots;
            
            nNonCoherentDots = self.nFrameDots - self.nCoherentDots;
            lifetimes = self.dotLifetimes;
            if self.isLimitedLifetime
                % would prefer not to call sort
                %   should be able to do accounting as we go
                [frameSorted, frameOrder] = sort(lifetimes(thisFrame));
                isDueForCoh = false(1, self.nFrameDots);
                isDueForCoh(frameOrder(1:self.nCoherentDots)) = true;
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
                nDirections = self.nCoherentDots;
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
            XY = self.normalizedXY;
            R = self.deltaR;
            radians = pi*degrees/180;
            deltaX = R*cos(radians);
            deltaY = R*sin(radians);
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
            %if self.time_flag == 0
            %    self.time_start = clock;
            %    self.time_end = [self.time_end 0];
            %    self.time_flag = 1;
            %    self.time_count = 0;
                
            %end
            if(self.tind < self.time_max)
            
            %    self.time_end = etime(clock, self.time_start);
            
                self.computeNextFrame;
                mglStencilSelect(self.stencilNumber);
                self.draw@dotsDrawableVertices;
                mglStencilSelect(0);
            else
                self.isVisible = false;
            end
        end
    end
end