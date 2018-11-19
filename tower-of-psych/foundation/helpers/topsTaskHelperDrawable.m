classdef topsTaskHelperDrawable < topsTaskHelper
   % Class topsTaskHelperDrawable
   %
   % Add topsTaskHelperDrawable, a subclass of topsTaskHelper
   
   properties (SetObservable)
      
   end
   
   methods
      
      % Constuct the helper
      %
      % Arguments:
      %  drawableName ... string name of drawable
      function self = topsTaskHelperDrawable(drawableName, varargin)
         
         if nargin < 1 || isempty(drawableName)
            drawableName = 'dotsDrawable';
         end
         
         % Create it
         self = self@topsTaskHelper(drawableName, varargin{:}, 'isEnsemble', true);
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
      %                    struct has an entry called time_<eventTag>.
      %
      % Created 5/10/18 by jig
      function draw(self, args, task, eventTag)
         
         % Check for args to setObjectProperty
         if nargin >= 2 && ~isempty(args)            
                        
            if isnumeric(args{1})
               
               % Given as: [on indices] [off indices]
               if ~isempty(args{1})
                  
                  % Show objects
                  self.theObject.setObjectProperty('isVisible', true, args{1});
               end
               
               if length(args) > 1 && ~isempty(args{2})
                  
                  % hide objects
                  self.theObject.setObjectProperty('isVisible', false, args{2});
               end
               
            elseif ischar(args{1})
 
               % Given as: <propertyName>, <value(s)>, <indices>
               self.theObject.setObjectProperty(args{:});
               
            else
               
               % Given as cell array of args 
               for ii = 1:length(args)
                  self.theObject.setObjectProperty(args{ii}{:});
               end
            end
         end
         
         % Draw the next frame. This returns a struct with args:
         %   - onsetTime: estimated onset time for this frame, which
         %        might be a time in the future
         %   - onsetFrame: number of frames elapsed between open() and
         %        this frame
         %   - swapTime: estimated time of the last video hardware
         %        refresh (e.g. "vertical blank"), which is alwasy a
         %        time in the past
         %   - isTight: whether this frame and the previous frame were
         %        adjacent (false if a frame was skipped)
         frameInfo = self.theObject.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
         
         % Store the timing data
         if nargin >= 3 && ~isempty(task) && ~isempty(eventTag)
            task.setTrialData([], eventTag, frameInfo.onsetTime + ...
               dotsTheScreen.getOffsetTime() - self.sync.results.referenceTime)
         end
      end
   end
end