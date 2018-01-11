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
    properties (SetAccess = protected)
      
      % utility object to account for OpenGL frame timing
        flushGauge;
    end
    
    methods (Access = {?dotsTheScreen})
        
        % Constructor is protected -- should only be called from dotsTheScreen.
        function self = dotsTheScreenMGL()
            self=self@dotsTheScreenType;
        end
    end
    
    % Protected methods that govern subclass function
    methods (Access = protected)
        
        % Return the current instance to a fresh state, closing the window.
        function initializeForScreen(self)
            
            % may not start out with an open window
            self.closeWindowForScreen();
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
        
        % Get the number of the display used for drawing.
        % @details
        % If Snow Dots has an open drawing window, returns a non-negative
        % integer which corresponds to displayIndex.  Otherwise, returns
        % -1.
        function displayNumber = getDisplayNumberForScreen(self)
            displayNumber = mglGetParam('displayNumber');
        end
        
        % Open an OpenGL drawing window.
        function openWindowForScreen(self)

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
            % not used so jig commented 9/4/17
            %             systemTable = mglGetGammaTable();
            %             n = length(systemTable.redTable);
            %             self.systemGammaTable = zeros(3,n);
            %             self.systemGammaTable(1,:) = systemTable.redTable;
            %             self.systemGammaTable(2,:) = systemTable.greenTable;
            %             self.systemGammaTable(3,:) = systemTable.blueTable;            
            
            % conditionally load a stimulus-appropriate gamma table
            if ~isempty(self.stimulusGammaTable)                
                mglSetGammaTable(self.stimulusGammaTable');
            end
        end
        
        % Close the OpenGL drawing window.
        function closeWindowForScreen(self)
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
        function frameInfo = nextFrameForScreen(self, doClear)
            
            if self.getDisplayNumber() >= 0
                % flush, swap buffers
                [self.lastFrameInfo.onsetTime, ...
                    self.lastFrameInfo.onsetFrame, ...
                    self.lastFrameInfo.swapTime, ...
                    self.lastFrameInfo.isTight] = ...
                    self.flushGauge.flush();
                
                if doClear
                    % clear, for the next frame of graphics
                    mglClearScreen();
                end
                
            else
                % no screen
                self.lastFrameInfo.onsetTime    = nan;
                self.lastFrameInfo.onsetFrame   = nan;
                self.lastFrameInfo.swapTime     = nan;
                self.lastFrameInfo.isTight      = false;
            end
            
            % return a copy
            frameInfo = self.lastFrameInfo;
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
        function frameInfo = blankForScreen(self)
            
            if self.getDisplayNumber() >= 0
                % flush, clear, swap buffers twice
                [self.lastFrameInfo.onsetTime, ...
                    self.lastFrameInfo.onsetFrame, ...
                    self.lastFrameInfo.swapTime, ...
                    self.lastFrameInfo.isTight] = ...
                    self.flushGauge.blank();
                
            else
                % no screen
                self.lastFrameInfo.onsetTime    = nan;
                self.lastFrameInfo.onsetFrame   = nan;
                self.lastFrameInfo.swapTime     = nan;
                self.lastFrameInfo.isTight      = false;
            end
            
            % return a copy
            frameInfo = self.lastFrameInfo;
        end
    end
end