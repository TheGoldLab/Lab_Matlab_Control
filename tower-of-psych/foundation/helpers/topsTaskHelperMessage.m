classdef topsTaskHelperMessage < topsTaskHelper
   % Class topsTaskHelperMessage
   %
   % Add topsTaskHelperMessage, a subclass of topsTaskHelper
   % includes text, image, and sound objects. Should supercede
   % topsTaskHelperFeedback.
   %
   % The text and image objects are held in an ensemble
   % The sound obects are private properties
   
   properties (SetObservable)
      
      % Default duration for showing (in sec)
      defaultDuration = 1.0;
      
      % For drawable object vertical spacing
      defaultSpacing = 3;
   end
   
   properties (SetAccess = private)
      
      % Message groups
      messageGroups=[];
   end
   
   methods
      
      % Constuctor. Arguments are sent to setResources
      %
      function self = topsTaskHelperMessage(name, varargin)
         
         if nargin < 1
            name = 'message';
         end
         
         % Check if name is "groups", then parse as such
         if strcmp(name, 'groups')
            name     = 'message';
            groups   = varargin;
            varargin = {};
         else
            groups = [];
         end
         
         % Call the topsTaskHelper constructor
         self = self@topsTaskHelper(name, [], varargin{:});

         % Add the groups
         if ~isempty(groups)
            self.addGroups(groups{:});
         end
      end
      
      % addGroups
      %
      % message.addGroups('name', <struct>, ...)      
      function addGroups(self, varargin)
         
         for ii = 1:2:nargin-1
            args = struct2args(varargin{ii+1});
            self.addGroup(varargin{ii}, args{:});
         end
      end
      
      % addGroup
      %  message.addGroup(<groupName>, ...
      %  	'text',  {'<string1>', {args1}, '<string2>'}, ...
      %     'drawables',   ...
      %        {{<function handle>, args}, {...}}, ...
      %     'playable', '<filename>', ...
      %     <optional parameter/value pairs>
      %
      % Other optional arguments are property/value pairs used 
      %  by show method:
      %  text       ... add text object(s). Syntax is detailed in parseDrawable.
      %  images     ... add image object(s). Syntax is detailed in parseDrawable.
      %  drawables  ... cell array of drawable specs, each is {<function
      %                    handle>, 'arg1', val1', ...}
      %  playable   ... filename for auditory object
      %  duration   ... in sec
      %  bgStart    ... background color [r g b] to use at start
      %  bgEnd      ... background color [r g b] to use at end
      function addGroup(self, groupName, varargin)
         
         % parse args
         p = inputParser;
         p.addRequired('self');
         p.addRequired('groupName');
         p.addParameter('useExisting', true);
         p.addParameter('text',        {});
         p.addParameter('images',      {});
         p.addParameter('drawables',   {});
         p.addParameter('playable',    {});
         p.addParameter('duration',    self.defaultDuration);
         p.addParameter('pauseAfterDuration', 0);
         p.addParameter('bgStart',     []);
         p.addParameter('bgEnd',       []);
         p.parse(self, groupName, varargin{:});

         % Check for existing
         if p.Results.useExisting && isfield(self.messageGroups, groupName)
            return
         end
         
         % Make the group
         theGroup = struct( ...
            'drawableEnsemble',     [],                           ...
            'textIndices',          [],                           ...
            'playable',             [],                           ...
            'isPrepared',           false,                        ...
            'duration',             p.Results.duration,           ...
            'pauseAfterDuration',   p.Results.pauseAfterDuration, ...
            'bgStart',              p.Results.bgStart,            ...
            'bgEnd',                p.Results.bgEnd);
         
         % Collect drawable specs, are cell arrays
         drawable = p.Results.drawables;
         
         % Add texts
         if ~isempty(p.Results.text)
            drawable = cat(2, drawable, ...
               self.parseDrawable(p.Results.text, @dotsDrawableText, 'string'));
         end

         % Add images
         if ~isempty(p.Results.images)
            drawable = cat(2, drawable, ...
               self.parseDrawable(p.Results.images, @dotsDrawableImages, 'fileNames'));
         end
         
         % Convert drawable specs to a struct to send to makeHelpers
         for ii = 1:length(drawable)
            specs.drawable.(['object_' int2str(ii)]) = struct( ...
               'fevalable', drawable{ii}{1}, ...
               'settings',  {drawable{ii}(2:end)});
         end
         
         % Make a drawable helper from the "drawables" specifications
         theDrawableHelper = topsTaskHelper.makeHelpers('drawable', specs);
                  
         % Get the object and save it in the group's drawable Ensemble
         theGroup.drawableEnsemble = theDrawableHelper.drawable.theObject;
         
         % Get text indices
         theGroup.textIndices = cellfun(@(x) isa(x, 'dotsDrawableText'), ...
            theGroup.drawableEnsemble.objects);
         
         % Add the playable
         if ~isempty(p.Results.playable)
            
            % Make the playableFile object
            theGroup.playable = dotsPlayableFile();
            
            % Set properties
            if ischar(p.Results.playable)
               
               % Only filename given
               theGroup.playable.fileName = p.Results.playable;
               
            elseif iscell(p.Results.playable)
               
               % Filename plus property/value pairs given
               theGroup.playable.fileName = p.Results.playable{1};
               for ii = 2:2:length(p.Results.playable)
                  theGroup.playable.(p.Results.playable{ii}) = ...
                     p.Results.playable{ii+1};
               end
            end
            theGroup.playable.prepareToPlay();
         end
         
         % Add the group
         self.messageGroups.(groupName) = theGroup;
      end
      
      % Remove group
      %
      function removeGroup(self, groupName)
         self.messageGroups = rmfield(self.messageGroups, groupName);
      end
      
      % showMultiple
      %
      %  Set and show multiple messages with text, images, and sounds
      %
      %  text is a cell array of strings
      %  	columns are set to indexed values
      %     rows are shown sequentially
      function showMultiple(self, groupName, text, pauseDuration)
         
         % Loop through each text set
         for ii = 1:size(text, 1)

            % Set the strings
            self.setText(groupName, text(ii,:));
            
            % Show
            self.show(groupName);
            
            % Pause
            if nargin>=4 && pauseDuration > 0
               pause(pauseDuration);
            end
         end
      end
            
      % setText
      %
      % Set text and prepare flag
      %
      function setText(self, groupName, text)

         if nargin >= 3 && ~isempty(text)
            
            % Set all the strings
            for ii = 1:length(text)
               self.messageGroups.(groupName).drawables.setObjectProperty( ...
                  'string', text{ii}, ...
                  self.messageGroups.(groupName).textIndices(ii));
            end
            
            % Need to prepare to draw
            self.messageGroups.(groupName).isPrepared = false;
         end
      end
      
      % showText
      %
      function showText(self, groupName, text, varargin)  
         self.setText(groupName, text);
         self.show(groupName, varargin{:});
      end
      
      % Set and show messages with text, images, and sounds
      %
      % Arguments
      %  groupName      ... string
      %  task           ... the topsTreeNode task caller
      %  eventTag       ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      function show(self, groupName, task, eventTag)         
         
         % Get the message group
         theGroup = self.messageGroups.(groupName);
         
         % Set background
         if ~isempty(theGroup.bgStart)
            dotsTheScreen.blankScreen(theGroup.bgStart);
         end
         
         % Draw the drawable(s)
         if ~isempty(theGroup.drawableEnsemble)
            
            % Possibly prepare to draw
            if ~self.messageGroups.(groupName).isPrepared
               theGroup.drawableEnsemble.setObjectProperty('isVisible', true);
               theGroup.drawableEnsemble.callObjectMethod(@prepareToDrawInWindow);
               self.messageGroups.(groupName).isPrepared = true;
            end
            
            % Draw 
            frameInfo = theGroup.drawableEnsemble.callObjectMethod(...
               @dotsDrawable.drawFrame, {}, [], true);
         end
         
         % Play the playable
         if ~isempty(theGroup.playable)
            theGroup.playable.play();
         end
         
         % Wait
         pause(theGroup.duration);
         
         % Clear screen and possibly re-set background
         dotsTheScreen.blankScreen(theGroup.bgEnd);
         
         % Conditionally store the timing data, with synchronization offset
         if nargin >= 5 && ~isempty(task) && ~isempty(eventTag)
            [offsetTime, referenceTime] = dotsTheScreen.getSyncTimes();
            task.setTrialData([], eventTag, ...
               frameInfo.onsetTime - referenceTime + offsetTime);
         end
         
         % Possibly wait again
         pause(theGroup.pauseAfterDuration);
         
         % Always store the specs in the data log
         topsDataLog.logDataInGroup(groupName, 'showMessage');
      end
   end
   
   methods (Access = protected)

      % Utility to add text, images to the drawables
      %  using simplified syntax; e.g.,
      %    'text',    {'Great!', 'y', 3}
      %    'images',  {'thumbsUp.jpg', 'y', -3}
      function drawables_ = parseDrawable(self, specs, fun, property)
         
         % Parse specs
         if ~iscell(specs)
            
            % Just a string is given, which is the value of the property arg
            % Ex. 'text', 'hello, World!"
            drawables_ = {{fun, property, specs}};
            return
         end
            
         if ~iscellstr(specs) && ischar(specs{1})
            
            % Given as {<value>, 'arg', val, ...}
            % Ex. 'text', {'hello, World!, 'x', 3}
            drawables_ = {[{fun, property}, specs]};
            return
         end
         
         % Parse cell array
         if iscellstr(specs)
            
            % Given as a cell array of strings, treat as list of values
            %  for the property arg
            % Ex. 'text', {'hello, World!, 'Hello again, World!'}
            commonSpecs = {};
            
         elseif iscellstr(specs{1})
            
            % Format: {{<values>}, 'arg', val, ...}
            commonSpecs = specs(2:end);
            specs       = specs{1};
            
         elseif isnumeric(specs{1})
            
            % Format: {<num_objects>, 'arg', val, ...}
            commonSpecs = specs(2:end);
            specs       = cell(specs{1}, 1);
            
         else
            
            % Format:
            %     {{'string1', 'arg1_1', val1_1, ...}, ...
            %      {'string2', 'arg2_1', val2_1, ...}}
            Lcells = cellfun(@iscell, specs);
            commonSpecs = specs(~Lcells);
            specs       = specs(Lcells);            
         end
          
         % Count number of objects
         numObjects  = numel(specs);
         
         % compute default y spacing
         ys = (0:numObjects-1)*self.defaultSpacing;
         ys = -(ys - mean(ys));

         % Make the fevalables
         drawables_ = cell(1, numObjects);
         
         if iscellstr(specs)
            % specs is just list of strings
            for ii = 1:numObjects
               drawables_{ii} = [{fun, property}, specs{ii}, 'y', ys(ii), commonSpecs];
            end
            
         else
            % specs string plus property/value pairs
            for ii = 1:numObjects
               drawables_{ii} = [{fun, property}, specs{ii}(1), 'y', ys(ii), specs{ii}(2:end), commonSpecs];
            end
         end
      end
   end   
end
           