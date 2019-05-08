classdef topsTaskHelperPlayable < topsTaskHelper
   % Class topsTaskHelperPlayable
   %
   % Add topsTaskHelperPlayable, a subclass of topsTaskHelper
   
   properties (SetObservable)
      
   end
   
   methods
      
      % Constuct the helper
      %
      % Arguments:
      %  playableName ... string name of playable
      function self = topsTaskHelperPlayable(playableName, varargin)
         
         if nargin < 1 || isempty(playableName)
            playableName = 'dotsPlayable';
         end
         
         % Create it
         self = self@topsTaskHelper(playableName, [], varargin{:});
      end
            
      %% play(self, args, task, eventTag)
      %
      % Utility for starting playing a sound
      %
      % Arguments:
      %  task         ... the calling topsTreeNodeTask
      %  eventTag     ... string used to store timing information in trial
      %                    struct. Assumes that the current trialData
      %                    struct has an entry called time_<eventTag>.
      %
      % Created 5/10/18 by jig
      function startPlaying(self, args, task, eventTag)
         
         % Play the sound
            if ~isempty(args)
           self.theObject.callObjectMethod(@play, [], args);
            else
          play(self.theObject);
            end
         onsetTime=mglGetSecs;
         
         % Store the timing data
          if nargin >= 3 && ~isempty(task) && ~isempty(eventTag)
             [offsetTime, referenceTime] = dotsTheScreen.getSyncTimes();
            task.setTrialData([], eventTag, onsetTime - ...
                referenceTime + offsetTime);
         end
         
      end
      
      %% play(self, args, task, eventTag)
      %
      % Utility for stopping playing a sound
      %
      % Arguments:
      %  task         ... the calling topsTreeNodeTask
      %  eventTag     ... string used to store timing information in trial
      %                    struct. Assumes that the current trialData
      %                    struct has an entry called time_<eventTag>.
      %
      % Created 5/10/18 by jig
      function finishPlaying(self, args, task, eventTag)
         onsetTime=mglGetSecs;
         % Play the sound
         if ~isempty(args)
             self.theObject.callObjectMethod(@stopSound, [], args);
         

         else
                 stopSound(self.theObject);
         end
          
         
         % Store the timing data
         if nargin >= 3 && ~isempty(task) && ~isempty(eventTag)
             [offsetTime, referenceTime] = dotsTheScreen.getSyncTimes();
            task.setTrialData([], eventTag, onsetTime - ...
                referenceTime + offsetTime);
         end
      end
   end
end