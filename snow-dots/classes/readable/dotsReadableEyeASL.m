classdef dotsReadableEyeASL < dotsReadableEye
    % @class dotsReadableEyeASL
    % Reads ASL/serial port gaze and pupil size data.
    % @details
    % dotsReadableEyeASL extends the dotsReadableEye superclass to
    % acquire point of gaze and pupil size data from an ASL eye tracker
    % connected via the serial port.
    % @details
    % It uses the as() mex funciton (which is only for Mac OS X) to buffer
    % and decode the streaming serial port data.  as() makes a number of
    % assumptions about the data format, including that the data frames are
    % 12 bytes and include the frame number.
    properties
        % nx2 matrix of ASL frame numbers and clockFunction timestamps
        % @details
        % Each call to readRawData() adds a row to timedFrames.  The
        % first column contains frame numbers returned from as().
        % The second column contains a timestamp from clockFunction.
        % dotsReadableEyeASL assumes that the numbered frame coincided
        % with the timestamp.
        timedFrames = [];
        
        % the largest frame number integer that ASL can represent
        % @details
        % ASL reports frame numbers as integers which overflow
        % periodically.  readRawEyeData() uses frameMaxInt to correct for
        % the overflow, even if frames are dropped.
        frameMaxInt = (2^16)-1;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsReadableEyeASL()
            self = self@dotsReadableEye();
            self.initialize();
        end
        
        % Clear data from this object and the as() internal buffer.
        % @details
        % Extends the dotsReadable flushData() method to also clear out
        % the as() internal data buffer and discard old frame timestamps.
        function flushData(self)
            self.flushData@dotsReadableEye();
            if self.isAvailable
                as('reset');
            end
            self.timedFrames = [];
        end
    end
    
    methods (Access = protected)
        % Acquire ASL serial port resources.
        % @details
        % Initializes the the as() mex function, returns true if
        % successful, otherwise returns false.
        function isOpen = openDevice(self)
            self.closeDevice;
            isOpen = false;
            if exist('as', 'file') > 0
                try
                    isOpen = as('init') >= 0;
                    
                catch err
                    warning(err.message);
                end
            end
        end
        
        % Release ASL serial port resources.
        % @details
        % Closes the as() mex function.
        function closeDevice(self)
            if self.isAvailable
                as('close');
            end
        end
        
        % Read raw ASL data from the serial port.
        % @details
        % Reads out any buffered data frames from the as() mex function's
        % internal buffer.  Reformats the data in the dotsReadable style.
        % @details
        % as() reports data frames in four columns as
        %   - [x y pupil frameNumber]
        %   .
        % Converts these to the dotsReadable three-column style as
        %   - [xID, x, timestamp]
        %   - [yID, y, timestamp]
        %   - [pupilID, pupilSize, timestamp]
        %   .
        % where timestamp is derived from the ASL frameNumber,
        % sampleFrequency, and the current time.
        % @details
        % Appends the latest frameNumber and the current time to
        % timedFrames.
        function newData = readRawEyeData(self)
            if ~self.isAvailable
                newData = zeros(0, 3);
                return;
            end

            nowTime = feval(self.clockFunction);
            aslFrames = as('read');
            nData = 3*size(aslFrames, 1);
            newData = zeros(nData, 3);
            if nData > 0
                % align the last frame with the current time
                frameNumbers = aslFrames(:,4);
                self.timedFrames(end+1,1:2) = [frameNumbers(end), nowTime];
                
                % correct for integer overflow
                frameNumbers = self.correctOverflow( ...
                    frameNumbers, self.frameMaxInt);
                
                % frame numbers to local time values
                frameTimes = dotsReadableEyeASL.computeFrameTimes( ...
                    frameNumbers, nowTime, ...
                    self.sampleFrequency);
                
                % data to dotsReadable format
                xIndexes = 1:3:nData;
                newData(xIndexes,1) = self.xID;
                newData(xIndexes,2) = aslFrames(:,2);
                newData(xIndexes,3) = frameTimes;
                
                yIndexes = 2:3:nData;
                newData(yIndexes,1) = self.yID;
                newData(yIndexes,2) = aslFrames(:,3);
                newData(yIndexes,3) = frameTimes;
                
                dIndexes = 3:3:nData;
                newData(dIndexes,1) = self.pupilID;
                newData(dIndexes,2) = aslFrames(:,1);
                newData(dIndexes,3) = frameTimes;
            end
        end
    end
    
    methods (Static)
        % Try to correct frame numbers which overflowed.
        % @param frameNumbers ASL integer frame numbers
        % @param maxInt the largest integer ASL can represent
        % @details
        % Attempts to correct frame numbers that overflowed their integer
        % representation.  Assumes that frame numbers should always
        % increase.  Where they decrease, adds @a maxInt + 1 as though the
        % next more significant digit were present.
        function frameNumbers = correctOverflow(frameNumbers, maxInt)
            rollover = diff(frameNumbers) < 0;
            if any(rollover)
                ii = find(rollover, 1) + 1;
                frameNumbers(ii:end) = ...
                    frameNumbers(ii:end) + maxInt + 1;
            end
        end
        
        % Compute frame times based on frame numbers.
        % @param frameNumbers ASL integer frame numbers
        % @param nowTime the time to align with the last frame number
        % @param sampleFrequency ASL sample frequency
        % @details
        % Appends the lasts frame number in @a frameNumbers and the given
        % @a localTime to timedFrames.  Uses this pair and the ASL
        % sample frequency to compute a frame time for each frame number in
        % @a in frameNumbers.
        function frameTimes = computeFrameTimes( ...
                frameNumbers, nowTime, sampleFrequency)
            
            % compute frame times with last frame defined at nowTime
            frameNumbers = frameNumbers - frameNumbers(end);
            frameTimes = nowTime + (frameNumbers ./ sampleFrequency);
        end
        
        % Reconstruct ASL integer frame numbers from frame timestamps.
        % @param frameTimes frame times from computeFrameTimes()
        % @param timedFrames nx2 pairs of [frameNumber frameTime]
        % @param sampleFrequency ASL sample frequency
        % @details
        % Reconstructs the "raw" frame numbers reported by ASL, based on
        % data saved in the nx3 dotsReadable format.  This is intended to
        % help with post-hoc validation and analysis.
        % @details
        % Returns the frame number for each frame time in @a frameTimes.
        function frameNumbers = reconstructFrameNumbers( ...
                frameTimes, timedFrames, sampleFrequency)
            
            frameNumbers = zeros(size(frameTimes));
            
            nHints = size(timedFrames, 1);
            lastFrame = 0;
            for ii = 1:nHints
                nowNumber = timedFrames(ii,1);
                nowTime = timedFrames(ii,2);
                firstFrame = lastFrame + 1;
                lastFrame = find(frameTimes <= nowTime, 1, 'last');
                times = frameTimes(firstFrame:lastFrame);
                frameNumbers(firstFrame:lastFrame) = round( ...
                    ((times - nowTime) * sampleFrequency) + nowNumber);
            end
        end
    end
end