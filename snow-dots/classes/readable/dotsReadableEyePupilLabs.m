classdef dotsReadableEyePupilLabs < dotsReadableEye
   % dotsReadableEyePupilLabs
   %
   % This class implements code for Matlab to communicate and control the
   % PupilLabs eyetracking software, which is written in Python. This
   % class will also override some functions in addition to the ones
   % recommended in the dotsReadableEye superclass to provide better
   % functionality.
   %
   % Specifically, the transformRawData function will be overwritten to
   % directly transform PupilLab data to SnowDots coordinates without
   % needing user defined coordinates. This is done through the addition
   % of a calibration routine.
   %
   % Furthermore, this class will define serveral components so that data
   % from both eyes can be recorded. Additionally, it will record the gaze
   % data that is generated from PupilLab's native algorithm.
   %
   % There are several dependencies in addition to SnowDots that must be
   % installed for this class to operate correctly. Refer to the Gold Lab
   % wiki on GitHub for more details.
   %
   % See example code from pupil labs:
   %  https://github.com/pupil-labs/pupil-helpers/blob/master/matlab/pupil_remote_control.m
   %
   % 11/17/17   xd  wrote it
   % 5/25/18    jig updated
   
   properties
      
      % Communication with the pupil labs software and device
      PLcommunication = struct( ...
         'IP',                      '127.0.0.1',... % IP address
         'port',                    '50020',    ... % Port number
         'socketRefreshInterval',   20,          ... % in sec, may need to refresh socket
         'timeout',                 5000);          % Communiation timeout, in ms

      % Calibration of the pupil-labs device
      PLcalibration = struct( ...         
         'deltaX',                  10,         ... % How far on the X axis the calibration markers should be placed
         'deltaY',                  6,          ... % How far on the Y axis the calibration markers should be placed
         'size',                    1.6,        ... % Size of calibration marker (arbitrary units)
         'timeout',                 20);            % Calibration timeout, in sec
      
      % Whether or not to get each eye data along with overall gaze
      getRawEyeData = false;
   end
   
   properties (SetAccess = protected)
      
      % Define data component names
      componentNames = { ...
         'gaze x', 'gaze y', 'gaze confidence'...
         'eye0 x', 'eye0 y', 'eye0 pupil', 'eye0 confidence'...
         'eye1 x', 'eye1 y', 'eye1 pupil', 'eye1 confidence'}';

      % Data index for gaze signal confidence
      cID;
      
      % Data indices for eye 0, 1: x, y, pupil confidence
      eIDs;
   end
   
   properties (Access = private)
      
      % Communication IP/port information
      pupilLabSubAddress;
      
      % ZMQ context used to manage communications with PupilLabs
      zmqContext;
      
      % Communication port for control commands
      reqPort;

      % Communication port for obtaining data
      gazePort;
      
      % blank data matrix, to compute once and copy when we get data
      blankData;
      
      % Monitor round-trip time
      roundTripTime = nan;
      
      % Latest received message
      result;
      
      % Keep track of socket refresh
      lastSocketRefresh;
      
      % dummy index
      blankID = -1;
   end
   
   %% Public methods
   methods
      
      % Constructor method
      function self = dotsReadableEyePupilLabs()
         self = self@dotsReadableEye();

         % Set properties, including calibration parameters
         self.sampleFrequency = 200; % is there a way to query this?
         self.calibration.query = false; % turn this off by default

         % Initialize the object
         self.initialize();
         
         % This will initialize the python module in Matlab, which we
         % will need in order to read the data from PupilLabs which is
         % serialized in msg-pack format, and unfortunately there does
         % not exist a working Matlab library for this format.
         py.abs(0);
         
         % Turn off default instructions for calibration
         self.calibration.showMessage = false;
      end
      
      % refreshSocket
      %
      % This refreshes the connection between the mPupilLabs object
      % and the PupilLabs ZMQ network. Doing so flushes the queue of
      % data streamed from PupilLabs so you will get the latest data
      % instead of the oldest.
      function refreshSocket(self)
         zmq.core.close(self.gazePort);
         self.gazePort = zmq.core.socket(self.zmqContext,'ZMQ_SUB');
         zmq.core.connect(self.gazePort,self.pupilLabSubAddress);
         zmq.core.setsockopt(self.gazePort,'ZMQ_SUBSCRIBE','gaze');
         
         % Keep track of when this happens
         self.lastSocketRefresh = feval(self.clockFunction);
      end
      
      % Overloaded flushData method
      %
      % Refresh the pupil labs socket and call dotsReadable.flushData
      function flushData(self)
         
         % Close then open the socket
         self.refreshSocket();
         
         % flush any remaining local data
         self.flushData@dotsReadable();
      end
      
      % Makes the PupilLab timer start counting from (numeric) val.
      function setDeviceTime(self, val)
         
         % Check val argument, default to 0.0
         if nargin < 2 || ~isnumeric(val)
            val = 0.0;
         end
         
         % Convert val to a string and send it over the ZMQ network. We
         % receive a message from the network because Pupil Remote
         % provides a response signal.
         val = sprintf('%0.2f',val);
         zmq.core.send(self.reqPort,uint8(['T ' val]));
         self.result = zmq.core.recv(self.reqPort);
      end
      
      % Get the current time value on the PupilLabs software and
      % returns it as a numeric value. Units are in seconds. Also measures
      % round-trip time
      function time = getDeviceTime(self)
         self.refreshSocket();
         zmq.core.send(self.reqPort,uint8('t'));
         self.result = zmq.core.recv(self.reqPort);
         time = str2double(char(self.result));
      end
      
      % Report round-trip time of communication channel
      function time = getRoundTripTime(self)
         time = self.roundTripTime;
      end
   end
   
   %% Protected methods
   methods (Access = protected)
      
      %% openDevice
      %
      % This function connects this instance to the PupilLabs software.
      % Therefore, you must ensure that the software is up and running
      % for this function to work properly.
      function isOpen = openDevice(self)
         
         % Dumb check for zmq library for communicating with the pupil-labs
         % device
         if ~exist('matlab-zmq', 'dir')
            isOpen = false;
            return
         end
         
         % Set up a ZMQ context that will be used for managing all our
         % communications with PupilLabs
         self.zmqContext = zmq.core.ctx_new();
         
         % Create a socket to connect to the PupilLabs REQ port which
         % will allow us to send commands to the software in addition to
         % getting what the SUB port is.
         self.reqPort = zmq.core.socket(self.zmqContext,'ZMQ_REQ');
         
         % Set timeouts to avoid blocking if there are commumication issues
         zmq.core.setsockopt(self.reqPort,'ZMQ_SNDTIMEO',self.PLcommunication.timeout);
         %zmq.core.setsockopt(self.reqPort,'ZMQ_RCVTIMEO',self.timeout);
         
         % Open the communication channel
         isOpen = ~zmq.core.connect(self.reqPort,['tcp://' self.PLcommunication.IP ':' self.PLcommunication.port]);
         
         % Only continue if we have successfully opened a REQ connection
         if isOpen
            
            % Measure round-trip time
            now = feval(self.clockFunction);
            zmq.core.send(self.reqPort, uint8('t'));
            self.result = zmq.core.recv(self.reqPort);
            self.roundTripTime = feval(self.clockFunction) - now;
            
            % Query the ZMQ_REQ port for the value of the ZMQ_SUB port.
            zmq.core.send(self.reqPort,uint8('SUB_PORT'));
            self.result = zmq.core.recv(self.reqPort);
            self.pupilLabSubAddress = ...
               ['tcp://' self.PLcommunication.IP ':' char(self.result)];
            
            % Request a ZMQ_SUB port
            self.gazePort = zmq.core.socket(self.zmqContext,'ZMQ_SUB');
            
            % Set timeouts to avoid blocking if there are commumication issues
            %zmq.core.setsockopt(self.gazePort,'ZMQ_SNDTIMEO',self.timeout);
            %zmq.core.setsockopt(self.gazePort,'ZMQ_RCVTIMEO',self.timeout);
            
            % Connect to the sub socket
            isOpen = ~zmq.core.connect(self.gazePort,self.pupilLabSubAddress);
            
            % Subscribe to the gaze channel
            zmq.core.setsockopt(self.gazePort,'ZMQ_SUBSCRIBE','gaze');
         end
      end
      
      %% calibrateDevice
      %
      %  Run pupil labs internal calibration routines with respect
      %   to world camera, then call dotsReadableEye.calibrateDevice
      %   to transform into snow-dots coordinates
      % 
      % Returns status: 0 for good calibration, otherwise error
      function status = calibrateDevice(self, varargin)
         
         % If any argument given, revert to dotsReadableEye calibrateDevice
         % Routine (used for special case of recentering)
         if nargin >= 2 && ~isempty(varargin{1})
            status = self.calibrateDevice@dotsReadableEye(varargin{:});
            return
         end
          
         % Check to pause data recording
         if ~self.recordDuringCalibration && self.isRecording
            self.record(false);
            restartRecording = true;
         else
            restartRecording = false;
         end
         
         % Subscribe to calibration notification channel. This will give
         % us information about the calibration routine as it progresses
         % in the PupilLabs software. We will use this to determine when
         % to transition to the next calibration target.
         calNotify = zmq.core.socket(self.zmqContext,'ZMQ_SUB');
         zmq.core.connect(calNotify,self.pupilLabSubAddress);
         zmq.core.setsockopt(calNotify,'ZMQ_SUBSCRIBE','notify.calibration.');
         
         % Send calibration command to tell PupilLabs to start the
         % calibration process.
         zmq.core.send(self.reqPort,uint8('C'));
         self.result = zmq.core.recv(self.reqPort);
         
         % Show instructions
         dotsDrawableText.drawEnsemble([], {'Please look at each object and', ...
            'maintain fixation while it is showing.'}, true, 5, 0.3);
         
         % Make a drawing ensemble for the calibration target
         calibrationEnsemble = dotsDrawable.makeEnsemble('calibrationEnsemble', {});

         % Generate calibration target location and sizes
         xDist = self.PLcalibration.deltaX;
         yDist = self.PLcalibration.deltaY;
         targetPositions = [0 0; -xDist yDist; xDist yDist; xDist -yDist;...
            -xDist -yDist; xDist 0; -xDist 0; 0 yDist; 0 -yDist];
         sizes = (3:-1:1) .* self.PLcalibration.size;
         
         % Create the target. We only need to create the dotsDrawables
         % once, put it into the ensemble, and then change the x/y
         % position properties through the functions available in the
         % ensemble class.
         inds = nans(length(sizes),1);
         for ii = 1:length(sizes)
            
            % Make it
            t          = dotsDrawableTargets();
            t.colors   = mod(ii+1,2) * ones(1,3);
            t.height   = sizes(ii);
            t.width    = sizes(ii);
            t.isSmooth = false;
            
            % Add it to the ensemble
            inds(ii)   = calibrationEnsemble.addObject(t);
         end
         
         % Show the target on a white background
         dotsTheScreen.blankScreen(ones(1,3));
         
         % We present the calibration markers in a loop. The loop only
         % progresses when the PupilLab software sends out a message
         % saying that the current marker has been completely sampled.
         % Then, we change the position of the marker and present it
         % again.
         for jj = 1:size(targetPositions,1)
            
            % Present calibration target at the updated position
            calibrationEnsemble.setObjectProperty('xCenter',targetPositions(jj,1), inds);
            calibrationEnsemble.setObjectProperty('yCenter',targetPositions(jj,2), inds);
            
            % Draw the target and flip the buffer
            calibrationEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
            
            % Wait for PupilLab calibration sample done message
            msg = [];
            endTime = feval(self.clockFunction) + self.PLcalibration.timeout;
            while (isempty(strfind(msg, 'marker_sample_completed')) || ...
                  isempty(strfind(msg, 'timestamp'))) && ...
                  feval(self.clockFunction) < endTime
               msg = char(zmq.core.recv(calNotify,500));
               % disp(sprintf('msg is <%s>', msg))
            end
            
            % Check for timeout
            if isempty(msg)
               status = 1;
               return
            end
            
            % wait a bit between targets
            pause(0.5);
         end % for each target
         
         % Create a stop calibration target that is identical to the
         % calibration marker but with a flipped color scheme.
         
         % Show it on a black background
         dotsTheScreen.blankScreen(zeros(1,3));

         % Put it in the center
         calibrationEnsemble.setObjectProperty('xCenter', 0, inds);
         calibrationEnsemble.setObjectProperty('yCenter', 0, inds);
         for ii = 1:length(sizes)
            calibrationEnsemble.setObjectProperty( ...
               'colors', mod(ii,2) * ones(1,3), inds(ii));
         end
         
         % Show it
         calibrationEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
         
         % Wait for 'stopped' message from PupilLab
         warning('off','zmq:core:recv:bufferTooSmall');
         msg = [];
         endTime = feval(self.clockFunction) + self.PLcalibration.timeout;
         while isempty(strfind(msg, 'stopped')) && feval(self.clockFunction) < endTime
            msg = char(zmq.core.recv(calNotify,500));
         end
         warning('on','zmq:core:recv:bufferTooSmall');
         
         % Check for timeout
         if isempty(msg)
            status = 1;
            return
         end
         
         % Pause a moment to let pupilLabs get out of calibration mode
         pause(2.0);
         
         % Re-set device time
         self.setDeviceTime();
         
         % Call dotsReadableEye.calibrateDevice routine for general
         % eye-tracking calibration, including tranforming to snow-dots
         % coordinates
         status = self.calibrateDevice@dotsReadableEye;
         
         % Possibly restart recording
         if restartRecording
            self.record(true);
         end
      end % calibrateDevice
      
      %% Overloaded startRecording function
      %
      function isRecording = startRecording(self)
         
         % Check for filename
         if isempty(self.filename)
            
            % Use default filename, which is set in pupilLab GUI
            str = 'R';
         else
            
            % Use given filename. Note that the data path is still set in
            % the pupilLab GUI
            str = sprintf('R %s', self.filename);
         end
         
         % Turn on recording
         zmq.core.send(self.reqPort, uint8(str));
         self.result = zmq.core.recv(self.reqPort);
         isRecording = true;
      end % startRecording
      
      %% Overloaded stopRecording function
      %
      function isRecording = stopRecording(self)
         
         % Turn off recording
         zmq.core.send(self.reqPort, uint8('r'));
         self.result = zmq.core.recv(self.reqPort);
         isRecording = false;
      end % stopRecording
      
      %% Overrides method from dotsReadableEye
      %
      function components = openComponents(self)
         
         % Check whether getting all data or just gaze
         if self.getRawEyeData
            
            % Make all the components
            components = struct('ID', num2cell((1:size(self.componentNames,2))'), ...
               'name', self.componentNames);
            
            % Save raw eye IDs
            fstr = @(n,x) find(strcmp(['eye' num2str(n) ' ' x], self.componentNames));
            self.eIDs = [ ...
               fstr(0, 'x'), fstr(0, 'y'), fstr(0, 'pupil'), fstr(0, 'confidence'); ...
               fstr(1, 'x'), fstr(1, 'y'), fstr(1, 'pupil'), fstr(1, 'confidence')];
         else
            
            % Just make the gaze components
            components = struct('ID', num2cell((1:3)'), ...
               'name', self.componentNames(1:3));
         end
         
         % Alwats save gaze IDs
         self.xID = find(strcmp('gaze x', self.componentNames));
         self.yID = find(strcmp('gaze y', self.componentNames));
         self.cID = find(strcmp('gaze confidence', self.componentNames));

         % Make a blank data matrix of the correct size. When data come in,
         % we just copy and fill this
         self.blankData = cat(2, repmat(self.blankID,  numel(components), 1), ...
            nans(numel(components),2));

      end
      
      %% readRawEyeData
      %
      % Get data from PupilLabs. The format of this data is a struct
      % and details can be found here:
      %
      %   https://docs.pupil-labs.com/#pupil-datum-format
      %
      % We convert it to the dotsReadable format depending on what
      % value the dataTypeSelector flag is set to.
      function newData = readRawEyeData(self)
         
         % Possibly refresh the socket
         if ~isempty(self.PLcommunication.socketRefreshInterval)
            if isempty(self.lastSocketRefresh) || ...
                  ((feval(self.clockFunction) - self.lastSocketRefresh) > ...
                  self.PLcommunication.socketRefreshInterval)
               self.refreshSocket();
            end
         end
         
         % The first message tells us what type of data it is. The
         % second msg will actually give us the data.
         msg = zmq.core.recv(self.gazePort); %#ok<NASGU>
         msg = zmq.core.recv(self.gazePort,1500);
         
         % Here, we use a python package to format the raw data. It
         % gives us a python dict object which we must then convert into
         % a Matlab struct.
         data = py.msgpack.loads(msg,pyargs('encoding','utf-8'));
         dataStruct = struct(data);
         
         % Format data according to the dotsReadable format.
         newData = self.blankData;
         
         % Here we extract the gaze data. These will be in PupilLab
         % normalized coordinates and need to be transformed into screen
         % space.
         
         % Collect the data from the parsed struct
         gazePos = cell2num(cell(dataStruct.norm_pos));
         time    = dataStruct.timestamp;        
         
         % Set the data
         newData(self.xID,:) = [self.xID gazePos(1) time];
         newData(self.yID,:) = [self.yID gazePos(2) time];
         newData(self.cID,:) = [self.cID dataStruct.confidence time];

         % Conveniently, the gaze data struct contains the raw data
         %  for each individual eye used to determine the gaze. Thus,
         %  we can directly extract the data from there if needed.
         if self.getRawEyeData
            
            % Loop through the two eyes
            for ii = 1:length(dataStruct.base_data)
               
               % Extract the data
               pupilDataStruct = struct(dataStruct.base_data{ii});
               pupilPos = cell2num(cell(pupilDataStruct.norm_pos));
               pupilSize = pupilDataStruct.diameter;
               confidence = pupilDataStruct.confidence;
               time = pupilDataStruct.timestamp;
               id = int64(pupilDataStruct.id);
               
               newData(self.eIDs(id+1,1),:) = [self.eIDs(id+1,1) pupilPos(1)  time];
               newData(self.eIDs(id+1,2),:) = [self.eIDs(id+1,2) pupilPos(2)  time];
               newData(self.eIDs(id+1,3),:) = [self.eIDs(id+1,3) pupilSize    time];
               newData(self.eIDs(id+1,4),:) = [self.eIDs(id+1,4) confidence   time];
            end
         end
      end
      
      %% Transform the normalized x/y eye data into screen coordinates
      %  with units of degrees visual angle
      %
      function newData = transformRawData(self, newData)
         
         % Transform gaze x,y
         newData = self.transformRawData@dotsReadableEye(newData);
         
         % check for all data
         if self.getRawEyeData
            
            for ee = 1:2
               % Calibrate each eye separately
               newData = self.transformRawData@dotsReadableEye( ...
                  newData, self.eIDs(ee,[1 2]));
            end            
         end            
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
         
         % Dumb check that this isn't a loaded file
         if ~isempty(self.reqPort) && ~isempty(self.lastSocketRefresh) && ...
               (feval(self.clockFunction) - self.lastSocketRefresh)/60 < .1
            
            % possibly turn off recording
            if self.isRecording
               zmq.core.send(self.reqPort, uint8('r'));
               self.result = zmq.core.recv(self.reqPort);
            end
            
            % Disconnect and close the data port
            zmq.core.disconnect(self.gazePort, self.pupilLabSubAddress);
            zmq.core.close(self.gazePort);
            self.gazePort = [];
            
            % Disconnect and close the control port
            zmq.core.disconnect(self.reqPort, ['tcp://' self.PLcommunication.IP ':' self.PLcommunication.port]);
            zmq.core.close(self.reqPort);
            self.reqPort = [];
            
            % Close the context
            % zmq.core.ctx_shutdown(self.zmqContext);
            % zmq.core.ctx_term(self.zmqContext);
         end
      end
   end
   
   methods (Static)
   
      % Load raw data from file
      %
      %
      % filename is string pathname where the pupil-labs folder is located
      % ecodes is optional ecodes struct
      %
      % Returns eye data struct (see dotsReadableEye) with data columns:
      %  1. timestamp
      %  2. gaze x
      %  3. gaze y
      %  4. confidence
      %  5. pupil_0
      %  6. pupil_1
      function data = loadRawData(dirname, ecodes, helper)
         
         % Need filename argument
         if nargin < 1 || isempty(dirname)
            data = [];
            return
         end
         
         % CONSTANTS
         pythonWithPath = '/Users/jigold/anaconda/bin/python3';
         pythonCmd      = '/Users/jigold/GoldWorks/Local/LabCode/Lab-Matlab-Control/Tasks/ModularTasks/Utilities/readPupilLabsData.py';
         tmpFileName    = 'tmpDataFile';
        
         % Set up the return values
         tags = {'time', 'gaze_x', 'gaze_y', 'confidence', 'pupil_0', 'pupil_1'};
         data = [];
         
         % Loop through the subdirectories, getting the data
         dirs = dir(fullfile(dirname, '0*'));
         for dd = 1:length(dirs)

            % load into a temporary file... not sure how else to do this (yet)
            commandStr = sprintf('%s %s %s gaze %s', ...
               pythonWithPath, pythonCmd, fullfile(dirname, dirs(dd).name), tmpFileName);
            system(commandStr);
            
            % collect the data
            load(tmpFileName);
            
            % concatenate 
            data = cat(1, data, eval(tmpFileName));
         end
      
         % clean up the tmp file
         system(sprintf('rm %s.mat', tmpFileName));
         
         % Convert from cell array
         data = cell2num(data);

         % Calibrate and synchronize using data from the current topsDataLog
         if nargin > 1 && ~isempty(ecodes)
         
            % Calibrate
            %
            % Get indices of relevant data columns
            eti  = find(strcmp(tags, 'time'));
            exi  = find(strcmp(tags, 'gaze_x'));
            eyi  = find(strcmp(tags, 'gaze_y'));

            % Calibrate from the dataLog calibration data
            data(:,[eti exi eyi]) = ...
               dotsReadableEye.calibrateGazeSets( ...
               data(:,[eti exi eyi]), ...
               topsDataLog.getTaggedData(['calibrate ' mfilename]));

            % Synchronize
            %
            data = dotsReadableEye.parseRawData(data, tags, ...
               topsTaskHelper.getSynchronizationData(mfilename));
         end 
      end
   end
end

