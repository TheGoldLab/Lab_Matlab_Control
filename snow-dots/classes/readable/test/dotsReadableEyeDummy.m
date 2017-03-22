classdef dotsReadableEyeDummy < dotsReadableEye
    % @class dotsReadableEyeDummy
    % Reads fake, static data as from an eye tracker.
    % @details
    % dotsReadableEyeDummy extends the dotsReadableEye superclass to
    % generate fake, x, y, and pupil data.
    properties
        % false x-position, as though from eye tracker hardware
        inputX = 0;
        
        % false y-position, as though from eye tracker hardware
        inputY = 0;
        
        % false pupil size, as though from eye tracker hardware
        inputPupil = 0;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsReadableEyeDummy()
            self = self@dotsReadableEye();
            self.initialize();
        end
    end
    
    methods (Access = protected)
        % Acquire dummy resources.
        function isOpen = openDevice(self)
            self.sampleFrequency = 60;
            isOpen = true;
        end
        
        % Release dummy resources.
        % @details
        function closeDevice(self)
            self.isAvailable = false;
        end
        
        % Create random data.
        function newData = readRawEyeData(self)
            n = numel(self.inputX);
            xData = zeros(n, 3);
            xData(:,1) = self.xID;
            xData(:,2) = self.inputX;
            xData(:,3) = topsClock();
            
            yData = zeros(n, 3);
            yData(:,1) = self.yID;
            yData(:,2) = self.inputY;
            yData(:,3) = topsClock();
            
            pupilData = zeros(n, 3);
            pupilData(:,1) = self.pupilID;
            pupilData(:,2) = self.inputPupil;
            pupilData(:,3) = topsClock();
            
            newData = cat(1, xData, yData, pupilData);
            
            % pretend it takes time to read data
            pause(1/self.sampleFrequency);
        end
    end
end