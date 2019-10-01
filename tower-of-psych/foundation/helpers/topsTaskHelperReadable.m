classdef topsTaskHelperReadable < topsTaskHelper
   % Class topsTaskHelperReadable
   %
   % Add topsTaskHelperReadable, a subclass of topsTaskHelper
   
   methods
      
      % Constuct the helper
      %
      % Arguments: just the ones passed to topsTaskHelper
      function self = topsTaskHelperReadable(varargin)
         
         % Parse the arguments
         [~, passedArgs] = parseHelperArgs('readable', varargin);
                 
         % Create it
         self = self@topsTaskHelper(passedArgs{:});
         
         % Add synchronization
         self.sync.clockFevalable = {@getDeviceTime, self.theObject};
      end
      
      %% startTrial
      %
      function startTrial(self, varargin)
         
         % Call the superclass startTrial method
         self.startTrial@topsTaskHelper(varargin{:});
         
         % Call the readable startTrial method
         self.theObject.startTrial();
      end
      
      %% finishTrial
      %
      function finishTrial(self, varargin)
         
         % Call the superclass finishTrial method
         self.finishTrial@topsTaskHelper(varargin{:});
         
         % Call the readable finishTrial method
         self.theObject.finishTrial();
      end
      
      %% readEvent
      %
      % Useful utility for checking for an event and, if found, saving the
      %  (synchronized) timing of the event in the trial data struture.
      %
      % Arguments:
      %  acceptedEvents ... cell array of strings acceptedEvents to list
      %                       names of events that can be used.
      %  task           ... the topsTreeNode task caller
      %  eventTag       ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      %
      function eventName = readEvent(self, acceptedEvents, task, eventTag)
         
         % Call dotsReadable.getNext
         %
         % data has the form [ID, value, time]
         [eventName, data] = self.theObject.getNextEvent(false, acceptedEvents);
         
         % Conditionally store the timing data, with synchronization offset
         if ~isempty(eventName) && nargin > 3 && ~isempty(task)
            self.saveSynchronizedTime(data(3), [], task, eventTag);
         end
      end
      
      %% Set gaze parameters
      %
      % Utility for dotsReadableEye objects:
      %     set default gaze window size and duration
      function setGazeParameters(self, windowSize, windowDuration)
         
         if isa(self.theObject, 'dotsReadableEye')
            if nargin >= 2 && ~isempty(windowSize)
               self.theObject.gazeMonitor.defaultWindowSize = windowSize;
            end
            if nargin >= 2 && ~isempty(windowSize)
               self.theObject.gazeMonitor.defaultWindowDuration = windowDuration;
            end
         end
      end
   end
end