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
            'gains',             [100 500], ...
            'frequency',         1000, ...   % Hz
            'duration',          20);        % in seconds
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
            
            % Reset the index
            self.inputIndex = 1;
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
            %
            %          % for debugging
            %          if nargin < 1 || isempty(dataPath)
            %             dataMatrix = [];
            %             tags = [];
            %             return
            %          end
            %
            %          if isempty(strfind(dataPath, '_EyePupilLabs'))
            %             dataPath = [dataPath '_EyePupilLabs'];
            %          end
            %
            %          % load into a temporary file... not sure how else to do this (yet)
            %          tmpFileName = 'tmpDataFile';
            %
            %          % Set up the return values
            %          tags = {'time', 'gaze_x', 'gaze_y', 'confidence'};
            %          dataMatrix = [];
            %
            %          % Loop through the subdirectories, getting the data
            %          dirs = dir(fullfile(dataPath, '0*'));
            %          for dd = 1:length(dirs)
            %             rawFileWithPath = fullfile(dataPath, dirs(dd).name, 'pupil_data');
            %             commandStr = sprintf('/Users/jigold/anaconda/bin/python3 /Users/jigold/GoldWorks/Local/LabCode/Lab-Matlab-Control/Tasks/ModularTasks/Utilities/readPupilLabsData.py %s %s', ...
            %                rawFileWithPath, tmpFileName);
            %             system(commandStr);
            %
            %             % collect the data
            %             load(tmpFileName);
            %
            %             % concatenate
            %             dataMatrix = cat(1, dataMatrix, eval(tmpFileName));
            %          end
            %
            %          % clean up the tmp file
            %          system(sprintf('rm %s.mat', tmpFileName));
            %
            %          % Convert from cell array
            %          dataMatrix = cell2num(dataMatrix);
        end
        
        function data = getData(self)
            data = self.readRawEyeData();
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
            self.aInDevice.gains = [2 5];
             self.aInDevice.nSamples = ceil(self.deviceParameters.duration * ...
                 self.deviceParameters.frequency * 2);
            
            % Transfer the sample frequency
            self.sampleFrequency = self.aInDevice.frequency;
            
            % Probably should actually check
            isOpen = true;
        end
        
        %       %% calibrateDevice
        %       %
        %       %  Run pupil labs internal calibration routines with respect
        %       %   to world camera, then call dotsReadableEye.calibrateDevice
        %       %   to transform into snow-dots coordinates
        %       %
        %       % Returns status: 0 for good calibration, otherwise error
        %       function status = calibrateDevice(self, varargin)
        %
        %          % If any argument given, revert to dotsReadableEye calibrateDevice
        %          % Routine (used for special case of recentering)
        %          if nargin >= 2 && ~isempty(varargin{1})
        %             status = self.calibrateDevice@dotsReadableEye(varargin{:});
        %             return
        %          end
        %
        %
        %       end % calibrateDevice
        
        %% Overrides method from dotsReadableEye
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
            
            % Yes, this is odd. Still not sure why I need to call this three
            % times, but it seems to be necessary to retrieve all of the data
            %  (not doing so results in gaps)
            mexHID('check');
            mexHID('check');
            mexHID('check');
            
            % Get the waveforms
            [c, v, t, ~] = self.aInDevice.getScanWaveform();
            
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
                disp('here')
            end
            
            % Format data according to the dotsReadable format:
            %  <ID> <value> <timestamp>
            newData = cat(1, ...
                [repmat(self.xID, sum(LeyeH), 1) v(LeyeH)'.*self.deviceParameters.gains(1) t(LeyeH)'], ...
                [repmat(self.yID, sum(LeyeV), 1) v(LeyeV)'.*self.deviceParameters.gains(2) t(LeyeV)']); 
            
%            disp(newData(:,2))
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

