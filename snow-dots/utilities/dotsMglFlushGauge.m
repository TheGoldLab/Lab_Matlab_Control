classdef dotsMglFlushGauge < handle
    % Models the video refresh cycle and predicts MGL frame onset times.
    %
    % @ingroup dotsUtilities
    
    properties
        % how many frame intervals to measure during initialize()
        initialFrameCount = 100;
        
        % how many valid frame intervals required for initialize() success
        initialFrameMinimum = 50;
        
        % criterion in seconds to validate frame intervals vs nominal
        initialFrameTolerance = .0005;
        
        % frame intervals measured in seconds during initialize()
        initialFrameIntervals = nan;
        
        % whether each intervals measured during initialize() is valid
        initialFrameIsValid = false;
        
        % frame period in seconds, measured during initialize()
        framePeriod = nan;
        
        % frame period in seconds, reported by the system
        nominalFramePeriod = nan;
        
        % seconds specifying a frame border-interval of ambiguous behavior
        framePadding = 0.001;
        
        % recent time in seconds when a blocking system swap call returned
        referenceFrameTime = nan;
        
        % frame count between initialize() referenceFrameTime
        referenceFrame = nan;
        
        % estimated onset time in seconds of drawing that preceeded flush()
        flushOnsetTime = nan;
        
        % frame count between initialize() and flush()
        flushOnsetFrame = nan;
        
        % whether the two recent flush()es had consecutive onset frames
        flushWasTight = true;
        
        % any function which returns the current time as a number
        clockFunction = @mglGetSecs;
        
        % any function which will wait or sleep for a given duration.
        waitFunction = @mglWaitSecs;
    end
    
    
    methods
        % Make a new gauge for mglFlush().  Must initialize() it.
        function self = dotsMglFlushGauge()
        end
        
        % Measure new frames and build a new refresh cycle model.
        function success = initialize(self)
            success = false;
            
            isOpen = mglGetParam('displayNumber') >= 0;
            if ~isOpen
                disp('you need to mglOpen() first');
            end
            
            disp(sprintf('%s measuring %d video refresh cycles.', ...
                mfilename, self.initialFrameCount));
            drawnow();
            
            % measure many mglFlush() intervals
            % 	work around warmup effects with redundancy
            flushes = zeros(1, self.initialFrameCount);
            for ii = [1:10, 1:self.initialFrameCount+1]
                mglClearScreen();
                mglFlush();
                flushes(ii) = feval(self.clockFunction);
            end
            self.initialFrameIntervals = diff(flushes);
            
            % compare measured frame intervals to the nominal interval
            self.nominalFramePeriod = 1./mglGetParam('frameRate');
            frameDeviation = ...
                self.initialFrameIntervals - self.nominalFramePeriod;
            self.initialFrameIsValid = ...
                abs(frameDeviation) < self.initialFrameTolerance;
            if sum(self.initialFrameIsValid) >= self.initialFrameMinimum
                success = true;
                self.framePeriod = mean( ...
                    self.initialFrameIntervals(self.initialFrameIsValid));
            else
                self.framePeriod = self.nominalFramePeriod;
            end
            
            
            % pick an arbitrary reference frame
            %   let Matlab "warm up" the flush functions
            self.referenceFrame = 0;
            self.referenceFrameTime = flushes(self.initialFrameCount);
            self.flushWait();
            
            % now attempt to return at the start of the 0th frame
            mglFlush();
            mglFlush();
            swapTime = feval(self.clockFunction);
            self.referenceFrame = -2;
            self.referenceFrameTime = swapTime;
            self.flushWait();
        end
        
        % Invoke mglFlush() and predict corresponding frame onset time.
        function [onsetTime, onsetFrame, swapTime, isTight] = ...
                flush(self)
            
            % where are we *now* in the frame cycle?
            %   near the frame border, "round" into the next frame
            nowTime = feval(self.clockFunction);
            nowFrame = self.frameAtTime(nowTime + self.framePadding);
            
            % compare now-frame number to previous onset frame number
            %   to model the behavior of the video system
            previousOnsetFrame = self.flushOnsetFrame;
            if previousOnsetFrame < nowFrame
                % at least one full frame has passed
                %   since the last flush() onset time
                % expect onset at the next frame
                % expect mglFlush() to return immediately
                isTight = false;
                onsetFrame = nowFrame + 1;
                blockingSwap = false;
                
            elseif previousOnsetFrame == nowFrame
                % less than one full frame has passed
                %   since the last flush() onset time
                % expect onset at the next frame
                % expect mglFlush() to return immediately
                isTight = true;
                onsetFrame = nowFrame + 1;
                blockingSwap = false;
                
            else
                % the last flush() onset is still in the future
                %   an "extra frame" is alredy in the OpenGL command queue
                % expect onset in two frames
                % expect mglFlush() to block for the rest of this frame
                isTight = true;
                onsetFrame = nowFrame + 2;
                blockingSwap = true;
            end
            
            % flush recent drawing commands into the OpenGL command queue
            %   and swap the two frame buffers
            mglFlush();
            swapTime = feval(self.clockFunction);
            
            % blocking swap calls synchronize Matlab with the frame cycle
            %   use them to update the reference frame
            % sanity check: blocking swap should return near predicted time
            if blockingSwap ...
                    && abs(self.flushOnsetTime - swapTime) ...
                    < self.framePadding
                
                % mark the new reference frame number
                % use the measured swap time
                %   (not the previously predicted onset time)
                self.referenceFrame = previousOnsetFrame;
                self.referenceFrameTime = swapTime;
            end
            
            % estimate time of the onset frame
            onsetTime = self.timeOfFrame(onsetFrame);
            self.flushOnsetFrame = onsetFrame;
            self.flushOnsetTime = onsetTime;
            self.flushWasTight = isTight;
        end
        
        % Invoke mglFlush() and block until corresponding frame onset time.
        function [onsetTime, onsetFrame, swapTime, isTight] = ...
                flushWait(self)
            [onsetTime, onsetFrame, swapTime, isTight] = self.flush();
            waitTime = onsetTime - feval(self.clockFunction) ...
                + self.framePadding;
            feval(self.waitFunction, waitTime);
        end
        
        % Clear both frame buffers, and implicitly update reference frame.
        function [onsetTime, onsetFrame, swapTime, isTight] = ...
                blank(self)
            mglClearScreen();
            [onsetTime, onsetFrame, swapTime, isTight] = self.flush();
            mglClearScreen();
            self.flush();
        end
        
        % Count frames between initialize() and now.
        function [frameNumber, currentTime] = currentFrame(self)
            currentTime = feval(self.clockFunction);
            frameNumber = self.frameAtTime(currentTime);
        end
        
        % Count frames between initialize() and the given time.
        function [frameNumber] = frameAtTime(self, time)
            frameNumber = self.referenceFrame + ...
                floor((time-self.referenceFrameTime)/self.framePeriod);
        end
        
        % Estimate onset time for the nth video frame since initialize().
        function onsetTime = timeOfFrame(self, n)
            onsetTime = self.referenceFrameTime + ...
                (n-self.referenceFrame)*self.framePeriod;
        end
    end
end