classdef dotsReadableEyeEyelink < dotsReadableEye
    % @class dotsReadableEyeEyelink
    % Reads Eyelink gaze and pupil size data.
    % @details
    % dotsReadableEyeEyelink extends the dotsReadableEye superclass to
    % acquire point of gaze and pupil size data from an Eyelink eye
    % tracker.
    % @details
    % It relies on mglEyelink functions which are part of the mgl project.
    properties
        % IP address of the Eyelink machine
        eyelinkIP = '100.1.1.1';
        
        % connection type to Eyelink
        eyelinkConnectType = 0;
        
        % whether to record pupil width (1), height (2), or area (3)
        pupilType = 1;
        
        % whether to record Eyelink (true) or local (false) sample times
        isEyelinkTime = true;
        
        % function that returns the current time as a number
        clockFunction = mglGetSecs();
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsReadableEyeEyelink()
            self = self@dotsReadableEye();
            self.initialize();
        end
    end
    
    methods (Access = protected)
        % Acquire Eyelink resources.
        function isOpen = openDevice(self)
            
            % release stale resources
            self.closeDevice();
            
            isOpen = false;
            if exist('mglEyelinkOpen', 'file') > 0
                try
                    % connect to the Eyelink machine via Ethernet
                    status = mglEyelinkOpen( ...
                        self.eyelinkIP, self.eyelinkConnectType);
                    isOpen = status > 0;
                    
                catch err
                    warning(err.message);
                end
            end
        end
        
        % Release Eyelink resources.
        function closeDevice(self)
            if self.isAvailable
                mglEyelinkClose();
            end
        end
        
        % Read raw Eyelink data.
        % @details
        % Reads out any buffered data from Eyelink.  Reformats the data in
        % the dotsReadable style.
        % @details
        % mglPrivateEyelinkGetCurrentSample() returns a single sample in a
        % 10-element matrix.  The elements want about are
        %   - 1 x position
        %   - 2 y position
        %   - 5 pupil width
        %   - 6 pupil height
        %   - 7 pupil area
        %   - 8 timestamp
        %   .
        % Converts these to the dotsReadable three-column style as
        %   - [xID, x, timestamp]
        %   - [yID, y, timestamp]
        %   - [pupilID, pupilSize, timestamp]
        %   .
        % where timestamp is derived from the Eyelink frameNumber, and
        % sampleFrequency.
        function newData = readRawEyeData(self)
            if ~self.isAvailable
                newData = zeros(0, 3);
                return;
            end
            
            % parse a sample matrix
            sample = mglPrivateEyelinkGetCurrentSample();
            x = sample(1);
            y = sample(2);
            
            % choose pupil statistic
            switch self.pupilType
                case 1
                    % width
                    pupil = sample(5);
                    
                case 2
                    % height
                    pupil = sample(6);
                    
                case 3
                    % area
                    pupil = sample(7);
                    
                otherwise
                    % width
                    pupil = sample(5);
            end
            
            % choose a time stamp
            if self.isEyelinkTime
                time = sample(8);
            else
                time = feval(self.clockFunction);
            end
            
            % package up data in dotsReadable format
            newData = zeros(3, 3);
            newData(1,:) = [self.xID x time];
            newData(2,:) = [self.yID y time];
            newData(3,:) = [self.pupilID pupil time];
        end
    end
end