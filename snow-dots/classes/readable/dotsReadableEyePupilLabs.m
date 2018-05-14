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
   
   properties
      
      % IP address of PupilLab Remote plugin (string)
      pupilLabIP = '127.0.0.1';
      
      % Port for PupilLab Remote plugin (string)
      pupilLabPort = '50020';
      
      % IP/port information for showing calibration graphics on remote
      % screen. Cell array of either:
      %  {false} for local mode, or
      %  {true <local IP> <local port> <remote IP> <remote port>}
      ensembleRemoteInfo = {false};
      
      % windowRect for showing calibration graphics.. default for
      %  GeChic monitor
      windowRect = [0 0 1920 1080];
      
      % Whether or not to get each eye data along with overall gaze
      getRawEyeData = false;
      
      % How far on the X axis the calibration markers should be placed
      calibDeltaX = 10;
      
      % How far on the Y axis the calibration markers should be placed
      calibDeltaY = 6;
      
      % Size of calibration marker (arbitrary units)
      calibSize = 1;
      
      % communiation timeout, in ms
      timeout = 1000;
      
      % flag to tell pupil labs to record data
      autoRecord = true;
   end
   
   properties (SetAccess = protected)
      % Indices for the various data components. g is for gaze while p is
      % for pupil. For the pupil indices, the first one corresponds to
      % pupil0 in PupilLab and the second one corresponds to pupil1.
      gXID = [];
      gYID = [];
      gCID = [];
      
      pXIDs = [];
      pYIDs = [];
      pDIDs = [];
      pCIDs = [];
      
      blankID = -1;
      
      % monitor round-trip time
      roundTripTime = nan;
      
      % latest received message
      result;
   end
   
   properties (Access = private)
      % Variables for controlling the connection between Matlab and
      % PupilLabs.
      pupilLabSubAddress;
      zmqContext;
      req = [];
      gaze = [];
      
      % Variables for transforming from PupilLab space to SnowDots space
      scale;
      rotation;
      translation;
   end
   
   %% Public methods
   methods
      
      % Constructor method
      function self = dotsReadableEyePupilLabs()
         self = self@dotsReadableEye();
         self.sampleFrequency=200; % is there a way to query this?
         self.initialize();
         
         % This will initialize the python module in Matlab, which we
         % will need in order to read the data from PupilLabs which is
         % serialized in msg-pack format, and unfortunately there does
         % not exist a working Matlab library for this format.
         py.abs(0);
      end
      
      % refreshSocket
      %
      % This refreshes the connection between the mPupilLabs object
      % and the PupilLabs ZMQ network. Doing so flushes the queue of
      % data streamed from PupilLabs so you will get the latest data
      % instead of the oldest.
      function refreshSocket(self)
         zmq.core.close(self.gaze);
         self.gaze = zmq.core.socket(self.zmqContext,'ZMQ_SUB');
         zmq.core.connect(self.gaze,self.pupilLabSubAddress);
         zmq.core.setsockopt(self.gaze,'ZMQ_SUBSCRIBE','gaze');
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
         zmq.core.send(self.req,uint8(['T ' val]));
         char(zmq.core.recv(self.req));
      end
      
      % Get the current time value on the PupilLabs software and
      % returns it as a numeric value. Units are in seconds.
      function time = getDeviceTime(self)
         zmq.core.send(self.req,uint8('t'));
         time = str2double(char(zmq.core.recv(self.req)));
      end
      
      % Report round-trip time of communication channel
      function time = getRoundTripTime(self)
         time = self.roundTripTime;
      end
      
