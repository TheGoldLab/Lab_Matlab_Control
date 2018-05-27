classdef topsTreeNodeTask < topsTreeNode
   % @class topsTreeNodeTask
   %
   % A special-purpose version of a topsTreeNode with properties and
   % functions that facilitate operating with tasks. This is an alternative
   % approach than making the trials topsTreeNode children. Instead here
   % the trials are defined by an array of structs with trial-specific data
   % that can make it easy to dump that struct into the topsDataLog and
   % keep track of what is going on.
   %
   % 5/27/18 created by jig
   
   properties
      
      % Keep track of which task this is
      taskIndex = 0;
      
      % Typically a struct of task-specific data
      taskData = [];
      
      % Typically an array of structs describing each trial
      trialData = [];
      
      % Current trial count in current iteration
      trialCount = 0;
      
      % Keep track of previous trial for updating
      previousTrialIndex = 0;
      
      % Current trial index in current iteration
      trialIndex = 0;
      
      % Number of times to run through this node's trials
      trialIterations = 1;
      
      % Count of iterations while running
      trialIterationCount = 1;
      
      % How to run through this node's trials --'sequential' or
      % 'random' order
      trialIterationMethod = 'random';
      
      % Flag indicating whether or not to randomize order of repeated trial
      randomizeWhenRepeating = true;
      
      % Array of trial indices, in order of calling
      trialIndices = [];
   end
   
   methods
      % Constuct with name optional.
      % @param name optional name for this object
      % @details
      % If @a name is provided, assigns @a name to this object.
      function self = topsTreeNodeTask(varargin)
         self = self@topsTreeNode(varargin{:});
      end
      
      % Figure out the next trial. If done, call the task's finish()
      %  routine, which should allow the parent topsTreeNode to find the
      %  next task.
      %
      % Argument repeatTrial is a boolean flag indicating that this trial
      % needs to be repeated
      function updateTrial(self, repeatTrial)
         
         % Check if we need to initalize the trialIndices array
         if ~isempty(self.trialData) && isempty(self.trialIndices)
            
            % Make array of indices
            if strcmp(self.trialIterationMethod, 'random')
               
               % Randomized
               self.trialIndices = randperm(numel(self.trialData));
            else
               
               % Sequential
               self.trialIndices = 1:numel(self.trialData);
            end
            
            % Start the counters
            self.trialCount = 1;
            self.trialIndex = self.trialIndices(self.trialCount);
            
         else
            
            % Save the previous index
            self.previousTrialIndex = self.trialIndex;
            
            % Check for repeat trial
            if nargin > 1 && repeatTrial
               
               % If randomizing, reorder the remaining trialIndices array.
               %     Otherwise do nothing
               if self.randomizeWhenRepeating && ...
                     strcmp(self.trialIterationMethod, 'random')
                  
                  % Get the number of remaining trials (+1 because including
                  % the current trial)
                  numRemainingTrials = length(self.trialIndices) - self.trialCount + 1;
                  
                  % permute the remaining indices
                  inds = self.trialIndices(end-numRemainingTrials+1:end);
                  self.trialIndices(end-numRemainingTrials+1:end) = ...
                     inds(randperm(numRemainingTrials));
                  
                  % Set the new trial index
                  self.trialIndex = self.trialIndices(self.trialCount);
               end
               
            else
               
               % Updating the trial!
               %
               % Increment the trial counter
               self.trialCount = self.trialCount + 1;
               
               % Check for end of trials
               if self.trialCount <= length(self.trialIndices)
                  
                  % update the index
                  self.trialIndex = self.trialIndices(self.trialCount);
               else
                  
                  % Increment iterations
                  self.trialIterationCount = self.trialIterationCount + 1;
                  
                  % Check for end of iterations
                  if self.trialIterationCount > self.trialIterations
                     
                     % Done!
                     self.trialIndex = 0;
                     self.isRunning = false;
                  else
                     
                     % Recompute trialIndices array
                     self.trialIndices = [];
                     self.updateTrial();
                  end
               end
            end
         end
      end
   end
end
