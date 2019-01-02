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
      rawGainH = 50;
      rawGainV = 50;
   end
   
   properties (SetAccess = protected)
      
      % Define data component names
      componentNames = {'x', 'y'}';
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
         self = self@dotsReadableEye();
         
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
      end
      
      % endTrial
      %
      % Stop scan at the end of each trial
      function finishTrialDevice(self)
         
         % Stop the scan
         self.aInDevice.stopScan();
      end
      
      % readDataFromFile
      %
      % Utility for reading data from a pupillabs folder
      %
      % dataPath is string pathname to where the pupil-labs folder is
      %
      % Returns data matrix, rows are times, columns are:
      %  1. timestamp
      %  2. gaze x
      %  3. gaze y
      function [dataMatrix, tags] = readRawDataFromFile(self, dataPath)
         
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
            h1 = find(LeyeH,1);
            v1 = find(LeyeV,1);
            if h1 < v1
               LeyeV = LeyeV & [LeyeH(2:end) false];
               LeyeH = LeyeH & [LeyeV(2:end) false];
            else
               LeyeV = LeyeV & [LeyeH(2:end) false];
               LeyeH = LeyeH & [LeyeV(2:end) false];
            end
         end
         
         if sum(LeyeV) ~= sum(LeyeH)
            disp('error parsing EOG channels')
         end
         
         % Format data according to the dotsReadable format:
         %  <ID> <value> <timestamp>
         newData = cat(1, ...
            [repmat(self.xID, sum(LeyeH), 1) v(LeyeH).*self.rawGainH t(LeyeH)], ...
            [repmat(self.yID, sum(LeyeV), 1) v(LeyeV).*self.rawGainH t(LeyeV)]);
         
         % disp(newData(:,2))
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