%       function data = readAndReturnData(self)
%          data = self.readNewData();
%       end
%       
      % calibrateSnowDots
      %
      % Calibrate with respect to snow-dots coordinates (deg vis angle)
      function calibrateSnowDots(self)
         
         % make calibration ensemble
         calibrationEnsemble = dotsEnsembleUtilities.makeEnsemble(...
            'calibEnsemble', self.remoteInfo{:});
         calibrationEnsemble.automateObjectMethod('draw', ...
            @dotsDrawable.drawFrame, {}, [], true);
         
         % Generate Fixation spots
         %
         % We will create a single drawable object to represent the fixation cue.
         % Then, we simply adjust the location of the cue each time we present it.
         fixationCue = dotsDrawableTargets();
         calibrationEnsemble.addObject(fixationCue);
         
         xdist = 10;
         ydist = 5;
         pos = [-xdist ydist; xdist ydist; xdist -ydist; -xdist -ydist];
         
         % Present cues
         n = 500;
         fixationData = cell(size(pos,1),1);
         for ii = 1:length(fixationData)
            data = zeros(n,2);
            
            calibrationEnsemble.setObjectProperty('width',[0 0]);
            calibrationEnsemble.setObjectProperty('height',[0 0]);
            calibrationEnsemble.callObjectMethod(@prepareToDrawInWindow);
            calibrationEnsemble.run(1);
            
            calibrationEnsemble.setObjectProperty('xCenter',[pos(ii,1) pos(ii,1)]);
            calibrationEnsemble.setObjectProperty('yCenter',[pos(ii,2) pos(ii,2)]);
            calibrationEnsemble.setObjectProperty('width',[1 0.1] * 3);
            calibrationEnsemble.setObjectProperty('height',[0.1 1] * 3);
            
            calibrationEnsemble.callObjectMethod(@prepareToDrawInWindow);
            calibrationEnsemble.run(1);
            
            self.refreshSocket();
            for jj = 1:n
               dataMatrix = self.readRawEyeData();
               data(jj,:) = dataMatrix([self.gXID, self.gYID],2)';
            end
            
            fprintf('Finished collecting data for cue %d\n',ii);
            fixationData{ii} = data;
         end
         
         calibrationEnsemble.setObjectProperty('width',[0 0]);
         calibrationEnsemble.setObjectProperty('height',[0 0]);
         calibrationEnsemble.callObjectMethod(@prepareToDrawInWindow);
         calibrationEnsemble.run(1);
         
         % Find average fixation location
         meanFixations = cellfun(@(X)mean(X),fixationData,'UniformOutput',false);
         meanFixations = cell2mat(meanFixations);
         meanFixations = [meanFixations; meanFixations(1,:)];
         meanFixDirVectors = diff(meanFixations);
         
         cueVectors = [pos; pos(1,:)];
         cueVectors = diff(cueVectors);
         disp('Finished finding avg location');
         
         % Calculate scaling and rotation
         scaling = zeros(size(meanFixDirVectors,1),1);
         theta   = zeros(size(scaling));
         
         x = sym('x');
         for ii = 1:length(scaling)
            
            % Find average scaling
            scaling(ii) = norm(cueVectors(ii,:)) / norm(meanFixDirVectors(ii,:));
            
            % Find average rotation
            normFixDirVector = meanFixDirVectors(ii,:) / norm(meanFixDirVectors(ii,:));
            normCueVector = cueVectors(ii,:) / norm(cueVectors(ii,:));
            rot = solve(normCueVector(1) == cos(x) * normFixDirVector(1) - sin(x) * normFixDirVector(2),x);
            theta(ii) = real(double(rot(end)));
         end
         
         theta = mean(theta);
         self.scale = mean(scaling);
         self.rotation = [cos(theta) -sin(theta); sin(theta) cos(theta)];
         disp('Finished finding rotation matrix');
         
         % Calculate average translation
         translations = zeros(size(scaling,1),2);
         % figure; hold on;
         %             transFix = zeros(size(translations));
         for ii = 1:length(translations)
            srFixation = self.rotation * (self.scale * meanFixations(ii,:))';
            translations(ii,:) = pos(ii,:) - srFixation';
            %     plot(srFixation(1),srFixation(2),'o');
            %                 transFix(ii,:) = srFixation';
         end
         self.translation = mean(translations);
         disp('Finished pupilLabs calibration');
         
         %             p = transFix + repmat(self.translation,4,1);
         %             plot(p(:,1),p(:,2));
         pause(1);
      end
      
      % calibratePupilLab
      %
      %  Run pupil labs internal calibration routines with respect
      %     to world camera
      function calibratePupilLab(self)
         
         % Pointer ubscribe to calibration notification channel. This will give
         % us information about the calibration routine as it progresses
         % in the PupilLabs software. We will use this to determine when
         % to transition to the next calibration target.
         calNotify = zmq.core.socket(self.zmqContext,'ZMQ_SUB');
         zmq.core.connect(calNotify,self.pupilLabSubAddress);
         zmq.core.setsockopt(calNotify,'ZMQ_SUBSCRIBE','notify.calibration.');
         
         % Send calibration command to tell PupilLabs to start the
         % calibration process.
         zmq.core.send(self.req,uint8('C'));
         % char(zmq.core.recv(self.req));
         
         % make ensemble
         calibrationEnsemble = dotsEnsembleUtilities.makeEnsemble( ...
            'calibrationEnsemble', self.remoteInfo{:});
         
         % Create a white background. This is necessary because the
         % PupilLab software recognizes calibration markers on a white
         % background. Having it on a black background will tell it to
         % stop calibrating.
         tx = dotsDrawableTextures();
         tx.textureMakerFevalable = {@dotsReadableEyePupilLabs.makeBackground};
         tx.width = self.windowRect(3);
         tx.height = self.windowRect(4);
         tx.isSmooth = false;
         calibrationEnsemble.addObject(tx);
         
         % Generate calibration target location and sizes
         xDist = self.calibDeltaX;
         yDist = self.calibDeltaY;
         targetPositions = [0 0; -xDist yDist; xDist yDist; xDist -yDist;...
            -xDist -yDist; xDist 0; -xDist 0; 0 yDist; 0 -yDist];
         sizes = 3:-1:1;
         sizes = sizes * self.calibSize;
         
         % Create the target. We only need to create the dotsDrawables
         % once, put it into the ensemble, and then change the x/y
         % position properties through the functions available in the
         % ensemble class.
         for ii = 1:length(sizes)
            t = dotsDrawableTargets();
            t.colors = mod(ii+1,2) * ones(1,3);
            t.height = sizes(ii);
            t.width = sizes(ii);
            t.isSmooth = false;
            
            calibrationEnsemble.addObject(t);
         end
         calibrationEnsemble.automateObjectMethod( ...
            'draw', @dotsDrawable.drawFrame, {}, [], true);
         
         % We present the calibration markers in a loop. The loop only
         % progresses when the PupilLab software sends out a message
         % saying that the current marker has been completely sampled.
         % Then, we change the position of the marker and present it
         % again.
         for jj = 1:size(targetPositions,1)
            
            % Update position
            calibrationEnsemble.setObjectProperty('xCenter',targetPositions(jj,1),[2 3 4]);
            calibrationEnsemble.setObjectProperty('yCenter',targetPositions(jj,2),[2 3 4]);
            
            % Present calibration target and check for PupilLab message
            calibrationEnsemble.callObjectMethod(@prepareToDrawInWindow);
            calibrationEnsemble.start();
            calibrationNotDone = true;
            while calibrationNotDone
               calibrationEnsemble.runBriefly();
               msg = char(zmq.core.recv(calNotify,500));
               if strfind(msg,'marker_sample_completed')
                  calibrationNotDone = false;
               end
               msg = char(zmq.core.recv(calNotify,500)); %#ok<NASGU>
            end
            calibrationEnsemble.finish();
            
            pause(0.25);
         end
         
         % Create a stop calibration target which is identical to the
         % calibration marker but with a flipped color scheme.
         calibrationEnsemble.removeObject([1 2 3 4]);
         for ii = 1:length(sizes)
            t = dotsDrawableTargets();
            t.colors = mod(ii,2) * ones(1,3);
            t.height = sizes(ii);
            t.width = sizes(ii);
            t.isSmooth = false;
            t.xCenter = 0;
            t.yCenter = 0;
            
            calibrationEnsemble.addObject(t);
         end
         
         % Display the stop calibration marker.
         calibrationEnsemble.automateObjectMethod( ...
            'draw', @dotsDrawable.drawFrame, {}, [], true);
         
         calibrationEnsemble.callObjectMethod(@prepareToDrawInWindow);
         
         warning('off','zmq:core:recv:bufferTooSmall');
         calibrationEnsemble.start();
         calibrationNotDone = true;
         while calibrationNotDone
            calibrationEnsemble.runBriefly();
            msg = char(zmq.core.recv(calNotify,500));
            if strfind(msg,'stopped')
               calibrationNotDone = false;
            end
         end
         calibrationEnsemble.finish();
         warning('on','zmq:core:recv:bufferTooSmall');
         
      end
      
      % calibrate
      %  Wrapper function to call both
      %     calibratePupilLab and calibrateSnowDots
      function calibrate(self)
         self.calibratePupilLab();
         self.calibrateSnowDots();
      end
   end
   
   %% Protected methods
   methods (Access = protected)
      
      function isOpen = openDevice(self)
         % openDevice
         %
         % This function connects this instance to the PupilLabs software.
         % Therefore, you must ensure that the software is up and running
         % for this function to work properly.
         
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
         self.req = zmq.core.socket(self.zmqContext,'ZMQ_REQ');
         
         % Set timeouts to avoid blocking if there are commumication issues
         zmq.core.setsockopt(self.req,'ZMQ_SNDTIMEO',self.timeout);
         zmq.core.setsockopt(self.req,'ZMQ_RCVTIMEO',self.timeout);
         
         % Open the communication channel
         isOpen = ~zmq.core.connect(self.req,['tcp://' self.pupilLabIP ':' self.pupilLabPort]);
         
         % Only continue if we have successfully opened a REQ connection
         if isOpen
            
            % Measure round-trip time
            now = mglGetSecs;
            zmq.core.send(self.req, uint8('t'));
            self.result = zmq.core.recv(self.req);
            self.roundTripTime = mglGetSecs - now;
            
            % possibly start recording
            if self.autoRecord
               zmq.core.send(self.req, uint8('R'));
               self.result = zmq.core.recv(self.req);
            end
            
            % Query the ZMQ_REQ port for the value of the ZMQ_SUB port.
            zmq.core.send(self.req,uint8('SUB_PORT'));
            subPort = char(zmq.core.recv(self.req));
            self.pupilLabSubAddress = ['tcp://' self.pupilLabIP ':' subPort];
            
            % Request a ZMQ_SUB port
            self.gaze = zmq.core.socket(self.zmqContext,'ZMQ_SUB');
            
            % Set timeouts to avoid blocking if there are commumication issues
            zmq.core.setsockopt(self.gaze,'ZMQ_SNDTIMEO',self.timeout);
            zmq.core.setsockopt(self.gaze,'ZMQ_RCVTIMEO',self.timeout);
            
            % Connect to the sub socket
            isOpen = ~zmq.core.connect(self.gaze,self.pupilLabSubAddress);
            
            % Subscribe to the gaze channel
            zmq.core.setsockopt(self.gaze,'ZMQ_SUBSCRIBE','gaze');
         end
      end
      
      function closeDevice(self)
         
         if ~isempty(self.req)
            
            % possibly turn off recording
            if self.autoRecord
               zmq.core.send(self.req, uint8('r'));
               self.result = zmq.core.recv(self.req);
            end
            
            % Disconnect and close the sockets
            zmq.core.disconnect(self.req, ['tcp://' self.pupilLabIP ':' self.pupilLabPort]);
            zmq.core.close(self.req);
            zmq.core.disconnect(self.gaze, self.pupilLabSubAddress);
            zmq.core.close(self.gaze);
            
            % Close the context
            zmq.core.ctx_shutdown(self.zmqContext);
            zmq.core.ctx_term(self.zmqContext);
         end
      end
      
      % Overrides method from dotsReadableEye
      function components = openComponents(self)
         
         % Define data component names
         names = { ...
            'gaze x', 'gaze y', 'gaze confidence'...
            'pupil0 x', 'pupil0 y', 'pupil0 size', 'pupil0 confidence'...
            'pupil1 x', 'pupil1 y', 'pupil1 size', 'pupil1 confidence'};
         
         % Check whether getting all data or just gaze
         if self.getRawEyeData

            % Make all the components
            components = struct('ID', num2cell(1:size(names,1)), 'name', names);

            % Save raw eye IDs
            self.pXIDs = [find(strcmp('pupil0 x', names)) find(strcmp('pupil1 x', names))];
            self.pYIDs = [find(strcmp('pupil0 y', names)) find(strcmp('pupil1 y', names))];
            self.pDIDs = [find(strcmp('pupil0 size', names)) find(strcmp('pupil1 size', names))];
            self.pCIDs = [find(strcmp('pupil0 confidence', names)) find(strcmp('pupil1 confidence', names))];            
         else
            
            % Just make the gaze components
            components = struct('ID', num2cell(1:3), 'name', names);            
         end
                  
         % Alwats save gaze IDs
         self.gXID = find(strcmp('gaze x', names));
         self.gYID = find(strcmp('gaze y', names));
         self.gCID = find(strcmp('gaze confidence', names));                  
      end
      
      function newData = readRawEyeData(self)
         % readRawEyeData
         %
         % Get data from PupilLabs. The format of this data is a struct
         % and details can be found here:
         %
         %   https://docs.pupil-labs.com/#pupil-datum-format
         %
         % We convert it to the dotsReadable format depending on what
         % value the dataTypeSelector flag is set to.
         
         % The first message tells us what type of data it is. The
         % second msg will actually give us the data.
         msg = zmq.core.recv(self.gaze); %#ok<NASGU>
         msg = zmq.core.recv(self.gaze,1500);
         
         % Here, we use a python package to format the raw data. It
         % gives us a python dict object which we must then convert into
         % a Matlab struct.
         data = py.msgpack.loads(msg,pyargs('encoding','utf-8'));
         dataStruct = struct(data);
         
         % Format data according to the dotsReadable format.
         dataLen = length(self.components);
         newData = cat(2, repmat(self.blankID, dataLen, 1), nans(dataLen,2));
         
         % Here we extract the gaze data. These will be in PupilLab
         % normalized coordinates and need to be transformed into screen
         % space.
         
         % Collect the data from the parsed struct
         gazePos = cell2num(cell(dataStruct.norm_pos));
         time = dataStruct.timestamp;
         confidence = dataStruct.confidence;
         
         % Set the data
         newData(self.gXID,:) = [self.gXID gazePos(1) time];
         newData(self.gYID,:) = [self.gYID gazePos(2) time];
         newData(self.gCID,:) = [self.gCID confidence time];
         
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
               
               newData(self.pXIDs(id+1),:) = [self.pXIDs(id+1) pupilPos(1) time];
               newData(self.pYIDs(id+1),:) = [self.pYIDs(id+1) pupilPos(2) time];
               newData(self.pDIDs(id+1),:) = [self.pDIDs(id+1) pupilSize time];
               newData(self.pCIDs(id+1),:) = [self.pCIDs(id+1) confidence time];
            end
         end
      end
      
      % Transform the normalized x/y eye data into screen coordinates
      %  with units of degrees visual angle
      function newData = transformRawData(self, newData)
         
         % Transform gaze x,y
         gazeData = newData([self.gXID, self.gYID], 2);
         gazeData = self.translation' + self.rotation * self.scale * gazeData;
         newData([self.gXID, self.gYID], 2) = gazeData;
            
         % check for all data
         if self.getRawEyeData
            
            % Transform pupil0 x,y
            p0Data = newData([self.pXIDs(1), self.pYIDs(1)], 2);
            p0Data = self.translation' + self.rotation * self.scale * p0Data;
            newData([self.pXID(1), self.pYID(1)], 2) = p0Data;
            
            % Transform pupil1 x,y
            p1Data = newData([self.pXID(2), self.pYID(2)], 2);
            p1Data = self.translation' + self.rotation * self.scale * p1Data;
            newData([self.pXID(2), self.pYID(2)], 2) = p1Data;
         end
      end
      
      function setupCoordinateRectTransform(self)
         % Have this function do nothing.
      end
   end
   
   %% Static methods
   methods (Static)
      function textureInfo = makeBackground(textureObject) %#ok<INUSD>
         
         % This is here so that the calibration will work on remote
         % systems. By defining this as a static function, it prevents
         % the need of having a separate file on the server machine (and
         % reduces the chance of software failure).
         image = [1 1 1 1] * 255;
         textureInfo = mglCreateTexture(image);
      end
   end
end

