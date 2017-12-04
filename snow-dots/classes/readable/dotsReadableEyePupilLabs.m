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
    % 11/17/17   xd  wrote it
    
    properties
        % IP address of PupilLab Remote plugin (string)
        pupilLabIP = '127.0.0.1';
        
        % Port for PupilLab Remote plugin (string)
        pupilLabPort = '50020';
        
        % What type of data to record. gaze (1), pupil (2), all data(3)
        dataType = 1;
        
        % How far on the X axis the calibration markers should be placed
        calibDeltaX = 10;
        
        % How far on the Y axis the calibration markers should be placed
        calibDeltaY = 6;
        
        % Size of calibration marker (arbitrary units)
        calibSize = 1;
    end
    
    properties (SetAccess = protected)
        % Indices for the various data components. g is for gaze while p is
        % for pupil. For the pupil indices, the first one corresponds to
        % pupil0 in PupilLab and the second one corresponds to pupil1.
        gXID = 1;
        gYID = 2;
        
        pXID = [3 6];
        pYID = [4 7];
        pDID = [5 8];
        
        blankID = 9;
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
    
    methods
        function self = dotsReadableEyePupilLabs()
            self = self@dotsReadableEye();
            self.initialize();
            
            % This will initialize the python module in Matlab, which we
            % will need in order to read the data from PupilLabs which is
            % serialized in msg-pack format, and unfortunately there does
            % not exist a working Matlab library for this format.
            py.abs(0);
        end
        
        function refreshSocket(self)
            % refreshSocket
            %
            % This refreshes the connection between the mPupilLabs object
            % and the PupilLabs ZMQ network. Doing so flushes the queue of
            % data streamed from PupilLabs so you will get the latest data
            % instead of the oldest.
            
            zmq.core.close(self.gaze);
            self.gaze = zmq.core.socket(self.zmqContext,'ZMQ_SUB');
            zmq.core.connect(self.gaze,self.pupilLabSubAddress);
            zmq.core.setsockopt(self.gaze,'ZMQ_SUBSCRIBE','gaze');
        end
        
        function timeSync(self, val)
            % timeSync
            %
            % Makes the PupilLab timer start counting from val. Must be a
            % numeric value. If val is not provided or is not numeric, this
            % function defaults to a value of 0.0.
            
            if nargin < 2
                val = 0.0;
            end
            
            if ~isnumeric(val)
                val = 0.0;
            end
            
            % Convert val to a string and send it over the ZMQ network. We
            % receive a message from the network because Pupil Remote
            % provides a response signal.
            val = sprintf('%0.2f',val);
            zmq.core.send(self.req,uint8(['T ' val]));
            char(zmq.core.recv(self.req));
        end
        
        function t = getTime(self)
            % getTime
            %
            % Get the current time value on the PupilLabs software and
            % returns it as a numeric value. Units are in seconds.
            zmq.core.send(self.req,uint8('t'));
            t = str2double(char(zmq.core.recv(self.req)));
        end
        
        function data = readAndReturnData(self)
            data = self.readNewData();
        end
        
        function calibrateSnowDots(self, varargin)
            % Parse inputs to check if in remote mode
            p = inputParser;
            p.addOptional('clientIP','',@isstr);
            p.addOptional('clientPort',0,@isnumeric);
            p.addOptional('serverIP','',@isstr);
            p.addOptional('serverPort',0,@isnumeric);
            p.parse(varargin{:});
            
            if isempty(p.Results.clientIP)
                calibEnsemble = topsEnsemble();
            else
                calibEnsemble = dotsClientEnsemble('Calib',p.Results.clientIP,...
                    p.Results.clientPort,p.Results.serverIP,p.Results.serverPort);
            end
            
            % Generate Fixation spots
            %
            % We will create a single drawable object to represent the fixation cue.
            % Then, we simply adjust the location of the cue each time we present it.
            fixationCue = dotsDrawableTargets();
            calibEnsemble.addObject(fixationCue);
            calibEnsemble.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);
                
            xdist = 10;
            ydist = 5;
            pos = [-xdist ydist; xdist ydist; xdist -ydist; -xdist -ydist];
            
            % Present cues
            n = 500;
            fixationData = cell(size(pos,1),1);
            for ii = 1:length(fixationData)
                data = zeros(n,2);

                calibEnsemble.setObjectProperty('width',[0 0]);
                calibEnsemble.setObjectProperty('height',[0 0]);
                calibEnsemble.callObjectMethod(@prepareToDrawInWindow);
                calibEnsemble.run(1);
                
                calibEnsemble.setObjectProperty('xCenter',[pos(ii,1) pos(ii,1)]);
                calibEnsemble.setObjectProperty('yCenter',[pos(ii,2) pos(ii,2)]);
                calibEnsemble.setObjectProperty('width',[1 0.1] * 3);
                calibEnsemble.setObjectProperty('height',[0.1 1] * 3);
                
                calibEnsemble.callObjectMethod(@prepareToDrawInWindow);
                calibEnsemble.run(1);
                
                self.refreshSocket();
                for jj = 1:n
                    dataMatrix = self.readRawEyeData();
                    data(jj,:) = dataMatrix([self.gXID, self.gYID],2)';
                end
                
                fprintf('Finished collecting data for cue %d\n',ii);
                fixationData{ii} = data;
            end
            
            calibEnsemble.setObjectProperty('width',[0 0]);
            calibEnsemble.setObjectProperty('height',[0 0]);
            calibEnsemble.callObjectMethod(@prepareToDrawInWindow);
            calibEnsemble.run(1);
            
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
        
        function calibratePupilLab(self, screen, varargin)
            
            % Subscribe to calibration notification channel. This will give
            % us information about the calibration routine as it progresses
            % in the PupilLabs software. We will use this to determine when
            % to transition to the next calibration target.
            calNotify = zmq.core.socket(self.zmqContext,'ZMQ_SUB');
            zmq.core.connect(calNotify,self.pupilLabSubAddress);
            zmq.core.setsockopt(calNotify,'ZMQ_SUBSCRIBE','notify.calibration.');
            
            % Send calibration command to tell PupilLabs to start the
            % calibration process.
            zmq.core.send(self.req,uint8('C'));
            char(zmq.core.recv(self.req));
            
            % Parse input parameters. This tells us whether the calibration
            % is being run locally or over a network.
            p = inputParser;
            p.addOptional('clientIP','',@isstr);
            p.addOptional('clientPort',0,@isnumeric);
            p.addOptional('serverIP','',@isstr);
            p.addOptional('serverPort',0,@isnumeric);
            
            p.parse(varargin{:});
            if isempty(p.Results.clientIP)
                calibEnsemble = topsEnsemble();
            else
                calibEnsemble = dotsClientEnsemble('Calib',p.Results.clientIP,...
                    p.Results.clientPort,p.Results.serverIP,p.Results.serverPort);
            end
            
            % Create a white background. This is necessary because the
            % PupilLab software recognizes calibration markers on a white
            % background. Having it on a black background will tell it to
            % stop calibrating.
            tx = dotsDrawableTextures();
            tx.textureMakerFevalable = {@dotsReadableEyePupilLabs.makeBackground};
            tx.width = screen.windowRect(3);
            tx.height = screen.windowRect(4);
            tx.isSmooth = false;
            calibEnsemble.addObject(tx);
            
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
                
                calibEnsemble.addObject(t);
            end
            calibEnsemble.automateObjectMethod( ...
                'draw', @dotsDrawable.drawFrame, {}, [], true);
            
            % We present the calibration markers in a loop. The loop only
            % progresses when the PupilLab software sends out a message
            % saying that the current marker has been completely sampled.
            % Then, we change the position of the marker and present it
            % again.
            for jj = 1:size(targetPositions,1)
                
                % Update position
                calibEnsemble.setObjectProperty('xCenter',targetPositions(jj,1),[2 3 4]);
                calibEnsemble.setObjectProperty('yCenter',targetPositions(jj,2),[2 3 4]);
                
                % Present calibration target and check for PupilLab message
                calibEnsemble.callObjectMethod(@prepareToDrawInWindow);
                calibEnsemble.start();
                calibrationNotDone = true;
                while calibrationNotDone
                    calibEnsemble.runBriefly();
                    msg = char(zmq.core.recv(calNotify,500));
                    if strfind(msg,'marker_sample_completed')
                        calibrationNotDone = false;
                    end
                    msg = char(zmq.core.recv(calNotify,500)); %#ok<NASGU>
                end
                calibEnsemble.finish();
                
                pause(0.25);
            end
            
            % Create a stop calibration target which is identical to the
            % calibration marker but with a flipped color scheme.
            calibEnsemble.removeObject([1 2 3 4]);
            for ii = 1:length(sizes)
                t = dotsDrawableTargets();
                t.colors = mod(ii,2) * ones(1,3);
                t.height = sizes(ii);
                t.width = sizes(ii);
                t.isSmooth = false;
                t.xCenter = 0;
                t.yCenter = 0;
                
                calibEnsemble.addObject(t);
            end
            
            % Display the stop calibration marker.
            calibEnsemble.automateObjectMethod( ...
                'draw', @dotsDrawable.drawFrame, {}, [], true);
            
            calibEnsemble.callObjectMethod(@prepareToDrawInWindow);
            
            warning('off','zmq:core:recv:bufferTooSmall');
            calibEnsemble.start();
            calibrationNotDone = true;
            while calibrationNotDone
                calibEnsemble.runBriefly();
                msg = char(zmq.core.recv(calNotify,500));
                if strfind(msg,'stopped')
                    calibrationNotDone = false;
                end
            end
            calibEnsemble.finish();
            warning('on','zmq:core:recv:bufferTooSmall');
            
        end
    end
    
    methods (Access = protected)  
        function isOpen = openDevice(self)
            % openDevice
            %
            % This function connects this instance to the PupilLabs software.
            % Therefore, you must ensure that the software is up and running
            % for this function to work properly.
            
            % Set up a ZMQ context which will be used for managing all our
            % communications with PupilLabs
            self.zmqContext = zmq.core.ctx_new();
            
            % Create a socket to connect to the PupilLabs REQ port which
            % will allow us to send commands to the software in addition to
            % getting what the SUB port is.
            self.req = zmq.core.socket(self.zmqContext,'ZMQ_REQ');
            zmq.core.setsockopt(self.req,'ZMQ_SNDTIMEO',5000);
            isOpen = ~zmq.core.connect(self.req,['tcp://' self.pupilLabIP ':' self.pupilLabPort]);
            
            % Only continue if we have successfully opened a REQ connection
            if isOpen
                % Query the ZMQ_REQ port for the value of the ZMQ_SUB port.
                zmq.core.send(self.req,uint8('SUB_PORT'));
                subPort = zmq.core.recv(self.req);
                subPort = char(subPort);
                self.pupilLabSubAddress = ['tcp://' self.pupilLabIP ':' subPort];
                
                % Open a ZMQ_SUB port and subscribe to the gaze channel
                self.gaze = zmq.core.socket(self.zmqContext,'ZMQ_SUB');
                isOpen = ~zmq.core.connect(self.gaze,self.pupilLabSubAddress);
                zmq.core.setsockopt(self.gaze,'ZMQ_SUBSCRIBE','gaze');
            end
        end
        
        function closeDevice(self)
            
            if ~isempty(self.req)
                % Close the sockets
                zmq.core.close(self.req);
                zmq.core.close(self.gaze);
                
                % Close the context
                zmq.core.ctx_shutdown(self.zmqContext);
            end
        end
        
        function components = openComponents(self)
            self.gXID = 1;
            self.gYID = 2;
            self.pXID = [3 6];
            self.pYID = [4 7];
            self.pDID = [5 8];
            self.blankID = 9;
            IDs = {self.gXID, self.gYID, self.pXID(1), self.pYID(1),...
                self.pDID(1), self.pXID(2), self.pYID(2), self.pDID(2), self.blankID};
            
            names = {'gaze x', 'gaze y', 'pupil0 x', 'pupil0 y', 'pupil0 size',...
                'pupil1 x', 'pupil1 y', 'pupil1 size', 'blank'};
            components = struct('ID', IDs, 'name', names);
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
            % value the dataType flag is set to.
            
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
            newData = zeros(8,3);
            
            % Here we extract the gaze data. These will be in PupilLab
            % normalized coordinates and need to be transformed into screen
            % space.
            if self.dataType == 1 || self.dataType == 3
                gazePos = cell2num(cell(dataStruct.norm_pos));
                time = dataStruct.timestamp;
                
                newData(1,:) = [self.gXID gazePos(1) time];
                newData(2,:) = [self.gYID gazePos(2) time];
                
                if self.dataType == 1
                    newData(3:end,1) = self.blankID;
                end
            end
            
            % Conveniently, the gaze data struct contains the pupil data
            % used to determine the gaze. Thus, we can directly extract the
            % data from there if needed.
            if self.dataType == 2 || self.dataType == 3
                for ii = 1:length(dataStruct.base_data)
                    pupilDataStruct = struct(dataStruct.base_data{ii});
                    
                    pupilPos = cell2num(cell(pupilDataStruct.norm_pos));
                    pupilSize = pupilDataStruct.diameter;
                    time = pupilDataStruct.timestamp;
                    id = int64(pupilDataStruct.id);
                    
                    newData(3 + (ii-1)*3,:) = [self.pXID(id+1) pupilPos(1) time];
                    newData(4 + (ii-1)*3,:) = [self.pYID(id+1) pupilPos(2) time];
                    newData(5 + (ii-1)*3,:) = [self.pDID(id+1) pupilSize time];
                end
                
                if self.dataType == 2
                    newData(1:2,1) = self.blankID;
                end
            end
        end
        
        function newData = transformRawData(self, newData)
            % Transform gaze
            gazeData = newData([self.gXID, self.gYID],2);
            gazeData = self.translation' + self.rotation * self.scale * gazeData;
            newData([self.gXID, self.gYID],2) = gazeData;
            
            % Transform pupil0
            p0Data = newData([self.pXID(1), self.pYID(1)],2);
            p0Data = self.translation' + self.rotation * self.scale * p0Data;
            newData([self.pXID(1), self.pYID(1)],2) = p0Data;
            
            % Transform pupil1
            p1Data = newData([self.pXID(2), self.pYID(2)],2);
            p1Data = self.translation' + self.rotation * self.scale * p1Data;
            newData([self.pXID(2), self.pYID(2)],2) = p1Data;
        end
        
        function setupCoordinateRectTransform(self)
            % Have this function do nothing.
        end
    end
    
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

