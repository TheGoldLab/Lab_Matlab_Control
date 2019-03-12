classdef dotsReadableEyeEOG < dotsReadableEye
    % dotsReadableEyeEOG
    %
    % This class implements code for Matlab to read eye-movement signals
    %  via the electrooculogram (EOG).
    %
    % [ADD NOTES ABOUT ELECTRODE PLACEMENT]
    %
    % 10/04/18    created by jig
    
    properties
        
        % Parameters for communicating with the input device
        %  On the 1208FS:
        %     channel 0, differential mode  is pins 1 and 2
        %     channel 1, differential mode, is pins 4 and 5
        deviceParameters = struct( ...
            'channels',          [0 1], ...
            'gains',             [4 4], ...  % see AInScan1208FS
            'frequency',         1000,  ...  % Hz
            'duration',          20);        % in seconds
        
        % Gains to apply to the raw inputs, which is useful for
        % visualizing the data on the eye monitor before calibration
        rawGainH = 100;
        rawGainV = 100;
        
        % The world's simplest blink filter (multiplied by rawGainV)
        blinkThreshold = 0.25;
        
        % Smoothing window size (half-width, in samples)
        bufferHW = 50;
    end
    
    properties (SetAccess = protected)
        
        % Define data component names
        componentNames = {'x', 'y'}';
        
        % Keep buffered data, for smoothing
        bufferedVals = [];
    end
    
    properties (Access = private)
        
        % Analog input device
        aInDevice;
        
        % Index into current data stream
        inputIndex;
        
        % blank data matrix, to compute once and copy when we get data
        blankData;
        
        % dummy index
        blankID = -1;
    end
    
    %% Public methods
    methods
        
        % Constructor method
        function self = dotsReadableEyeEOG()
            
            % Make the object from the superclass
            self = self@dotsReadableEye();
            
            % Set calibration parameters
            self.calibration.query = false; % turn this off by default
            
            % Initialize the object
            self.initialize();
        end
        
        % beginTrial
        %
        % Start scan at the beginning of each trial
        function startTrialDevice(self)
            
            % Get the device ready
            self.aInDevice.prepareToScan();
            
            % Start the scan
            self.aInDevice.startScan();
            
            % Clear the index
            self.inputIndex = [];
            
            % Clear the buffer
            self.bufferedVals(:) = nan;
        end
        
        % endTrial
        %
        % Stop scan at the end of each trial
        function finishTrialDevice(self)
            
            % Stop the scan
            self.aInDevice.stopScan();
        end
        
        % for debugging
        function preview(self, duration)
            if nargin < 2 || isempty(duration)
                duration = 10;
            end
            
            % Call the ain method
            self.aInDevice.preview([], duration)
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        
        %% openDevice
        %
        % This function connects this instance to the 1208FS device.
        function isOpen = openDevice(self)
            
            % Get the instance
            self.aInDevice = AInScan1208FS();
            
            % Set device properties
            self.aInDevice.channels  = self.deviceParameters.channels;
            self.aInDevice.frequency = self.deviceParameters.frequency;
            self.aInDevice.gains     = self.deviceParameters.gains;
            self.aInDevice.nSamples = ceil(self.deviceParameters.duration * ...
                self.deviceParameters.frequency * length(self.deviceParameters.channels));
            
            % Transfer the sample frequency
            self.sampleFrequency = self.aInDevice.frequency;
            
            % Set up the buffer
            self.bufferedVals = nans(self.bufferHW*2+1, 2);
            
            % Probably should actually check
            isOpen = true;
        end
        
        % Overloaded openComponents method: just x and y
        %
        function components = openComponents(self)
            
            % Make the components
            components = struct( ...
                'ID',    num2cell(1:size(self.componentNames,1))', ...
                'name',  self.componentNames);
            
            % Save IDs
            self.xID = find(strcmp('x', self.componentNames));
            self.yID = find(strcmp('y', self.componentNames));
            
            % Make a blank data matrix of the correct size. When data come in,
            % we just copy and fill this
            self.blankData = cat(2, repmat(self.blankID,  numel(components), 1), ...
                nans(numel(components),2));
        end
        
        %% readRawEyeData
        %
        % Get EOG data.
        function newData = readRawEyeData(self)
            
            % Get the latest waveforms, waiting for data
            [c, v, t, ~] = self.aInDevice.getScanWaveform(true, true);
            
            % Check for data
            if isempty(c)
                newData = [];
                return
            end
            
            % Get the two channels
            LeyeH = c==self.deviceParameters.channels(1);
            LeyeV = c==self.deviceParameters.channels(2);
            
            % Special case of one more sample in either channel
            if sum(LeyeH) ~= sum(LeyeV)
                badIndices = find(diff(c)==0);
                if c(1) == c(end) && c(1) ~= c(2)
                    badIndices = [1; badIndices];
                end
                if ~isempty(badIndices)
                    LeyeH(badIndices) = false;
                    LeyeV(badIndices) = false;
                end
                if sum(LeyeV) ~= sum(LeyeH)
                    disp('error parsing EOG channels')
                end
            end
            
            % Scale the inputs
            hVals = v(LeyeH).*self.rawGainH;
            vVals = v(LeyeV).*self.rawGainV;
            
            % Smooth it
            if self.bufferHW > 0
               
               % Concatenate horizontal, vertical samples with buffers
               hWithBuffer = cat(1, self.bufferedVals(:,1), hVals);
               vWithBuffer = cat(1, self.bufferedVals(:,2), vVals);
               
               % Save the new (unsmoothed) buffers
               bufSz = self.bufferHW*2+1;
               self.bufferedVals(:,1) = hWithBuffer(end-bufSz+1:end);
               self.bufferedVals(:,2) = vWithBuffer(end-bufSz+1:end);
               
               % Smooth each channel using extra buffered data
               smoothedH = smooth(hWithBuffer, bufSz);% , 'sgolay');
               hVals = smoothedH(self.bufferHW+1:end-self.bufferHW-1);
               smoothedV = smooth(vWithBuffer, bufSz);% , 'sgolay');
               vVals = smoothedV(self.bufferHW+1:end-self.bufferHW-1);
            end
            
            % Format data according to the dotsReadable format:
            %  <ID> <value> <timestamp>
            newData = cat(1, ...
                [repmat(self.xID, sum(LeyeH), 1) hVals t(LeyeH)], ...
                [repmat(self.yID, sum(LeyeV), 1) vVals t(LeyeV)]);
            
            % disp(newData(:,2))
        end
        
        %% Get current fixation
        %
        function fixXY = getFixation(self, timeout, waitForSaccade, doTransform)
            
            % For debugging
            %             persistent f
            %             if isempty(f)
            %                 f = figure;
            %             end
            
            % Check arg
            if nargin < 2 || isempty(timeout)
                timeout = 1.0;
            end
            
            % Wait
            pause(timeout);
            
            % Get the data
            newData = self.readRawEyeData();
            
            % Take only the data over requsted interval
            Lgood = newData(:,3) >= (max(newData(:,3)) - timeout);
            newData = newData(Lgood,:);
            
            % Make sure we have equal x,y
            Lx = newData(:,1)==self.xID;
            Ly = newData(:,1)==self.yID;
            
            % Remove extra
            if sum(Lx) > sum(Ly)
                Lx(find(Lx,1)) = false;
            elseif sum(Ly) > sum(Lx)
                Ly(find(Ly,1)) = false;
            end
            
            % Possibly transform
            if nargin >= 4 && doTransform
                newData(Lx|Ly,:) = self.transformRawData(newData(Lx|Ly,:));
            end
            
            % Save as x, y
            xs = newData(Lx,2);
            ys = newData(Ly,2);
            
            % Check for saccade or not
            if nargin >= 3 && waitForSaccade
                
                % check for blink
                if any(ys>self.rawGainV*self.blinkThreshold);                    
                    fixXY = [];
                    return
                end
                
                % Look for max dist from initial position
                ind = min(10, floor(length(xs)/4));
                dist = sqrt((xs-median(xs(1:ind))).^2 + (ys-median(ys(1:ind))).^2);
                ind = find(dist==max(dist),1);
                fixXY = [xs(ind) ys(ind)];
            else
                fixXY = median([xs ys]);
            end
            
            % For debugging
            %             oldfig = gcf;
            %             figure(f);
            %             subplot(2,1,1); cla reset; hold on;
            %             plot(xs, 'b-');
            %             plot(ys, 'r-');
            %             plot([0 250], fixXY([1 1]), 'b-')
            %             plot([0 250], fixXY([2 2]), 'r-')
            %             subplot(2,1,2); cla reset; hold on;
            %             plot(xs,ys,'k.')
            %             plot(fixXY(1), fixXY(2), 'ro');
            %             axis([-20 20 -20 20]);
            %             pause(0.5)
            %             figure(oldfig);
        end
        
        %% Transform the normalized x/y eye data into screen coordinates
        %  with units of degrees visual angle
        %
        function newData = transformRawData(self, newData)
            
            % Transform gaze x,y
            newData = self.transformRawData@dotsReadableEye(newData);
        end
        
        %% Override default setupCoordinateRectTransform function
        %  from dotsReadableEye because we do our own calibration here and
        %  don't want to use those transformations
        %
        function setupCoordinateRectTransform(self)
        end
        
        %% Close the communication channels with pupilLab
        %
        function closeDevice(self)
            
            % Just close it
            if ~isempty(self.aInDevice)
                self.aInDevice.close();
            end
        end
    end
end

