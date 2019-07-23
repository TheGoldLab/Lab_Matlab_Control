classdef topsTaskHelperTargets < topsTaskHelper
   % Class topsTaskHelperTargets
   %
   % Helper class for showing targets using the monitor (as a
   % dotsDrawableTargets), LEDs (dotsWritableDOutArduinoLEDs), and spoken
   % words (directions)
   %
   
   properties (SetObservable)
      
      % Flag to show drawables
      showDrawables;
      
      % Flag to show LEDs
      showLEDs;
   end
   
   properties (SetAccess = protected)
      
      % dotsWritableDOutArduinoLEDs object used to show LEDs
      LEDObject;
      
      % Array of structs with target specifications -- see constructor for
      % detailsn below
      targetProperties;
   end
   
   methods
      
      % Constuct the helper
      %
      % Optional parameters:
      %  showDrawables   ... used by dotsTheScreen
      %  showLEDs        ... flag
      %  onPlayables     ... struct of playables when target turns on
      %  offPlayables    ... struct of playables when target turns off
      function self = topsTaskHelperTargets(name, varargin)
         
         % Parse the arguments
         p = inputParser;
         p.StructExpand = false;
         p.KeepUnmatched = true;
         p.addRequired( 'name');
         p.addParameter('showDrawables', true);
         p.addParameter('showLEDs',      false);
         p.addParameter('onPlayables',   false);
         p.addParameter('offPlayables',  false);
         p.parse(name, varargin{:});
         
         % Get the remaining optional args
         args = orderParams(p.Unmatched, varargin, true);
         
         % Check name
         if isempty(p.Results.name)
            name = 'targets';
         else
            name = p.Results.name;
         end
         
         % Create it
         self = self@topsTaskHelper(name, [], args{:});
         
         % Set properties
         self.showDrawables = p.Results.showDrawables;
         self.showLEDs      = p.Results.showLEDs;
         
         % Set up LED object
         if self.showLEDs
            self.LEDObject = dotsWritableLEDsArduino();
            self.sync.clockFevalable = {self.LEDObject.clockFunction};
         end
         
         % Check screen
         if ~dotsTheScreen.isOpen
            self.showDrawables = false;
         end
         
         % Get number of drawable targets
         numTargets = length(self.theObject.objects);
         
         % Set up LED functions
         self.targetProperties = struct( ...
            'LEDindex',       cell(numTargets, 1), ...
            'onPlayable',     cell(numTargets, 1), ...
            'offPlayable',    cell(numTargets, 1));
         
         % Set given targets
         for ii = 1:numTargets
            
            % Check if on/off playables were given
            name = self.ensembleObjectNames{ii};
            args = {};
            if isfield(p.Results.onPlayables, name)
               args = cat(2, args, 'onPlayable', p.Results.onPlayables.(name));
            end
            if isfield(p.Results.offPlayables, name)
               args = cat(2, args, 'offPlayable', p.Results.offPlayables.(name));
            end
            
            % Set the target properties
            self.set(ii, args{:});
         end         
      end
      
      %% set
      %
      % Utility for setting target(s) properties
      function set(self, index, varargin)
         
         % ---- Parse the arguments
         %
         p = inputParser;
         p.addRequired( 'indexOrName');
         p.addParameter('anchor',      []);
         p.addParameter('x',           []);
         p.addParameter('y',           []);
         p.addParameter('r',           []);
         p.addParameter('theta',       []);
         p.addParameter('color',       []);
         p.addParameter('onPlayable',  []);
         p.addParameter('offPlayable', []);
         p.parse(index, varargin{:});
         
         % Get index from name(s), if needed
         if ischar(p.Results.indexOrName)
            index = find(strcmp(p.Results.indexOrName, self.ensembleObjectNames));
         else
            index = p.Results.indexOrName;
         end         
         
         % ---- Update ensemble
         %
         % Need to deal with targets and images differently

         if strcmp(self.ensembleObjectClasses{index}, 'dotsDrawableTargets')
         
            % dotsDrawableTarget
            %
            % Set position
            if ~isempty(p.Results.r) && ~isempty(p.Results.theta)
               
               % Get x,y position of "anchor" (object that the given object r, t is
               % plotted with respect to)
               if ~isempty(p.Results.anchor)
                  
                  % Possibly get index from name
                  if ischar(p.Results.anchor)
                     anchor = find(strcmp(p.Results.anchor, self.ensembleObjectNames));
                  else
                     anchor = p.Results.anchor;
                  end
                  anchorX = self.theObject.getObjectProperty('xCenter', anchor);
                  anchorY = self.theObject.getObjectProperty('yCenter', anchor);
               else
                  anchorX = 0;
                  anchorY = 0;
               end
               
               % Set x,y using r,t
               self.theObject.setObjectProperty('xCenter', anchorX + ...
                  p.Results.r * cosd(p.Results.theta), index);
               self.theObject.setObjectProperty('yCenter', anchorY + ...
                  p.Results.r * sind(p.Results.theta), index);
               
            else
               if ~isempty(p.Results.x)               
                  self.theObject.setObjectProperty('xCenter', ...
                     p.Results.x, index);
               end
               if ~isempty(p.Results.y)               
                  self.theObject.setObjectProperty('yCenter', ...
                     p.Results.y, index);
               end
            end
         
            % Get x, y position
            x = self.theObject.getObjectProperty('xCenter', index);
            y = self.theObject.getObjectProperty('yCenter', index);
            
         elseif strcmp(self.ensembleObjectClasses{index}, 'dotsDrawableImages')

            % dotsDrawableImages
            %
            % Set position
            if ~isempty(p.Results.x)
               self.theObject.setObjectProperty('x', p.Results.x, index);
            end
            if ~isempty(p.Results.y)
               self.theObject.setObjectProperty('y', p.Results.y, index);
            end
            
            % Get x, y position
            x = self.theObject.getObjectProperty('x', index);
            y = self.theObject.getObjectProperty('y', index);
         end
         
         % ---- Set LED show/hide functions
         %
         % Which LED?
         targetAngle = ang([x y]);
         if ~isfinite(targetAngle)
            self.targetProperties(index).LEDindex       = 3; % CENTER
            self.targetProperties(index).spokenLocation = '';
         elseif targetAngle <= 45 || targetAngle > 315
            self.targetProperties(index).LEDindex       = 1; % RIGHT
            self.targetProperties(index).spokenLocation = 'right';
         elseif targetAngle > 45 && targetAngle <= 135
            self.targetProperties(index).LEDindex       = 2; % TOP
            self.targetProperties(index).spokenLocation = 'up';
         elseif targetAngle > 135 && targetAngle <= 225
            self.targetProperties(index).LEDindex       = 4; % LEFT
            self.targetProperties(index).spokenLocation = 'left';
         else %if targetAngle > 225 || targetAngle <= 315
            self.targetProperties(index).LEDindex       = 5; % BOTTOM
            self.targetProperties(index).spokenLocation = 'down';
         end
         
         % ---- Set color
         %
         % Drawable color
         if ~isempty(p.Results.color)            
            self.theObject.setObjectProperty('colors', colorRGB(p.Results.color), index);
         end
         
         % LED color
         self.LEDObject.set(self.targetProperties(index).LEDindex, ...
            self.theObject.getObjectProperty('colors', index));
                  
         % Playable settings
         for playable = {'onPlayable', 'offPlayable'}
            
            % Check playable argument
            if ~isempty(p.Results.(playable{:}))
               if isnumeric(p.Results.(playable{:}))
                  
                  % Play a tone
                  thePlayable = dotsPlayableTone.makeTone(p.Results.(playable{:}));
                  self.targetProperties(index).(playable{:}) = {@play, thePlayable};
                  
               elseif strcmp(p.Results.(playable{:}), 'location')
                  
                  % Say location
                  self.targetProperties(index).(playable{:}) = 'location';
               
               elseif strcmp(p.Results.(playable{:}), 'none')
                  
                  % Nothing
                  self.targetProperties(index).(playable{:}) = {};
               end
            end
         end
      end
      
      %% show
      %
      % Utility for showing target(s)
      %
      % indices is cell array of {<array of on indices> <array of off
      %              indices>}
      % task is pointer to task object ... used to save trial data
      % eventTag is string ... used to save trial data
      function show(self, indices, task, eventTag)
         
         % Use dotsDrawable.drawEnsemble to do the work.
         if self.showDrawables
            
            % Use drawEnsemble to do the work
            frameInfo = dotsDrawable.drawEnsemble(self.theObject, indices);
            
            % Store the timing data
            if nargin >=4 && ~isempty(task) && ~isempty(eventTag)
               [offsetTime, referenceTime] = dotsTheScreen.getSyncTimes();
               task.setTrialData([], eventTag, frameInfo.onsetTime - ...
                  referenceTime + offsetTime);
            end
         end
         
         % Toggle LEDs
         if self.showLEDs
            
            % Use toggleLEDs to do the work
            timestamp = self.LEDObject.toggleLEDs({ ...
               [self.targetProperties(indices{1}).LEDindex], ...
               [self.targetProperties(indices{2}).LEDindex]});
            
            % NOTE THAT THIS WILL OVERWRITE DRAWABLE TIMING - change if you
            % don't want this behavior
            if nargin >=4 && ~isempty(task) && ~isempty(eventTag)
               task.setTrialData([], eventTag, timestamp - ...
                   self.sync.results.referenceTime + self.sync.results.offset);
            end
         end
         
         % Onset playables
         for ii = indices{1}
            if ~isempty(self.targetProperties(ii).onPlayable) 
               if iscell(self.targetProperties(ii).onPlayable)
                  feval(self.targetProperties(ii).onPlayable{:});
               elseif ischar(self.targetProperties(ii).onPlayable) && ...
                     ~isempty(self.targetProperties(ii).spokenLocation)
                  system(['say ' self.targetProperties(ii).spokenLocation]);
               end
            end
         end
         
         % Offset playables
         for ii = indices{2}
            if ~isempty(self.targetProperties(ii).offPlayable) 
               if iscell(self.targetProperties(ii).offPlayable)
                  feval(self.targetProperties(ii).offPlayable{:});
               elseif ischar(self.targetProperties(ii).offPlayable) && ...
                     ~isempty(self.targetProperties(ii).spokenLocation)
                  system(['say ' self.targetProperties(ii).spokenLocation]);
               end
            end
         end
      end
      
      %% blank
      %
      function blank(self)
         
         % Blank the screen
         if self.showDrawables
            dotsTheScreen.blankScreen([0 0 0]);
         end
         
         % Blank the LEDs
         if self.showLEDs
            self.LEDObject.blankLEDs();
         end
      end
   end
end