classdef dotsReadableEyeMouseSimulator < dotsReadableEye
   % dotsReadableEyeMouseSimulator
   %
   % Uses the mouse to simulate gaze position, for testing. Clicking the
   % button re-zeros the output
   %
   % 5/24/18 written by jig
   
   properties
      
      % The mouse object
      HIDmouse = [];
      
      % The mouse object component IDS (x,y,button)
      HIDmouseComponentIDs;
      
      % Scale factor.. could calibrate this if we wanted to be fancy
      mouseScaleFactor = 10;
   end
   
   properties (SetAccess = private)
      
      % data buffer
      data = [];
      
      % index into data buffer
      index = 0;
      
      % tic start
      tstart = [];
   end
   
   %% Public method
   methods
      
      % Constructor method
      function self = dotsReadableEyeMouseSimulator(matching, frequency)
         self = self@dotsReadableEye();
         
         if nargin < 1
            matching = [];
         end
         
         % get the mouse object
         self.HIDmouse = dotsReadableHIDMouse(matching);
         
         % Get and save mouse component IDs... first two are x,y, last is
         % button press
         self.HIDmouseComponentIDs = getComponentIDs(self.HIDmouse);
         
         % set a dummy sample frequency
         if nargin < 2 || isempty(frequency)
            self.sampleFrequency = 1000;
         else
            self.sampleFrequency = frequency;
         end
         
         % start clock
         self.tstart = tic;
      end
      
      % Get time using python time.time() function
      function time = getDeviceTime(self)
         
         time = toc(self.tstart); %feval(self.clockFunction);
         
%          [~, timeStr] = system('/Users/jigold/anaconda/bin/python3 /Users/jigold/GoldWorks/Local/LabCode/Lab-Matlab-Control/snow-dots/utilities/time.py');
%          time = str2double(timeStr);
%          self.lastTimeRef = time - mglGetSecs();
      end
   end
   
   %% Protected methods
   methods (Access = protected)
      
      function newData = readRawEyeData(self)
         
         % Read from the mouse
         self.HIDmouse.read();
         pause(1/self.sampleFrequency);
         
         % Check for button press
         if getValue(self.HIDmouse, self.HIDmouseComponentIDs(3))
            disp('BUTTON!')
            self.HIDmouse.flushData();
            self.HIDmouse.x = 0;
            self.HIDmouse.y = 0;
         end
         
         % save x,y values and timestamp
         time = toc(self.tstart); %time = feval(self.clockFunction);
         newData = [ ...
            self.xID self.HIDmouse.x/self.mouseScaleFactor time; ...
            self.yID -self.HIDmouse.y/self.mouseScaleFactor time];
         
         if self.isRecording
            self.index = self.index + 1;
            if size(self.data,1) > self.index
               self.data = cat(1, self.data, nans(1000,3));
            end
            self.data(self.index,:) = newData([5 3 4]);
         end
      end
      
      function closeDevice(self)
         
         % close the HID device
         self.HIDmouse.close();
      end
      
      %> Turn on data recording from the device (for subclasses).
      function isRecording = startRecording(self)
         
%          if isempty(self.filename)
%             self.filename = './dotsReadableEyeMouseSimulator_tmpFile';
%          end
%          
%          % Call python script
%          commandStr = sprintf('/Users/jigold/anaconda/bin/python3 /Users/jigold/GoldWorks/Local/LabCode/Lab-Matlab-Control/snow-dots/utilities/mouse.py > %s &', ...
%             fullfile(self.filepath, self.filename));
%          system(commandStr);
%          
         isRecording = true; % overriden by device-specific subclass
      end
      
      %> Turn off data recording from the device (for subclasses).
      function isRecording = stopRecording(self)
         
         data = self.data(1:self.index,:);
         save(fullfile(self.filepath, self.filename), 'data');
         
%          [~,cmdout] = system('ps -ef | grep mouse');
%          
%          if ~isempty(cmdout)
%             cmdout = strsplit(cmdout,'\n');
%             ind = cell2num(strfind(cmdout, 'python'))~=0;
%             if any(ind)
%                strs = strsplit(cmdout{ind});
%                system(sprintf('kill -9 %s', strs{3}));
%             end
%          end
%          
         isRecording = false; % overriden by device-specific subclass
      end
   end
   
   methods (Static)
      
      % readDataFromFile
      %
      % Utility for reading data from a raw data file of mouse positions
      %
      % dataPath is string filename, with path
      %
      % Returns data matrix, rows are times, columns are:
      %  1. timestamp
      %  2. gaze x
      %  3. gaze y
      function [data, tags] = readDataFromFile(filename)
         
         % for debugging
         if nargin < 1 || isempty(filename)
            filename = fullfile(DBSfilepath(), 'Pupil', 'data_2018_06_23_20_58_eye');
         end
         
         % Set up the return values
         tags = {'time', 'gaze_x', 'gaze_y'};
         
         load(filename);
         %          data = csvread(filename);
         %          data(:,2) =  data(:,2)/10;
         %          data(:,3) = -data(:,3)/10;
      end
   end
end