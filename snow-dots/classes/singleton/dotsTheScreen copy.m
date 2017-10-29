classdef dotsTheScreen < dotsAllSingletonObjects
    % @class dotsTheScreen
    % Singleton to work with the OpenGL drawing context.
    % @details
    % dotsTheScreen manages the Snow Dots OpenGL drawing context. "Context"
    % includes the display and window to use for drawing, OpenGL system
    % resources, OpenGL configuration, and state memory, all of which Snow
    % Dots needs in order to draw graphics with OpenGL.
    % @details
    % dotsTheMachineConfiguration provides hardware-specific default
    % property values to dotsTheScreen.
    properties
        % dispay width (cm)
        width;
        
        % dispay height (cm)
        height;
        
        % display viewing distance (cm)
        distance;
        
        % index of display on which to open drawing windows
        % @details
        % A positive integer is a 1-based index for an attached display, on
        % which to open a full-screen window.  0 calls for a small window
        % centered on the primary display.
        displayIndex;
        
        % rectangle representing the entire display (pixels, [0 0 w h])
        displayPixels;
        
        % color depth of each pixel (number of bits)
        bitDepth;
        
        % whether or not to use OpenGL full-scene antialiasing
        multisample;
        
        % pixel dimensions of the current drawing window [x y x2 y2]
        windowRect;
        
        % Hz frame rate of the current drawing window
        windowFrameRate;
        
        % approximate conversion factor for the current display
        pixelsPerDegree;
        
        % a foreground color, [L] [LA] [RGB] [RGBA], 0-255
        foregroundColor;
        
        % a background color, [L] [LA] [RGB] [RGBA], 0-255
        backgroundColor;
        
        % function that returns the current time as a number
        clockFunction;
        
        % filename with path to .mat file that contains a gamma table
        gammaTableFile;
    end
    
    properties (SetAccess = protected)
        % utility object to account for OpenGL frame timing
        flushGauge;
        
        % onset data from the last frame
        lastFrameInfo;
        
        % color calibration that was in the video card at startup (nx3)
        systemGammaTable;
        
        % color calibration which is sitimulus-appropriate (nx3)
        stimulusGammaTable;
    end
    
    methods (Access = private)
        % Constructor is private.
        % @details
        % Use dotsTheScreen.theObject to access the current instance.
        function self = dotsTheScreen(varargin)
            mc = dotsTheMachineConfiguration.theObject();
            mc.applyClassDefaults(self);
            mc.applyClassDefaults(self, mc.defaultGroup);
            self.set(varargin{:});
            self.initialize;
        end
    end
    
    methods (Static)
        % Access the current instance.
        function obj = theObject(varargin)
            persistent self
            if isempty(self) || ~isvalid(self)
                constructor = str2func(mfilename);
                self = feval(constructor, varargin{:});
            else
                self.set(varargin{:});
            end
            obj = self;
        end
        
        % Restore the current instance to a fresh state.
        function reset(varargin)
            factory = str2func([mfilename, '.theObject']);
            self = feval(factory, varargin{:});
            self.initialize;
        end
        
        % Launch a graphical interface to view dotsTheScreen properties.
        function g = gui()
            self = dotsTheScreen.theObject();
            g = topsGUIUtilities.openBasicGUI(self, mfilename());
        end
        
        % Get a filename suitable for storing a machine-specific gamma
        % table.
        function hostFile = getHostGammaTableFilename()
            [stat,h] = unix('hostname -s');
            hostFile = sprintf('dots_%s_GammaTable.mat', deblank(h));
        end
        
        % Get the number of the display used for drawing.
        % @details
        % If Snow Dots has an open drawing window, returns a non-negative
        % integer which corresponds to displayIndex.  Otherwise, returns
        % -1.
        function displayNumber = getDisplayNumber()
            displayNumber = mglGetParam('displayNumber');
        end
        
        % Open an OpenGL drawing window.
        function openWindow()
            self = dotsTheScreen.theObject();
            self.open();
        end
        
        % Close the OpenGL drawing window.
        function closeWindow()
            self = dotsTheScreen.theObject();
            self.close();
        end
    end
    
    methods
        % Return the current instance to a fresh state, closing the window.
        function initialize(self)
            % may not start out with an open window
            self.close();
            self.lastFrameInfo = [];
            
            % pixels of the entire display
            displays = mglDescribeDisplays();
            whichElement = max(1, self.displayIndex);
            display = displays(whichElement);
            self.displayPixels = [0 0 display.screenSizePixel];
            
            % approximate visual coordinate conversion factor
            % note that the "actual" conversion occurs below in
            % open(), with mglVisualAngleCoordinates()
            self.pixelsPerDegree = self.displayPixels(3) ...
                / (2*(180/pi)*atan2(self.width/2, self.distance));
            
            % utility to manage frame timing
            self.flushGauge = dotsMglFlushGauge();
            self.flushGauge.clockFunction = self.clockFunction;
            
            % locate a gamma table to be loaded during open()
            hostFile = dotsTheScreen.getHostGammaTableFilename;
            if exist(self.gammaTableFile, 'file')
                % reload present gamma table
                self.gammaTableFromMatFile(self.gammaTableFile);
                
            elseif exist(hostFile, 'file')
                % reload host's default gamma table
                self.gammaTableFromMatFile(hostFile);
                
            else
                % no gamma table
                self.stimulusGammaTable = [];
                self.gammaTableFile = '';
            end
        end
        
        % Open an OpenGL drawing window.
        function open(self)
            if self.getDisplayNumber >= 0
                mglClose();
            end
            
            % choose full scene antialiasing or not
            %   when choosing a context pixel format
            %   this may fail silently
            mglSetParam('multisampling', double(self.multisample));
            
            % open window, may use default size and frame rate
            if isempty(self.windowRect)
                w = [];
                h = [];
            else
                w = self.windowRect(3) - self.windowRect(1);
                h = self.windowRect(4) - self.windowRect(2);
            end
            frameRate = [];
            mglOpen(self.displayIndex, w, h, frameRate, self.bitDepth);
            
            % choose full scene antialiasing again
            %   once the context has been created
            %   this may fail silently, also
            dotsMglSmoothness('scene', double(self.multisample));
            
            if isempty(self.windowRect)
                w = mglGetParam('screenWidth');
                h = mglGetParam('screenHeight');
                self.windowRect = [0 0 w h];
            end
            
            % configure OpenGL modelview matrix to do pixels-per-degree
            % transformation
            %   assume square pixels
            %   calculate pixels-per-degree from the screen center
            mglSetParam('visualAngleSquarePixels', 1);
            mglSetParam('visualAngleCalibProportion', .5);
            mglVisualAngleCoordinates( ...
                self.distance, [self.width self.height]);
            
            % hide the cursor and raise the command window
            mglDisplayCursor(0);
            commandwindow();
            
            % set the background color and clear front and back buffers
            mglClearScreen(self.backgroundColor);
            mglFlush();
            mglClearScreen(self.backgroundColor);
            mglFlush();
            
            % measure and report the refresh interval
            self.flushGauge.initialize();
            self.windowFrameRate = 1 ./ self.flushGauge.framePeriod;
            
            % expose the current gamma table in a familiar format
            systemTable = mglGetGammaTable();
            n = length(systemTable.redTable);
            self.systemGammaTable = zeros(3,n);
            self.systemGammaTable(1,:) = systemTable.redTable;
            self.systemGammaTable(2,:) = systemTable.greenTable;
            self.systemGammaTable(3,:) = systemTable.blueTable;
            
            if ~isempty(self.stimulusGammaTable)
                % load a stimulus-appropriate gamma table
                mglSetGammaTable(self.stimulusGammaTable');
            end
        end
        
        % Close the OpenGL drawing window.
        function close(self)
            mglDisplayCursor(1);
            mglClose();
        end
        
        % Flush OpenGL drawing commands and swap OpenGL frame buffers.
        % @param doClear whether or not clear the frame buffer after
        % displaying it
        % @details
        % Flushes any recent drawing commands throught OpenGL rendering
        % pipeline, then calls for a frame buffer swap.  This will cause
        % the recently drawn frame to appear on-screen.
        % @details
        % If @a doClear is true (default), sends a frame buffer clear
        % command immediately after the swap command.  This will cause new
        % future frames to start out as clear.  Use doClear = false to
        % let drawings accumulate or "pile up" frame after frame.
        % @details
        % Returns a struct with frame timing data obtained from
        % flushGauge.  The struct has fields:
        %   - @b onsetTime: estimated onset time for this frame, which
        %   might be a time in the future
        %   - @b onsetFrame: number of frames elapsed between open() and
        %   this frame
        %   - @b swapTime: estimated time of the last video hardware
        %   refresh (e.g. "vertical blank"), which is alwasy a time in the
        %   past
        %   - @b isTight: whether this frame and the previous frame were
        %   adjacent (false if a frame was skipped)
        %   .
        % Assigns the same struct to lastFrameInfo.
        function frameInfo = nextFrame(self, doClear)
            
            if nargin < 2
                doClear = true;
            end
            
            if self.getDisplayNumber() >= 0
                % flush, swap buffers
                [frameInfoData{1:4}] = self.flushGauge.flush();
                
                if doClear
                    % clear, for the next frame of graphics
                    mglClearScreen();
                end
                
            else
                % placeholder frame data
                frameInfoData = {nan, nan, nan, false};
            end
            
            % report data for the last frame
            frameInfoNames = ...
                {'onsetTime', 'onsetFrame', 'swapTime', 'isTight'};
            frameInfo = cell2struct(frameInfoData, frameInfoNames, 2);
            self.lastFrameInfo = frameInfo;
        end
        
        % Swap OpenGL frame buffers twice without drawing.
        % @details
        % Calls for a clear of both OpenGL frame buffers as well as two
        % frames buffer swaps.  This will cause any previous drawing
        % commands to be processed but not shown, and the screen to turn
        % blank.
        % Returns a struct with frame timing data obtained from
        % flushGauge, for the first flush.  The struct has fields:
        %   - @b onsetTime: estimated onset time for this frame, which
        %   might be a time in the future
        %   - @b onsetFrame: number of frames elapsed between open() and
        %   this frame
        %   - @b swapTime: estimated time of the last video hardware
        %   refresh (e.g. "vertical blank"), which is alwasy a time in the
        %   past
        %   - @b isTight: whether this frame and the previous frame were
        %   adjacent (false if a frame was skipped)
        %   .
        % Assigns the same struct to lastFrameInfo.
        function frameInfo = blank(self)
            
            if self.getDisplayNumber() >= 0
                % flush, clear, swap buffers twice
                [frameInfoData{1:4}] = self.flushGauge.blank();
                
            else
                % placeholder frame data
                frameInfoData = {nan, nan, nan, false};
            end
            
            % report data for the last frame
            frameInfoNames = ...
                {'onsetTime', 'onsetFrame', 'swapTime', 'isTight'};
            frameInfo = cell2struct(frameInfoData, frameInfoNames, 2);
            self.lastFrameInfo = frameInfo;
        end
        
        % Save gamma-correction data in stimulusGammaTable to a .mat
        % file.
        % @param fileWithPath optional .mat file where to save the gamma
        % table
        % @details
        % Saves the gamma-correction data currently in gammaTable to the
        % given @a fileWithPath.  If @a fileWithPath is omitted, defaults
        % to gammaTableFile.
        function gammaTableToMatFile(self, fileWithPath)
            if nargin < 2 || isempty(fileWithPath) || ~ischar(fileWithPath)
                fileWithPath = self.gammaTableFile;
            end
            
            if ~isempty(fileWithPath)
                gammaTable = self.stimulusGammaTable;
                save(fileWithPath, 'gammaTable');
            end
        end
        
        % Load gamma-correction data from a .mat file into
        % stimulusGammaTable.
        % @param fileWithPath optional .mat file where to save the gamma
        % table
        % @details
        % Loads the gamma-correction data from fileWithPath into the
        % gammaTableFile property.  If @a fileWithPath is omitted, defaults
        % to gammaTableFile.
        function gammaTableFromMatFile(self, fileWithPath)
            if nargin < 2 || isempty(fileWithPath) || ~ischar(fileWithPath)
                fileWithPath = self.gammaTableFile;
            end
            
            if ~isempty(fileWithPath)
                s = load(fileWithPath);
                if isfield(s, 'gammaTable')
                    self.stimulusGammaTable = s.gammaTable;
                    self.gammaTableFile = fileWithPath;
                end
            end
        end
    end
end