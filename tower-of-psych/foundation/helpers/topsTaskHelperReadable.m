classdef topsTaskHelperReadable < topsTaskHelper
   % Class topsTaskHelperReadable
   %
   % Add topsTaskHelperReadable, a subclass of topsTaskHelper

   methods
      
      % Constuct the helper
      %
      % Arguments:
      %  readableName ... string name of readable
      %  topsTreeNode ... typically the top node, to bind
      function self = topsTaskHelperReadable(readableName, topsTreeNode, varargin)
         
         if nargin < 1 || isempty(readableName)
            readableName = 'dotsReadable';
         end
         
         if nargin < 2
            varargin = {readableName};
         end
         
         % Create it
         self = self@topsTaskHelper(readableName, readableName, varargin{:});
         
         % Bind to the treeNode via the start/finish call lists
         if nargin >= 2 && ~isempty(topsTreeNode)
            topsTreeNode.addCall('start',  {@calibrate}, 'calibrate',  self.theObject);
            topsTreeNode.addCall('start',  {@record, true}, 'record on',  self.theObject);
            topsTreeNode.addCall('finish', {@close}, 'close', self.theObject);
            topsTreeNode.addCall('finish', {@record, false}, 'record off', self.theObject);
         end
         
         % Add synchronization
         self.sync.clockFevalable = {@getDeviceTime, self.theObject};
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
            task.setTrialData([], eventTag, data(3) + self.sync.offset);
         end
      end
   end
end