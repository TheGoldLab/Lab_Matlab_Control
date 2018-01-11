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
      
      % type 'help PsychDefaultSetup' for details
      featureLevel=2;
      
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
      verbosity=3;
      
      % don't wait for flip to excecute before returning
      dontSync = false;
   end
   
   properties (SetAccess = protected)
      
      % the PTB windowPtr
      windowPointer = [];
      
      % to restore verbosity to prior state
      priorVerbosity;
      
      % to keep track of VBL
      VBLCountAtOpenWindow;
   end
   
   methods (Access = {?dotsTheScreen})
      
      % Constructor is protected -- should only be called from dotsTheScreen.
      function self = dotsTheScreenPTB()
         self=self@dotsTheScreenType;
         
         % use default setup with the given featureLevel
         PsychDefaultSetup(self.featureLevel);
      end
   end
   
   % Protected methods that govern subclass function
   methods (Access = protected)
      
      % Return the current instance to a fresh state, closing the window.
      function initializeForScreen(self)
         
         % Get information about displays
         screens = Screen('Screens');
         if ~any(self.displayIndex==screens)
            self.displayIndex = max(screen);
         end
         [w,h] = Screen('DisplaySize',self.displayIndex);
         self.displayPixels = [0 0 w h];
      end
      
      % Get the number of the display used for drawing.
      % @details
      % If Snow Dots has an open drawing window, returns a non-negative
      % integer that corresponds to displayIndex.  Otherwise, returns
      % -1.
      function displayNumber = getDisplayNumberForScreen(self)
         displayNumber = Screen('WindowScreenNumber', self.windowPointer);
      end
      
      % Open an OpenGL drawing window.
      function openWindowForScreen(self)
         
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
         
         % open screen/window ... ignore all parameters after
         %   bitDepth. Type "Screen OpenWindow?" for details.
         [self.windowPointer, self.windowRect] = ...
            Screen('OpenWindow', ...
            self.displayIndex, ...
            self.backgroundColor, ...
            self.debugRect, ...
            self.bitDepth);
         
         % get the VBL count
         info = Screen('GetWindowInfo', self.windowPtr);
         self.VBLCountAtOpenWindow = info.VBLCount;
         
         % conditionally hide the cursor
         if self.hideCursor
            HideCursor(self.displayIndex);
         end
         
         % get the frame
         self.frameRate = Screen('NominalFrameRate', self.windowPointer);
         disp(self.frameRate)
         
         % load the gamma table... remember to transpose
         %   because it's stored in MGL-friendly format
         if ~isempty(self.newGammaTable)
            [self.oldGammaTable, success] = Screen('LoadNormalizedGammaTable', ...
               self.windowPointer, ...
               self.newGammaTable');
            
            if ~success
               disp('dotsTheScreenPTB: Could not load Gamma Table')
            end
         end
      end
      
      % Close the OpenGL drawing window.
      function closeWindowForScreen(self)
         
         % close window
         Screen('Close', self.windowPointer);
         self.displayIndex  = -1;
         self.windowPointer = [];
         
         % restore verbosity
         Screen('Preference', 'Verbosity', self.priorVerbosity);
      end
      
      % Flush OpenGL drawing commands and swap OpenGL frame buffers
      %   using the PTB Screen command
      %
      % Arguments (checked in dotsTheScreen.nextFrame, which is the
      %   public routine that should be called directly):
      %   - doClear ... whether or not clear the frame buffer after
      %                   displaying it
      %   - when    ... system time that flip should occur
      %
      % Returns a struct with frame timing data obtained from
      % flushGauge.  The struct has fields:
      %   - onsetTime ... estimated onset time for this frame, which
      %                   might be a time in the future
      %   - onsetFrame ... number of frames elapsed between open() and
      %                   this frame
      %   - swapTime ... estimated time of the last video hardware
      %                   refresh (e.g. "vertical blank"), which is
      %                   alwasy a time in the past
      %   - isTight ...  whether this frame and the previous frame were
      %                    adjacent (false if a frame was skipped)
      function frameInfo = nextFrameForScreen(self, doClear, when)
         
         if isempty(self.windowPointer)
            
            % no screen
            self.lastFrameInfo.onsetTime    = nan;
            self.lastFrameInfo.onsetFrame   = nan;
            self.lastFrameInfo.swapTime     = nan;
            self.lastFrameInfo.isTight      = false;
         else
            
            % flush, swap buffers. 2nd return argument is estimate of
            %   stimulus-onset time, which I don't know how it's
            %   computed for LCDs so I'm ignoring for now
            [self.lastFrameInfo.onsetTime, ~, ...
               self.lastFrameInfo.swapTime, Missed, ~] = ...
               Screen('Flip', self.windowPointer, when, ...
               ~doClear, self.dontSync);
            
            % compute flip frame
            info = Screen('GetWindowInfo', self.windowPtr);
            onsetFrame = info.VBLCount - self.VBLCountAtOpenWindow;
            self.lastFrameInfo.isTight = ...
               onsetFrame == self.lastFrameInfo.onsetFrame + 1;
            self.lastFrameInfo.onsetFrame = onsetFrame;
            
            % report errors... need to check accuracy of this
            if Missed
               disp('dotsTheScreenPTB: nextFrameForScreen missed flip deadline')
            end
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
         
         % draw a rect using the background color
         if ~isempty(self.windowPointer)
            Screen('FillRect', self.windowPointer, self.backgroundColor);
         end
         
         % call nextFrameForScreen to flip
         frameInfo = self.nextFrameForScreen(self, true, 0);
      end
   end
end