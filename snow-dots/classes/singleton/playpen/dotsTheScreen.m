classdef dotsTheScreen < dotsAllSingletonObjects
    % Class dotsTheScreen
    % Singleton to work with the OpenGL drawing context.
    %
    % dotsTheScreen manages the Snow Dots OpenGL drawing context. "Context"
    % includes the display and window to use for drawing, OpenGL system
    % resources, OpenGL configuration, and state memory, all of which Snow
    % Dots needs in order to draw graphics with OpenGL.
    %
    % Uses a dotsTheScreenType helper object for implementation-specific
    %   functions (e.g., MGL or Psychtoolbox). Defined via property
    %   screenFrameworkType, which can be set as a default using
    %   dotsTheMachineConfiguration.  
    %
    % dotsTheMachineConfiguration provides hardware-specific defaults.
    
    % property values for dotsTheScreen.
    properties
        
        % constructor for the screen context (e.g., "MGL", "PTB")
        screenFrameworkType;
        
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
        gammaTableFileName;
    end
    
    properties (SetAccess = protected)
        
        % helper framework object
        screenFramework;
        
        % onset data from the last frame
        lastFrameInfo;
        
        % color calibration that was in the video card at startup (nx3)
        oldGammaTable;
        
        % color calibration that is to be used (nx3)
        newGammaTable;        
    end
    
    % Private methods... use static methods, below, for functionality
    methods (Access = private)
        
        % Constructor is private.
        % @details
        % Use dotsTheScreen.theObject to access the current instance.
        function self = dotsTheScreen(varargin)
            
            % update from configuration file
            mc = dotsTheMachineConfiguration.theObject();
            mc.applyClassDefaults(self);
            mc.applyClassDefaults(self, mc.defaultGroup);
            
            % update from input arguments
            self.set(varargin{:});
        end
        
    end
    
    methods
        % needed as dotsAllSingletonObjects superclass
        function initialize(self)
            self.reset();
        end
    end
    
    % Use these static methods for all screen-related
    %   commands: dotsTheScreen.<method>(<arguments>)
    methods (Static)
        
        % Access the current instance.
        function obj = theObject(varargin)
            
            % keep a copy
            persistent self
            
            if isempty(self) || ~isvalid(self)
                
                % 1. call the consructor method for this class to get the
                %   object that contains a reference to the helper subclass
                self = dotsTheScreen(varargin{:});
                
                % 2. call that subclass's constructor method
                %   to get the real object
                self.screenFramework = ...
                    feval(str2func(['dotsTheScreen' self.screenFrameworkType]));
            end
            
            % now apply any args to both self and helper
            if nargin > 1
                self.set(varargin{:});
                self.screenFramework.set(varargin{:});
            end
            
            % return the current object
            obj = self;
        end
        
        % Restore the current instance to a fresh state.
        function reset(varargin)
            
            % get the screen object
            self = dotsTheScreen.theObject(varargin{:});
            
            % close any open window
            self.screenFramework.closeWindowForScreen();
            
            % now do subclass-specific initialization
            self.screenFramework.initializeForScreen();
            
            % approximate visual coordinate conversion factor
            % note that the "actual" conversion occurs below in
            % open(), with mglVisualAngleCoordinates()
            self.pixelsPerDegree = self.displayPixels(3) ...
                / (2*(180/pi)*atan2(self.width/2, self.distance));
            
            % read the gamma table
            self.readGammaTableFromMatFile();
            
            % reset frameInfo
            self.lastFrameInfo = struct( ...
                'onsetTime',    nan, ...
                'onsetFrame',   nan, ...
                'swapTime',     nan, ...
                'isTight',      nan);
        end
        
        % Launch a graphical interface to view dotsTheScreen properties.
        function g = gui()
            self = dotsTheScreen.theObject();
            g    = topsGUIUtilities.openBasicGUI(self, mfilename());
        end
        
        % get an object by parsing the current screen type
        function obj = getObjectByScreenType(className)
            self  = dotsTheScreen.theObject();
            obj   = eval([className self.screenFrameworkType]);
        end
        
        % Set the host filename for storing a machine-specific gamma table.
        function setHostGammaTableFileName(fileName)
            self  = dotsTheScreen.theObject();
            
            % check to use default (typical)
            if isempty(fileName) || ~ischar(fileName) || ...
                    strcmp(fileName, 'default')
                [~,h]    = unix('hostname -s');
                fileName = sprintf('dots_%s_GammaTable.mat', deblank(h));
            end
            
            % save the name
            self.gammaTableFileName = fileName;
        end
        
        % Get the number of the display used for drawing.
        % @details
        % If Snow Dots has an open drawing window, returns a non-negative
        % integer which corresponds to displayIndex.  Otherwise, returns
        % -1.
        function displayNumber = getDisplayNumber()
            self = dotsTheScreen.theObject();
            displayNumber = self.getDisplayNumberForScreen();
        end
        
        % Open an OpenGL drawing window.
        function openWindow()
            self = dotsTheScreen.theObject();
            self.screenFramework.openWindowForScreen();
            
            % open the matlab command window if not already open
            commandwindow();            
        end
        
        % Close the OpenGL drawing window.
        function closeWindow()
            self = dotsTheScreen.theObject();
            self.screenFramework.closeWindowForScreen();
        end
        
        % Save gamma-correction data in newGammaTable to a .mat file.
        % Argument:
        %   fileName ... optional. If empty uses default from 
        %                   setHostGammaTableFileName.
        function saveGammaTableToMatFile(fileName)
            
            % get the screen object
            self = dotsTheScreen.theObject();
            
            % conditinally use fileName arg
            if nargin >= 1
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
        function readGammaTableFromMatFile(fileName)

            % get the screen object
            self = dotsTheScreen.theObject();
            
            % conditinally use fileName arg
            if nargin >= 1
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
        function makeGammaTable(optiCAL, fileName, tableSize, sampleInterval, targetSize)
            
            % check arguments
            if nargin < 1 || isempty(optiCAL)
                optiCAL = '/dev/tty.USA19H64P1.1';
            end
            if ~exist(optiCAL, 'file')
                disp('makeGammaTable: Cannot find optiCAL device')
                return
            end
            
            if nargin < 2
                fileName = []; % use default
            end
            
            if nargin < 3 || isempty(tableSize)
                tableSize = 256;
            end
            
            if nargin < 4 || isempty(sampleInterval)
                sampleInterval = 0.1;
            end
            
            if nargin < 5 || isempty(targetSize)
                targetSize = 10;
            end
            
            % get current screen object
            self = dotsTheScreen.theObject();
            
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