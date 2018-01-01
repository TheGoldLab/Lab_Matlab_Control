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
   %
   % Based on Psychtoolbox
   %
   % 12/23/2017 jig created from Ben Heasley's MGL-based version
   properties
      
      % dispay width (cm)
      width;
      
      % dispay height (cm)
      height;
      
      % display viewing distance (cm)
      distance;
      
      % index of display on which to open drawing windows. See PTB Screen
      displayIndex = max(Screen('Screens'));
      
      % rectangle representing the entire display (pixels, [0 0 w h])
      windowRect;
      
      % color depth of each pixel (number of bits)
      bitDepth;
      
      % whether or not to use OpenGL full-scene antialiasing
      multisample;
      
      % Hz frame rate of the current drawing window
      windowFrameRate;
      
      % approximate conversion factor for the current display
      pixelsPerDegree;
      
      % x coordinate (in pixels) of midpoint of drawing rect
      xScreenCenter;

      % y coordinate (in pixels) of midpoint of drawing rect
      yScreenCenter;
      
      % a foreground color, [L] [LA] [RGB] [RGBA], 0-255
      foregroundColor;
      
      % a background color, [L] [LA] [RGB] [RGBA], 0-255
      backgroundColor;
      
      % function that returns the current time as a number
      clockFunction;
      
      % filename with path to .mat file that contains a gamma table
      gammaTableFileName;
      
      % PTB-specific properties
      % type 'help PsychDefaultSetup' for details
      featureLevel = 2;
      
      % rect for debug window on current screen
      debugRect = [];
      
      % hide/show cursor on active screen
      hideCursor = true;
      
      % PTB debug level verbisoty
      % 0 - Disable all output - Same as using the SuppressAllWarnings flag.
      % 1 - Only output critical errors.
      % 2 - Output warnings as well.
      % 3 - Output startup information and a bit of additional information.
      %       This is the default.
      % 4 - Be pretty verbose about information and hints to optimize your
      %       code and system.
      % 5 - Levels 5 and higher enable very verbose debugging output,
      %       mostly useful for debugging PTB itself, not generally useful
      %       for end-users.
      verbosity = 3;
      
      % don't wait for flip to excecute before returning
      % 0 = sync to retrace and pause until flip
      % 1 = sync to retrace but return immediately
      % 2 = show stimulus immediately
      dontSync = 0;

      % whether or not to maximize PTB priority
      maximizePTBPriority = true;
      
      % whether or not to use standard anti-aliasing
      useAntiAliasing = true;
      
      % the PTB windowPtr
      windowPointer = [];      
   end
   
   properties (SetAccess = protected)
      
      % onset data from the last frame
      lastFrameInfo;
      
      % color calibration that was in the video card at startup (nx3)
      oldGammaTable;
      
      % color calibration that being loaded (nx3)
      newGammaTable;
      
      % PTB-specific properties
      % to restore verbosity to prior state
      priorVerbosity = [];
      
      % to keep track of VBL
      VBLCountAtOpenWindow;
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
         
         % use default setup with the given featureLevel
         PsychDefaultSetup(self.featureLevel);
         
         % initialize the drawing window
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
         
         % get the screen object
         self = dotsTheScreen.theObject(varargin{:});
         
         % now do subclass-specific initialization
         self.initialize();         
      end
      
      % Launch a graphical interface to view dotsTheScreen properties.
      function g = gui()
         self = dotsTheScreen.theObject();
         g    = topsGUIUtilities.openBasicGUI(self, mfilename());
      end
      
      % Get a filename suitable for storing a machine-specific gamma
      % table.
      function hostFile = getHostGammaTableFilename()
         [~, h]         = unix('hostname -s');
         hostFile       = sprintf('dots_%s_GammaTable.mat', deblank(h));
      end
      
      % Get the number of the display used for drawing.
      % @details
      % If Snow Dots has an open drawing window, returns a non-negative
      % integer which corresponds to displayIndex.  Otherwise, returns
      % -1.
      function displayNumber = getDisplayNumber()
         displayNumber = Screen('WindowScreenNumber', self.windowPointer);
      end
      
      % Open an OpenGL drawing window.
      function openWindow()
         
         % get this object and call open method
         self = dotsTheScreen.theObject();
         self.open();
         
         % open the matlab command window if not already open
         commandwindow();
      end
      
      % Close the OpenGL drawing window.
      function closeWindow()
         self = dotsTheScreen.theObject();
         self.close();
      end
      
      % convert position to drawing rect(s):
      %  [left top right bottom], in pixels
      function rect = getRect(x, y, width, height)
         
         % convert dva to pixels
         self = dotsTheScreen.theObject();
         
         % check args
         if nargin < 3
            width  = zeros(size(x));
            height = zeros(size(x));
         elseif nargin < 4 || (isempty(height) && ~isempty(width))
            height = width;
         elseif isempty(width) && ~isempty(height)
            width  = height;
         end
         
         % check for unequal arrays and convert to pixels
         lengths = [length(x),length(y),length(width),length(height)];
         max_length = max(lengths);
         if lengths(1) < max_length
            x = repmat(x(1)*self.pixelsPerDegree,1,max_length);
         else
            x = x(:)'.*self.pixelsPerDegree;
         end
         if lengths(2) < max_length
            y = repmat(y(1)*self.pixelsPerDegree,1,max_length);
         else
            y = y(:)'.*self.pixelsPerDegree;
         end
         if lengths(3) < max_length
            half_width = repmat(width(1)*self.pixelsPerDegree/2,1,max_length);
         else
            half_width = width(:)'.*self.pixelsPerDegree./2;
         end
         if lengths(4) < max_length
            half_height = repmat(height(1)*self.pixelsPerDegree/2,1,max_length);
         else
            half_height = height(:)'.*self.pixelsPerDegree./2;
         end         
         
         % get rect
         rect = cat(1, ...
            self.xScreenCenter+x-half_width, ...
            self.yScreenCenter-y-half_height, ...
            self.xScreenCenter+x+half_width, ...
            self.yScreenCenter-y+half_height);
      end
   end
   
   methods
      
      % Return the current instance to a fresh state, closing the window.
      function initialize(self)

         % close any open windows
         Screen('CloseAll');
         self.windowPointer = [];
         
         % read the gamma table
         self.readGammaTableFromMatFile();
         
         % reset frameInfo
         self.lastFrameInfo = struct( ...
            'onsetTime',    nan, ...
            'onsetFrame',   nan, ...
            'swapTime',     nan, ...
            'isTight',      nan);

         % check for good displayIndex
         screens = Screen('Screens');
         if ~any(self.displayIndex==screens)
            return
         end

         % NEED THIS FOR NOW ON MACBOOK PRO
         % REMOVE WHEN STABLE
         Screen('Preference', 'SkipSyncTests', 1);
         
         % get the frame rate
         self.windowFrameRate = Screen('NominalFrameRate', self.displayIndex);
         % PUT IN A DUMMY FOR NOW -- CAREFUL!!
         if self.windowFrameRate == 0
            self.windowFrameRate = 60;
         end
         
         % Here we could use DisplaySize to get the dimensions (in mm),
         %  but the Screen documentation says that it can be unreliable
         %  so we will instead assume that it is set properly in the
         %  configuration file
         % [w,h] = Screen('DisplaySize', self.displayIndex);
         % self.width           = w/10;
         % self.height          = h/10;
         
         % to use full retina resolution on macbook pro (maybe)
         % PsychImaging('PrepareConfiguration');
         % PsychImaging('AddTask', 'General', 'UseRetinaResolution');         
      end
      
      % Open an OpenGL drawing window.
      function open(self)
         
         % check for good displayIndex
         screens = Screen('Screens');
         if ~any(self.displayIndex==screens)
            return
         end
         
         % check for open window
         if ~isempty(self.windowPointer)
            Screen('Close', self.windowPointer);
         end
         
         % set verbosity
         self.priorVerbosity = ...
            Screen('Preference', 'Verbosity', self.verbosity);
         
         %
         % OPEN the screen/window ... ignore all parameters after
         %  bitDepth. Type "Screen OpenWindow?" for details.
         % NOTE: Using PsychImaging to ensure that the color
         %  specification is [0,1] (see PsychDefaultSetup)
         [self.windowPointer, self.windowRect] = ...
            PsychImaging('OpenWindow', ...
            self.displayIndex, ...
            self.backgroundColor, ...
            self.debugRect, ...
            self.bitDepth);
         
         % get the size of the on-screen window
         [screenXpixels, ~] = Screen('WindowSize', self.windowPointer);

         % windowRect is in pixels... get conversion factors
         self.pixelsPerDegree = screenXpixels / ...
            (2*atan2d(self.width/2, self.distance));
         
         % get midpoint of drawing rect
         [self.xScreenCenter, self.yScreenCenter] = ...
            RectCenter(self.windowRect);
            
         % conditionally maximize drawing priority
         if self.maximizePTBPriority
            topPriorityLevel = MaxPriority(self.windowPointer);
            Priority(topPriorityLevel);
         end
         
         % Set up alpha-blending for smooth (anti-aliased) lines
         if self.useAntiAliasing
            Screen('BlendFunction', self.windowPointer, ...
               GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
         end

         % get the VBL count
         info = Screen('GetWindowInfo', self.windowPointer );
         self.VBLCountAtOpenWindow = info.VBLCount;
         
         % conditionally hide the cursor
         if self.hideCursor
            HideCursor(self.displayIndex);
         end
         
         % load the gamma table... remember to transpose
         %   because it's stored in MGL-friendly format
         if ~isempty(self.newGammaTable)
            [self.oldGammaTable, success] = ...
               Screen('LoadNormalizedGammaTable', ...
               self.windowPointer, ...
               self.newGammaTable');
            
            if ~success
               disp('dotsTheScreen: Could not load Gamma Table for PTB')
            end
         end
      end
      
      % Close the OpenGL drawing window.
      function close(self)
         
         % close window
         self.windowPointer
         Screen('Close', self.windowPointer);
         self.windowPointer = [];
         
         % restore verbosity
         if ~isempty(self.priorVerbosity)
            Screen('Preference', 'Verbosity', self.priorVerbosity);
         end
         
         % conditionally show the cursor
         if self.hideCursor
            ShowCursor(self.displayIndex);
         end
         
         % re-set priority level
         Priority(0);
      end
      
      % Flush OpenGL drawing commands and swap OpenGL frame buffers
      %   using the PTB Screen command
      %
      % Arguments (checked in dotsTheScreen.nextFrame, which is the
      %   public routine that should be called directly):
      %   - dontClear ... whether or not clear the frame buffer after
      %                   displaying it
      %   - when    ... system time that flip should occur
      %
      % Returns a struct with frame timing data.  The struct has fields:
      %   - onsetTime ... estimated onset time for this frame, which
      %                   might be a time in the future
      %   - onsetFrame ... number of frames elapsed between open() and
      %                   this frame
      %   - swapTime ... estimated time of the last video hardware
      %                   refresh (e.g. "vertical blank"), which is
      %                   alwasy a time in the past
      %   - isTight ...  whether this frame and the previous frame were
      %                    adjacent (false if a frame was skipped)
      function frameInfo = nextFrame(self, dontClear, when)
         
         if isempty(self.windowPointer)
            
            % no screen
            frameInfo.onsetTime    = nan;
            frameInfo.onsetFrame   = nan;
            frameInfo.swapTime     = nan;
            frameInfo.isTight      = false;
         else
            
            % flush, swap buffers. 2nd return argument is estimate of
            %   stimulus-onset time, which I don't know how it's
            %   computed for LCDs so I'm ignoring for now
            [frameInfo.onsetTime, ~, ...
               frameInfo.swapTime, Missed, ~] = ...
               Screen('Flip', self.windowPointer, when, ...
               dontClear, self.dontSync);
            
            % report errors... need to check accuracy of this
            if Missed
               disp('dotsTheScreen: nextFrame missed flip deadline for PTB')
            end
            
            % compute flip frame
            info = Screen('GetWindowInfo', self.windowPointer );
            onsetFrame = info.VBLCount - self.VBLCountAtOpenWindow;
            frameInfo.isTight = ...
               onsetFrame == self.lastFrameInfo.onsetFrame + 1;
            frameInfo.onsetFrame = onsetFrame;            
         end
         
         % save the frame info
         self.lastFrameInfo = frameInfo;
      end
      
      % Blank the screen.
      % @details
      % Uses FilRect with the background color to erase the screen.
      % Returns a struct with frame timing data with fields:
      %   - @b onsetTime: estimated onset time for this frame, which
      %   might be a time in the future
      %   - @b onsetFrame: number of frames elapsed between open() and
      %   this frame
      %   - @b swapTime: estimated time of the last video hardware
      %   refresh (e.g. "vertical blank"), which is alwasy a time in the
      %   past
      %   - @b isTight: whether this frame and the previous frame were
      %   adjacent (false if a frame was skipped)
      %
      function frameInfo = blank(self)
         
         % draw a rect using the background color
         if ~isempty(self.windowPointer)
            Screen('FillRect', self.windowPointer, self.backgroundColor);
         end
         
         % call nextFrameForScreen to flip
         frameInfo = self.nextFrameForScreen(self, true, 0);
         
         % save the frame info
         self.lastFrameInfo = frameInfo;
      end
      
            % Save gamma-correction data in newGammaTable to a .mat file.
      % Argument:
      %   fileName ... optional. If empty uses default from
      %                   setHostGammaTableFileName.
      function saveGammaTableToMatFile(self, fileName)
         
         % conditinally use fileName arg
         if nargin >= 2
            self.setHostGammaTableFileName(fileName);
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
      %                   setHostGammaTableFileName.
      %                Use keyword 'none' to skip
      function readGammaTableFromMatFile(self, fileName)
         
         % conditinally use fileName arg
         if nargin >= 2
            self.setHostGammaTableFileName(fileName);
         end
         
         % check fileName
         if ~isempty(self.gammaTableFileName) && ...
               ~strcmp(self.gammaTableFileName, 'none') && ...
               exist(self.gammaTableFileName, 'file')
            s = load(self.gammaTableFileName);
            if isfield(s, 'gammaTable')
               self.newGammaTable = s.gammaTable;
            end
         end
      end
      
      % Makes a gamma table using the optiCAL device from Cambridge Research
      % Systems. This function assumes that:
      %   1. the optiCAL device is connected to the host computer using
      %           the USB-to-serial device
      %   2. the optiCAL argument (or default) points to the device in
      %           the file system
      %   3. the sensor is suctioned onto the middle of the screen
      %
      % Arguments:
      %   1 ... location of optiCAL device
      %       --> Needs USB-serial connetor
      %       --> Use 'ls /dev/tty.*' to find device name
      %       --> Use "instrfind" to find open serial objects
      %       --> Returns in units of cd/m^2
      %   2 ... gammaFileName. Can be
      %           []          do not save
      %           'default'   use getHostGammaTableFilename
      %           <name>      use given filename
      %   3 ... tableSize (def 256)
      %   4 ... sampleInterval, interval between luminance measurementes, in sec
      %   5 ... targetSize, diameter of spot to draw on screen, in deg visual angle
      function makeGammaTable(self, optiCAL, fileName, tableSize, sampleInterval, targetSize)
         
         % check arguments
         if nargin < 2 || isempty(optiCAL)
            optiCAL = '/dev/tty.USA19H64P1.1';
         end
         if ~exist(optiCAL, 'file')
            disp('makeGammaTable: Cannot find optiCAL device')
            return
         end
         
         if nargin < 3
            fileName = []; % use default
         end
         
         if nargin < 4 || isempty(tableSize)
            tableSize = 256;
         end
         
         if nargin < 5 || isempty(sampleInterval)
            sampleInterval = 0.1;
         end
         
         if nargin < 6 || isempty(targetSize)
            targetSize = 10;
         end
         
         % set up gamma table arrays
         maxV                    = tableSize-1;
         nominalLuminanceValues  = 0:maxV;
         measuredLuminanceValues = nans(tableSize, 1);
         
         % start with a nominal gamma table
         self.gammaTableFileName = 'none';
         self.newGammaTable      = repmat(nominalLuminanceValues, 1, 3)./maxV;
         
         % initialize snow dots and open a window
         self.reset();
         self.openWindow();
         
         % make target on the center of the screen
         t         = dotsDrawableTargets();
         t.xCenter = 0;
         t.yCenter = 0;
         t.width   = targetSize;
         t.height  = targetSize;
         
         % set up the optiCAL device to start taking measurements
         OP = opticalSerial(devName);
         
         if isempty(OP)
            disp('makeGammaTable: Cannot make opticalSerial object')
            return
         end
         
         % loop through the luminances
         for ii = 1:tableSize
            
            % show target
            t.colors = nominalLuminanceValues(ii)./(numValues-1).*[1 1 1];
            dotsDrawable.drawFrame({t});
            
            % get luminance reading
            OP.getLuminance(1, sampleInterval);
            
            % save it
            measuredLuminanceValues(ii) = OP.values(end);
         end
         
         % close the optiCAL device
         OP.close();
         
         % close the OpenGL drawing window
         self.closeWindow();
         
         % make the gamma table
         maxLum     = max(measuredLuminanceValues);
         scaledLum  = linspace(0, maxLum, tableSize);
         gammaTable = zeros(3, tableSize);
         for ii = 2:tableSize
            gammaTable(:,ii) = nominalLuminanceValues( ...
               find(measuredLuminanceValues>=scaledLum(ii),1,'first'))./maxV.*[1 1 1];
         end
         
         % save to file
         self.saveGammaTableToMatFile(fileName)
      end
   end
end