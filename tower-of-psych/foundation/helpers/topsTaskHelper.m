classdef topsTaskHelper < topsFoundation
   % Class topsTaskHelper
   %
   % Standard interface for adding snow-dots "helper" objects to a
   % topsTreeNode
   
   properties (SetObservable)
      
      % The helper object
      theObject;      
      
      % Timeout to get synchronization time, in sec
      syncTimeout=0.5;
      
      % Minimum round trip time needed
      syncMinRoundTrip = 0.02;
      
      % the clock function
      clockFunction;
      
      % For time synchronization
      sync = struct( ...
         'offset',     0, ...
         'roundTrip',  0);
   end
   
   properties (SetAccess = private)
      
      % Call list used to prepare for use
      prepareCallList;
   end
  
   methods
      
      % Constuct with name optional.
      function self = topsTaskHelper(theObject)
         
         % Create it
         self = self@topsFoundation(class(theObject));
         
         % Default clock function
         self.clockFunction=dotsTheMachineConfiguration.getDefaultValue('clockFunction');
      end
      
      % Function to prepare for use
      function prepare(self)
         
         if ~isempty(self.prepareCallList)
            self.prepareCallList.run();
         end
      end
      
      % Function to synchronize
      function synchronize(self, treeNode, timeFevalable)
         
         % Get the device time
         self.sync.roundTrip  = inf;
         started              = feval(self.clockFunction);
         after                = started;
         while (self.sync.roundTrip > self.syncMinRoundTrip) && ...
               ((after-started) < self.syncTimeout);
            before               = feval(self.clockFunction);
            remoteTime           = feval(timeFevalable{:});
            after                = feval(self.clockFunction);
            self.sync.roundTrip  = after - before;
         end
         if (after-started) >= self.syncTimeout
            error(sprintf('Helper <%s>: Could not synchronize', self.name))
         end
         
         % offset is local - remote, then offset relative to topNode sync time 
         self.sync.offset = mean([before after])-remoteTime-treeNode.helperSyncTime;
         
         % Store offset, round-trip time in data log
         topsDataLog.logDataInGroup(self.sync, ['sync_' self.name]);
      end
      
      % Add fevalable(s) to the prepareCallList
      %
      % prepareSpecs is a cell array of cell arrays
      %  of fevalable arguments, minus the object; e.g., 
      %  {{<method> <args>}, {<method> <args>}}
      function addPreprarables(self, prepareSpecs)
         
         % Needs specs
         if isempty(prepareSpecs)
            return
         end
         
         % Make sure the call list exists
         if isempty(self.prepareCallList)
            self.prepareCallList = topsCallList();
            self.prepareCallList.alwaysRunning = false;
            ind = 0;
         else
            ind = length(self.prepareCallList.calls)-1;
         end

         % Loop through the specs, giving unique names
         if ~iscell(prepareSpecs{1})
            prepareSpecs = {prepareSpecs};
         end
         for ii = 1:length(prepareSpecs)            
            callList.addCallForObject(self.theObject, ...
               prepareSpecs{ii}, [self.name num2str(ind+ii)]);
         end            
      end
      
      % Set property
      function setProperty(self, name, value, index)
         if nargin < 4 || isempty(index)
            self.theObject.(name) = value;
         else
            self.theObject.(name)(index) = value;
         end
      end 
      
      % Add helperBindings
      % Helper bindings is cell array of string names of helpers 
      function addBindings(self, treeNode, helperBindings)         
         
         for ii = 1:length(helperBindings)
            self.theObject.helpers.(helperBindings) = ...
               treeNode.helpers.(helperBindings).theObject;
         end
      end
      
        %% getEventWithTimestamp
      %
      % Useful utility for saving the timing of the event in the trial data
      % struture.
      %
      % Arguments:
      %  task           ... the topsTreeNode task caller
      %  acceptedEvents ... cell array of strings acceptedEvents to list
      %                       names of events that can be used.
      %  eventTag       ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      %
      function eventName = getEventWithTimestamp(self, task, ...
            acceptedEvents, eventTag)
         
         % Call dotsReadable.getNext
         %
         % data has the form [ID, value, time]
         [eventName, data] = self.theObject.getNextEvent([], acceptedEvents);
         
         if ~isempty(eventName)
            
            % Store the timing data
            task.setTrialTime([], eventTag, data(3));
         end
      end
      
      %% showText
      %
      % Utility to show text using the textEnsemble or command window
      %
      % Optional arguments are:
      %  showDuration
      %  pauseDuration
      function showText(self, textStrings, eventTag, varargin)

         % check string format
         if ischar(textStrings)
            textStrings = {textStrings};
         end
         
         % jig : need to make more robust checks at some point
         if ~isempty(self.sharedHelpers.drawables)
%                length(self.sharedDrawableEnsemble.objects) >= size(textStrings,2) && ...
%                isa(self.sharedDrawableEnsemble.objects{1}, 'dotsDrawableText')
            
            % Draw using ensemble, getting timestamp
            ret  = dotsDrawableText.drawEnsemble(self.sharedHelpers.drawables, ...
               textStrings, true, varargin{:});
            drawTime = ret.onsetTime;
         else
            
            % Just show in the command window
            for ii = 1:length(textStrings)
               disp(textStrings{ii});
            end
            drawTime = mglGetSecs;
         end
         
         if nargin >= 3 && ~isempty(eventTag)
            self.setTrialTime([], 'screenEnsemble', eventTag, drawTime);
         end
      end

   end
   
   methods (Static)
      
      function helper = makeHelper(theObject)
         
         if isa(theObject, 'topsEnsemble') || isa(theObject, 'dotsClientEnsemble')
            helper = topsTaskHelperEnsemble(theObject);
         else
            helper = topsTaskHelper(theObject);
         end
      end
   end
end   