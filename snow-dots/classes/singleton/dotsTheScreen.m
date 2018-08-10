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
      backgroundColor = [0 0 0];
      
      % function that returns the current time as a number
      clockFunction;
      
      % filename with path to .mat file that contains a gamma table
      gammaTableFileName;
      
      % newly loaded color calibration
      newGammaTable;
   end
   
   properties (SetAccess = protected)
      % utility object to account for OpenGL frame timing
      flushGauge;
      
      % onset data from the last frame
      lastFrameInfo;
      
      % color calibration that was in the video card at startup (nx3)
      systemGammaTable;
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
      function gammaTableFileName = getHostGammaTableFilename
         gammaTableFileName = sprintf('dots_%s_GammaTable.mat', getMachineName());
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
      
      % Makes a gamma table using the optiCAL device from Cambridge Research
      % Systems. Easist way to call this is:
      %
      %  -> dotsTheScreen.makeGammaTable();
      %
      % If you want to check and plot the results, try this:
      %
      %  -> [gammaTable, values] = dotsTheScreen.makeGammaTable(true);
      %  -> cla reset; hold on
      %  -> plot(values(:,1), values(:,2), 'k.'); % uncorrected
      %  -> plot(values(:,1), values(:,3), 'r.'); % corrected
      %
      %  Note that this routine will put a file in your current working directory
      %  that contains the new gamma table. If you want to keep using this
      %  table by default, just make sure that it lives somewhere on your
      %  Matlab path.
      %
      % This function assumes that:
      %   1. the optiCAL device is connected to the host computer using
      %           the USB-to-serial device. To check that it is recognized,
      %           type 'ls /dev/tty.*' ... if it is connected using the
      %           keyspan USB-serial, it should be something like
      %           /dev/tty.USA*. Use "instrfind" to find open serial
      %           objects. Returns in units of cd/m^2
      %
      %   2. the optiCAL argument (or default) points to the device in
      %           the file system
      %   3. the sensor is suctioned onto the middle of the screen
      %
      % Arguments:
      %  doTest      ... boolean flag to test gamma after correction
      %   fileName   ... gammaFileName. [] for default.
      %   tableSize  ... length of the gamma table
      %   targetSize ... diameter of spot to draw on screen, in deg visual angle
      %
      % Returns:
      %  gammaTable  ... the new gamma table
      %  values      ... nx3 matrix of [nominal values, measuredValues, correctedValues]
      %                    (3rd column only if doTest=true)
      %
      function [gammaTable, values] = makeGammaTable(doTest, ...
            fileName, tableSize, targetSize)
         
         % Open a window with no gamma table
         dotsTheScreen.reset('gammaTableFileName', 'none');
         dotsTheScreen.openWindow();
         
         % check arguments
         if nargin < 1 || isempty(doTest)
            doTest = false;
         end
         
         if nargin < 2
            fileName = []; % use default
         end
         
         if nargin < 3 || isempty(tableSize)
            table = mglGetGammaTable();
            tableSize = size(table.redTable,2);
         end
         
         if nargin < 4 || isempty(targetSize)
            targetSize = 20;
         end
         
         % set up gamma table arrays
         maxV                    = tableSize-1;
         nominalLuminanceValues  = 0:maxV;
         measuredLuminanceValues = nans(tableSize, 1);
         
         % make target on the center of the screen
         t         = dotsDrawableTargets();
         t.xCenter = 0;
         t.yCenter = 0;
         t.width   = targetSize;
         t.height  = targetSize;
         
         % set up the optiCAL device to start taking measurements
         OP = opticalSerial();
         
         if isempty(OP)
            disp('makeGammaTable: Cannot make opticalSerial object')
            return
         end
         
         % loop through the luminances
         for ii = 1:tableSize
            
            % show target
            t.colors = nominalLuminanceValues(ii)./(maxV).*[1 1 1];
            dotsDrawable.drawFrame({t});
            
            % get luminance reading
            OP.getLuminance(1, 0);
            
            % save it
            measuredLuminanceValues(ii) = OP.values(end);
         end
         
         % make the gamma table
         maxLum     = max(measuredLuminanceValues);
         scaledLum  = linspace(0, maxLum, tableSize);
         gammaTable = zeros(3, tableSize);
         for ii = 2:tableSize
            gammaTable(:,ii) = nominalLuminanceValues( ...
               find(measuredLuminanceValues>=scaledLum(ii),1,'first'))./maxV.*[1 1 1]';
         end
         
         % save the new gamma table to a file
         screen = dotsTheScreen.theObject();
         screen.newGammaTable = gammaTable;
         screen.saveGammaTableToMatFile(fileName);
         
         % return the measured values
         values = cat(2, nominalLuminanceValues', measuredLuminanceValues);
         
         % possibly run a test
         if doTest
            
            % set the new gamma table
            mglSetGammaTable(gammaTable);
            
            % collect samples
            correctedLuminanceValues = nans(tableSize, 1);
            
            % loop through the luminances
            for ii = 1:tableSize
               
               % show target
               t.colors = nominalLuminanceValues(ii)./(maxV).*[1 1 1];
               dotsDrawable.drawFrame({t});
               
               % get luminance reading
               OP.getLuminance(1, 0);
               
               % save it
               correctedLuminanceValues(ii) = OP.values(end);
            end
            
            % save the new values
            values = cat(2, values, correctedLuminanceValues);
         end
         
         % close the optiCAL device
         OP.close();
         
         % close the OpenGL drawing window
         dotsTheScreen.closeWindow();
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
         
         % reading from mglDescribeDisplays seems accurate
         self.width = display.screenSizeMM(1)/10;
         self.height = display.screenSizeMM(2)/10;
         
         % approximate visual coordinate conversion factor
         % note that the "actual" conversion occurs below in
         % open(), with mglVisualAngleCoordinates()
         self.pixelsPerDegree = self.displayPixels(3) / ...
            (2 * rad2deg(atan2(self.width/2, self.distance)));
         
         % utility to manage frame timing
         self.flushGauge = dotsMglFlushGauge();
         self.flushGauge.clockFunction = self.clockFunction;
         
         % locate a gamma table to be loaded during open()
         self.readGammaTableFromMatFile();
      end
      
      % Open an OpenGL drawing window.
      function open(self)
         
         % Check if open
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
         
         % in pixels
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
         
         if ~isempty(self.newGammaTable)
            % load a stimulus-appropriate gamma table
            mglSetGammaTable(self.newGammaTable);
         end
      end
      
      % Close the OpenGL drawing window.
      function close(self)
         mglDisplayCursor(1);
         if self.getDisplayNumber >= 0
            mglClose();
         end
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
         
         %disp('dotsTheScreen: GETTING NEXT FRAME')
         
         if nargin < 2
            doClear = true;
         end
         
         if self.getDisplayNumber() >= 0
            
            % flush, swap buffers
            [frameInfoData{1:4}] = self.flushGauge.flush();
            
            if doClear
               
               % clear, for the next frame of graphics
               mglClearScreen(self.backgroundColor);
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
      
      % Gets the current time
      function time = getCurrentTime(self)
         time = self.clockFunction();
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
      function frameInfo = blank(self, backgroundColor)
         
         if nargin > 1 && ~isempty(backgroundColor)
            self.backgroundColor = backgroundColor;
         end
         
         if self.getDisplayNumber() >= 0
            % flush, clear, swap buffers twice
            [frameInfoData{1:4}] = self.flushGauge.blank(self.backgroundColor);
            
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
      
      % Save gamma-correction data in newGammaTable to a .mat file.
      % Argument:
      %   fileName ... optional. If empty uses default from
      %                   setHostGammaTableFileName.
      function saveGammaTableToMatFile(self, fileName)
         
         % conditinally use fileName arg
         if nargin >= 2
            self.gammaTableFileName = fileName;
         end
         
         % Conditionally get default name
         if isempty(self.gammaTableFileName)
            self.gammaTableFileName = self.getHostGammaTableFilename();
         end
         
         % save it
         if ~isempty(self.gammaTableFileName) && ...
               ~isempty(self.newGammaTable)
            gammaTable = self.newGammaTable;
            save(self.gammaTableFileName, 'gammaTable');
         end
      end
      
      % Load gamma-correction data from a .mat file into newGammaTable.
      % Argument:
      %   fileName ... optional. If empty uses default from
      %                setHostGammaTableFileName. Keywords:
      %                'none' = skip
      %                'make' = call makeGammaTable
      function readGammaTableFromMatFile(self, fileName)
         
         % Conditionally use fileName arg
         if nargin >= 2
            self.gammaTableFileName = fileName;
         end
         
         % Conditionally get default name
         if isempty(self.gammaTableFileName)
            self.gammaTableFileName = self.getHostGammaTableFilename();
         end
         
         % check gammaTableFileName
         if strcmp(self.gammaTableFileName, 'none')
            
            % flag indicating explicity NO gamma table
            self.newGammaTable = [];
            
         elseif strcmp(self.gammaTableFileName, 'make')
            
            % flag indicating to make it anew
            self.makeGammaTable();
            
         elseif ~isempty(self.gammaTableFileName) && ...
               exist(self.gammaTableFileName, 'file')
            
            % otherwise check that it exists and load if so
            s = load(self.gammaTableFileName);
            if isfield(s, 'gammaTable')
               disp(sprintf('loading gamma from <%s>', self.gammaTableFileName))
               self.newGammaTable = s.gammaTable;
            end
            
         end
      end
   end
end