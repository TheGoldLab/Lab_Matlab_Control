classdef topsTaskHelperDrawable < topsTaskHelper
   % Class topsTaskHelperDrawable
   %
   % Add topsTaskHelperDrawable, a subclass of topsTaskHelper
   
   properties (SetObservable)
      
   end
   
   methods
      
      % Constuct the helper
      %
      function self = topsTaskHelperDrawable(varargin)
         
         % Parse the arguments
         [~, passedArgs] = parseHelperArgs('drawable', varargin);
         
         % Create it
         self = self@topsTaskHelper(passedArgs{:});      
      end
            
      %% draw(self, args, task, eventTag)
      %
      % Utility for setting isVisible flag of drawable objects to true/false,
      %  then sending a screen flip command and saving the (synchronized)
      %  timing in the current trial structure. Remember that
      %  syncronization is done by the screenEnsemble helper, which stores 
      %  the result in the dotsTheScreen singleton object so everyone else
      %  can access it.
      %
      % **** REQUIRES theObject to be a drawable ensemble ****
      %
      % Arguments:
      %  args         ... cell array of args to send to "setObjectProperty"
      %                    format: {<propertyName>, <value(s)>, <indices>}
      %                    also can be cell array of cell arrays.
      %  task         ... the calling topsTreeNodeTask
      %  eventTag     ... string used to store timing information in trial
      %                    struct. Assumes that the current trialData
      %                    struct has an entry called <eventTag>.
      %
      % Created 5/10/18 by jig
      function draw(self, args, task, eventTag)
         
         % Check args
         if nargin < 2
            args = [];
            if nargin < 3
               task = [];
               if nargin < 4
                  eventTag = [];
               end
            end
         end
         
         % Use dotsDrawable.drawEnsemble to do the work. For now we do not
         % have the capacity to send a "prepareToDrawFlag" but could change
         % that if needed (third argument)
         frameInfo = dotsDrawable.drawEnsemble(self.theObject, args, false);
         
         % Store the timing data
         if ~isempty(task) && ~isempty(eventTag)
            self.saveSynchronizedTime(frameInfo.onsetTime, true, task, eventTag);
         end
      end
   end
end