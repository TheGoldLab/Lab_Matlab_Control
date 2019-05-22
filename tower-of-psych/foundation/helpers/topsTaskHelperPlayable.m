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
            playableName = 'dotsPlayableTone';
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
      function startPlaying(self, task, eventTag)
         
         % Play the sound
         play(self.theObject);
         
         % Should be Asynchronous, so this is an estimate of onset time
         % (i.e., just after returning from play) -- but there are
         % certainly latencies that we ARE NOT TAKING INTO ACCOUNT that we
         % should if we really care about timing information
         % Store the timing data
         onsetTime = feval(self.clockFunction);

         % Store the timing data
         if nargin >= 2 && ~isempty(task) && ~isempty(eventTag)
            task.setTrialData([], eventTag, onsetTime);
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
      function finishPlaying(self, task, eventTag)
         
         % Play the sound
         stopPlaying(self.theObject);
         
         % See above -- this is probably a pretty bad estimate of the
         % offset time
         offsetTime = feval(self.clockFunction);

         % Store the timing data
         if nargin >= 2 && ~isempty(task) && ~isempty(eventTag)
            task.setTrialData([], eventTag, offsetTime);
         end
      end
   end
end