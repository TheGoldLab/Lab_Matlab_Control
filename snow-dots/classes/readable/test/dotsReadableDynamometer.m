classdef dotsReadableDynamometer < dotsReadable
   % dotsReadableDynamometer
   %
   % Requires vernier-toolbox for communicating with the dynamometer
   %
   % 9/16/18 written by jig
   
   properties
      
      % Possibly have more than one set up 
      numSensors = 2;
      
      % Sample rate (Hz) -- hard wired for now
      sampleRate = 200;
   end
   
   properties (SetAccess = private)

      % the object used by the vernier-toolbox
      dynamometers;
      
      % blank data matrix, to compute once and copy when we get data
      blankData;
   end
   
   %% Public methods
   methods
      
      % Constructor method
      function self = dotsReadableDynamometer(numSensors)
         self = self@dotsReadable();
         
         % Set the number needed
         if nargin >= 1
            self.numSensors = numSensors;
         end
         
         % Initialize the object
         self.initialize();
      end
      
      % Show value
   end
   
   %% Protected methods
   methods (Access = protected)
      
      % openDevice
      %
      function isOpen = openDevice(self)
         
         % default
         isOpen = false;
         
         % open them - not checking if each device is opened successfully
         for ii = 1:self.numSensors
            self.dynamometers(ii) = dynamometer();
            if ~isempty(self.dynamometers(ii))
               isOpen = true;
            end
         end
         
         % set up blank data
         self.blankData = cat(2, ...
            (1:self.numSensors)', ...
            zeros(self.numSensors, 2));
      end
      
      % closeDevice
      %
      function closeDevice(self)
         
         % closes all at once
         if ~isempty(self.dynamometers)
            self.dynamometers.close();
         end
      end
      
      % openComponents
      %
      % Set up one component per sensor
      %
      function components = openComponents(self)
         
         % The components are just the sensors, ID=index
         components = struct( ...
            'ID', num2cell((1:self.numSensors)'), ...
            'name', strrep('sensor%d', '%d', cellstr(num2str((1:self.numSensors)'))));
      end
      
      % startRecording
      %
      % This causes data to be stored in a buffer that can be retrieved via
      %  get_buffer
      %
      function isRecording = startRecording(self)
         
         % call start method
         self.dynamometers.start();
         
         % return flag
         isRecording = true;
      end
      
      % stopRecording
      %
      function isRecording = stopRecording(self)
         
         % call start method
         self.dynamometers.stop();
         
         % return flag
         isRecording = false;
      end
      
      % getBufferedData
      %
      % Gets all buffered data since last start
      %
      function data = getBufferedData(self)
      end
      
      % newData rows are per sensor, columns are:
      %  sensor ID
      %  sensor value
      %  timestamp
      function newData = readNewData(self)
         
         % Get the blank data matrix
         newData = self.blankData;
         
         % Fill in the sensor values
         for ii = 1:self.numSensors
            newData(ii,2) = self.dynamometers(ii).read;
         end
         
         % Fill in the current time
         newData(:,3) = feval(self.clockFunction);
      end
   end
end