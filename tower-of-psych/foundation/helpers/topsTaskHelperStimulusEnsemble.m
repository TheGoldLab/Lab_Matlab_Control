classdef topsTaskHelperStimulusEnsemble < topsTaskHelper
   % Class topsTaskHelperStimulusEnsemble
   %
   % Helper class for drawing/playing any/all drawables and/or playables
   %  in an ensemble
   %
   
   properties (SetObservable)
      
      % Whether to draw drawables, or not
      drawFlag;
      
      % Whether to play playables, or not
      playFlag;
   end
   
   properties (SetAccess = protected)
      
      % Keep track of drawable objects
      drawableIndices = [];
      
      % Keep track of playable objects
      playableIndices = [];      
   end
   
   methods
      
      % Constuct the helper
      %
      % Optional parameters: draw, play (see above)
      function self = topsTaskHelperStimulusEnsemble(varargin)
         
         % Parse the arguments
         [parsedArgs, passedArgs] = parseHelperArgs('stimulusEnsemble', varargin, ...
            'drawFlag',     false,    ...
            'playFlag',     false);
         
         % Create it
         self = self@topsTaskHelper(passedArgs{:});
         
         % Set properties
         self.drawFlag = parsedArgs.drawFlag;
         self.playFlag = parsedArgs.playFlag;
         
         % Check screen
         if ~dotsTheScreen.isOpen
            self.drawFlag = false;
         end
         
         % Keep track of drawable/playable indices
         self.drawableIndices = find(strncmp('dotsDrawable', ...
            self.ensembleObjectClasses, length('dotsDrawable')));
         self.drawableIndices = find(strncmp('dotsPlayable', ...
            self.ensembleObjectClasses, length('dotsPlayable')));
      end
      
      %% Show stimulus
      %
      % Utility for drawing/playing stimuli in this helper's ensemble
      %
      % Optional arguments:
      %  names    ... string or cell array of strings of names in 
      %                 ensembleObjectNames
      function show(self, names, task, eventTag)
         
         % check args
         if nargin < 2 || isempty(names)
            drawableInds = self.drawableIndices;
            playableInds = self.playableIndices;
         else
            [~, objectInds] = ismember(names, self.ensembleObjectNames);
            drawableInds = intersect(objectInds, self.drawableIndices);
            playableInds = intersect(objectInds, self.playableIndices);
         end         
         
         % Flag to keep track if we save sync times for the drawable(s), in
         % which case don't use extra timestamp for playable(s)
         savedTime = false;
         
         % DRAW: use dotsDrawable.drawEnsemble to do the work.
         if self.drawFlag && ~isempty(drawableInds)
            
            % Use drawEnsemble to do the work
            frameInfo = dotsDrawable.drawEnsemble(self.theObject, drawableInds);
            
            % Store the timing data
            if nargin >=4 && ~isempty(task) && ~isempty(eventTag)
               self.saveSynchronizedTime(frameInfo.onsetTime, true, task, eventTag);
               savedTime = true;
            end
         end
         
         % PLAY: just loop through sounds, if given
         if self.playFlag && ~isempty(playableInds)
            
            % Loop through the sounds
            for pp = playableInds
               
               % Play the sound
               play(self.theObject.objects{pp});
            end
            
            % Should be Asynchronous, so this is an estimate of onset time
            % (i.e., just after returning from play) of the final sound -- but there are
            % certainly latencies that we ARE NOT TAKING INTO ACCOUNT that we
            % should if we really care about timing information
            % Store the timing data
            onsetTime = feval(self.clockFunction);

            % Store the timing data
            if ~savedTime && nargin >= 4 && ~isempty(task) && ~isempty(eventTag)
               task.setTrialData([], eventTag, onsetTime);
            end
         end
      end
   end
end