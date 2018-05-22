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
        
        % Communiation timeout, in ms
        timeout = 5000;
        
        % Name of pupilLabs datafile
        sessionName = [];
        
        % Need to keep refreshing the socket to make sure the data arrives
        %  This is the time, in sec, defining the refresh interval. It is
        %  checked automatically during readRawData
        socketRefreshInterval = 1;
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
        
        % Monitor round-trip time
        roundTripTime = nan;
        
        % Latest received message
        result;
        
        % Are we currently recording?
        isRecording = false;
        
        % Keep track of socket refresh
        lastSocketRefresh = [];
    end
    
    properties (Access = private)
        
        % Variables for controlling the connection between Matlab and
        % PupilLabs.
        pupilLabSubAddress;
        zmqContext;
        reqPort = [];
        gazePort = [];
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
            zmq.core.close(self.gazePort);
            self.gazePort = zmq.core.socket(self.zmqContext,'ZMQ_SUB');
            zmq.core.connect(self.gazePort,self.pupilLabSubAddress);
            zmq.core.setsockopt(self.gazePort,'ZMQ_SUBSCRIBE','gaze');
            
            % Keep track of when this happens
            self.lastSocketRefresh = mglGetSecs;
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
        
        % Overloaded toggleDataFile routing
        % toggleFlag = true for open, false for close
        function toggleDataFile(self, toggleFlag)
            
            if nargin < 1 || isempty(toggleFlag)
                toggleFlag = true;
            end
            
            if toggleFlag && ~self.isRecording
                
                % Check for filename
                if isempty(self.sessionName)
                    str = 'R';
                else
                    str = sprintf('R %s', self.sessionName);
                end
                
                % Turn on recording
                zmq.core.send(self.reqPort, uint8(str));
                self.result = zmq.core.recv(self.reqPort);
                self.isRecording = true;
                
            elseif ~toggleFlag && self.isRecording
                
                % Turn off recording
                zmq.core.send(self.reqPort, uint8('r'));
                self.result = zmq.core.recv(self.reqPort);
                self.isRecording = false;
            end
        end
        
        % calibratePupilLab
        %
        %  Run pupil labs internal calibration routines with respect
        %     to world camera
        function calibratePupilLab(self)
            
            % Pointer subscribe to calibration notification channel. This will give
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
            
            % Make and start a drawing ensemble that automates drawing
            calibrationEnsemble = dotsEnsembleUtilities.makeEnsemble( ...
                'calibrationEnsemble', self.ensembleRemoteInfo{:});
            calibrationEnsemble.automateObjectMethod( ...
                'draw', @dotsDrawable.drawFrame, {}, [], true);
            calibrationEnsemble.start();
            
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
            
            % We present the calibration markers in a loop. The loop only
            % progresses when the PupilLab software sends out a message
            % saying that the current marker has been completely sampled.
            % Then, we change the position of the marker and present it
            % again.
            for jj = 1:size(targetPositions,1)
                
                % Present calibration target at the updated position
                calibrationEnsemble.setObjectProperty('xCenter',targetPositions(jj,1), inds);
                calibrationEnsemble.setObjectProperty('yCenter',targetPositions(jj,2), inds);
                calibrationEnsemble.runBriefly();
                
                % Wait for PupilLab calibration sample done message
                msg = [];
                while isempty(strfind(msg, 'marker_sample_completed')) || ...
                        isempty(strfind(msg, 'timestamp'))
                    msg = char(zmq.core.recv(calNotify,500));
                    % disp(sprintf('msg is <%s>', msg))
                end
                
                % wait a bit between targets
                pause(0.5);
            end
            
            % Create a stop calibration target that is identical to the
            % calibration marker but with a flipped color scheme.
            calibrationEnsemble.setObjectProperty('isVisible', false, 1);
            calibrationEnsemble.setObjectProperty('xCenter', 0, inds);
            calibrationEnsemble.setObjectProperty('yCenter', 0, inds);
            for ii = 1:length(sizes)
                calibrationEnsemble.setObjectProperty( ...
                    'colors', mod(ii,2) * ones(1,3), inds(ii));
            end
            
            % Show it
            calibrationEnsemble.runBriefly();
            
            % Wait for 'stopped' message from PupilLab
            warning('off','zmq:core:recv:bufferTooSmall');
            msg = [];
            while isempty(strfind(msg, 'stopped'))
                msg = char(zmq.core.recv(calNotify,500));
            end
            
            % Clean up
            calibrationEnsemble.finish();
            warning('on','zmq:core:recv:bufferTooSmall');
        end
        
        %  Wrapper function to call both
        %     calibratePupilLab and calibrateSnowDots
        function calibrate(self)
            self.calibratePupilLab();
            self.calibrateEyeSnowDots();
        end
        
        % Convenient set-up routine
        function setupPupilLabs(self, windowRect, turnOnRecording)
            
            % Set window Rect
            if nargin >= 2 && ~isempty(windowRect)
                self.windowRect = windowRect;
            end
            
            % Check second arg
            if nargin < 3 || isempty(turnOnRecording)
                turnOnRecording = true;
            end
            
            % Turn off recording while calibrating
            if self.isRecording
                self.toggleDataFile(false);
                turnOnRecording = true;
            end
            
            % Calibrate
            self.calibrate();
            
            % Set current device time to zero
            self.setDeviceTime();
            
            % Possibly start recording
            if turnOnRecording
                self.toggleDataFile(true)
            end
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
            self.reqPort = zmq.core.socket(self.zmqContext,'ZMQ_REQ');
            
            % Set timeouts to avoid blocking if there are commumication issues
            zmq.core.setsockopt(self.reqPort,'ZMQ_SNDTIMEO',self.timeout);
            %zmq.core.setsockopt(self.reqPort,'ZMQ_RCVTIMEO',self.timeout);
            
            % Open the communication channel
            isOpen = ~zmq.core.connect(self.reqPort,['tcp://' self.pupilLabIP ':' self.pupilLabPort]);
            
            % Only continue if we have successfully opened a REQ connection
            if isOpen
                
                % Measure round-trip time
                now = mglGetSecs;
                zmq.core.send(self.reqPort, uint8('t'));
                self.result = zmq.core.recv(self.reqPort);
                self.roundTripTime = mglGetSecs - now;
                
                % Query the ZMQ_REQ port for the value of the ZMQ_SUB port.
                zmq.core.send(self.reqPort,uint8('SUB_PORT'));
                self.result = zmq.core.recv(self.reqPort);
                self.pupilLabSubAddress = ...
                    ['tcp://' self.pupilLabIP ':' char(self.result)];
                
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
        
        function closeDevice(self)
            
            if ~isempty(self.reqPort)
                
                % possibly turn off recording
                if self.isRecording
                    zmq.core.send(self.reqPort, uint8('r'));
                    self.result = zmq.core.recv(self.reqPort);
                end
                
                % Disconnect and close the sockets
                zmq.core.disconnect(self.reqPort, ['tcp://' self.pupilLabIP ':' self.pupilLabPort]);
                zmq.core.close(self.reqPort);
                zmq.core.disconnect(self.gazePort, self.pupilLabSubAddress);
                zmq.core.close(self.gazePort);
                
                % Close the context
                % zmq.core.ctx_shutdown(self.zmqContext);
                % zmq.core.ctx_term(self.zmqContext);
            end
        end
        
        % Overrides method from dotsReadableEye
        function components = openComponents(self)
            
            % Define data component names
            names = { ...
                'gaze x', 'gaze y', 'gaze confidence'...
                'pupil0 x', 'pupil0 y', 'pupil0 size', 'pupil0 confidence'...
                'pupil1 x', 'pupil1 y', 'pupil1 size', 'pupil1 confidence'}';
            
            % Check whether getting all data or just gaze
            if self.getRawEyeData
                
                % Make all the components
                components = struct('ID', num2cell((1:size(names,2))'), 'name', names);
                
                % Save raw eye IDs
                self.pXIDs = [find(strcmp('pupil0 x', names)) find(strcmp('pupil1 x', names))];
                self.pYIDs = [find(strcmp('pupil0 y', names)) find(strcmp('pupil1 y', names))];
                self.pDIDs = [find(strcmp('pupil0 size', names)) find(strcmp('pupil1 size', names))];
                self.pCIDs = [find(strcmp('pupil0 confidence', names)) find(strcmp('pupil1 confidence', names))];
            else
                
                % Just make the gaze components
                components = struct('ID', num2cell((1:3)'), 'name', names(1:3));
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
            
            % Possibly refresh the socket
            if ~isempty(self.socketRefreshInterval)
                if isempty(self.lastSocketRefresh) || ...
                        ((mglGetSecs - self.lastSocketRefresh) > ...
                        self.socketRefreshInterval)
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
            dataLen = length(self.components)-length(self.gazeEvents);
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

