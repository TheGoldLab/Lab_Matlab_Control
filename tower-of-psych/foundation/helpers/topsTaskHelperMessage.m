classdef topsTaskHelperMessage < topsTaskHelper
   % Class topsTaskHelperMessage
   %
   % Add topsTaskHelperMessage, a subclass of topsTaskHelper
   % includes text, image, and sound objects. Supercedes
   % topsTaskHelperFeedback.
   %
   % The text and image objects are held in an ensemble
   % The sound obects are private properties
   %
   % 7/16/19 jig revised to account for the possibility that no screen is
   % used. In this case, text drawables can be spoken.
   
   properties (SetObservable)
            
      % Default duration for showing (in sec)
      defaultDuration;
      
      % For drawable object vertical spacing
      defaultSpacing;
   end
   
   properties (SetAccess = private)
      
      % Flag to show drawables, based on whether there is an open screen
      showDrawables;

      % Message groups
      messageGroups=[];
   end
   
   methods
      
      % Constuctor. Arguments are property/value pairs:
      %  'name'            ... string name for this helper
      %  'defaultDuration' ... sets object property
      %  'defaultSpacing'  ... sets object property
      %  <group name>      ... struct of group specs sent to addGroup
      %
      function self = topsTaskHelperMessage(varargin)
         
         % Parse the arguments
         p = inputParser;
         p.StructExpand = false;
         p.KeepUnmatched = true;
         p.addParameter('name',              'message');
         p.addParameter('defaultDuration',   1.0);
         p.addParameter('defaultSpacing',    3.0);
         p.addParameter('groups',            struct());
         p.parse(varargin{:});
         
         % Call the topsTaskHelper constructor
         self = self@topsTaskHelper('name', p.Results.name);
         
         % Check screen
         if dotsTheScreen.isOpen
            self.showDrawables = true;
         else
            self.showDrawables = false;
         end
         
         % Set properties
         self.defaultDuration = p.Results.defaultDuration;
         self.defaultSpacing  = p.Results.defaultSpacing;
      
         % Add the groups
         for ff = fieldnames(p.Unmatched)'
            self.addGroup(ff{:}, p.Unmatched.(ff{:}));
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
         p.addParameter('useExisting',    true);
         p.addParameter('text',           {});
         p.addParameter('images',         {});
         p.addParameter('drawables',      {});
         p.addParameter('playable',       {});
         p.addParameter('duration',       self.defaultDuration);
         p.addParameter('pauseDuration',  0);
         p.addParameter('bgStart',        []);
         p.addParameter('bgEnd',          []);
         p.addParameter('speakText',      false);
         p.parse(self, groupName, varargin{:});

         % Check for existing
         if p.Results.useExisting && isfield(self.messageGroups, groupName)
            return
         end
         
         % Make the group
         theGroup = struct( ...
            'drawableEnsemble',  [],                      ...
            'textIndices',       [],                      ...
            'playable',          [],                      ...
            'isPrepared',        false,                   ...
            'speakText',         p.Results.speakText,     ...
            'duration',          p.Results.duration,      ...
            'pauseDuration',     p.Results.pauseDuration, ...
            'bgStart',           p.Results.bgStart,       ...
            'bgEnd',             p.Results.bgEnd);
         
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
         if ~isempty(drawable)
            
            for ii = 1:length(drawable)
               specs.(groupName).(['object_' int2str(ii)]) = struct( ...
                  'fevalable', drawable{ii}{1}, ...
                  'settings',  {drawable{ii}(2:end)});
            end
            
            % Make a drawable helper from the "drawables" specifications
            theDrawableHelpers = topsTaskHelper.makeHelpers('drawable', specs);
            
            % Get the helper and save it in the group's drawable Ensemble
            theGroup.drawableEnsemble = theDrawableHelpers.(groupName).theObject;
            
            % Get text indices
            theGroup.textIndices = find(cellfun(@(x) isa(x, 'dotsDrawableText'), ...
               theGroup.drawableEnsemble.objects));
         end
         
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
               self.messageGroups.(groupName).drawableEnsemble.setObjectProperty( ...
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
         
         % Draw the drawable(s)
         if self.showDrawables && ~isempty(theGroup.drawableEnsemble)
            
            % Set background
            if ~isempty(theGroup.bgStart)
               dotsTheScreen.blankScreen(theGroup.bgStart);
            end
            
            % Possibly prepare to draw
            if ~theGroup.isPrepared
               theGroup.drawableEnsemble.setObjectProperty('isVisible', true);
               theGroup.drawableEnsemble.callObjectMethod(@prepareToDrawInWindow);
               self.messageGroups.(groupName).isPrepared = true;
            end
            
            % Draw
            frameInfo = theGroup.drawableEnsemble.callObjectMethod(...
               @dotsDrawable.drawFrame, {}, [], true);
         end
         
         % Possibly show/speak the text
         for ii = theGroup.textIndices
            
            % Get the text
            text = theGroup.drawableEnsemble.getObjectProperty('string', ii);

            if ~isempty(text) && ~all(isspace(text))

               % Possibly show the text in the command window if it was not
               % shown on the screen
               if ~self.showDrawables
                  disp(text)
               end
            
               % Possibly speak the text
               if theGroup.speakText
                  system(['say ' text]);
               end
            end
         end
         
         % Play the playable
         if ~isempty(theGroup.playable)
            theGroup.playable.play();
         end

         % End drawing
         if self.showDrawables && ~isempty(theGroup.drawableEnsemble) && ...
               isfinite(theGroup.duration) && theGroup.duration > 0

            % Wait
            pause(theGroup.duration);
         
            % Clear screen and possibly re-set background
            dotsTheScreen.blankScreen(theGroup.bgEnd);
         
            % Conditionally store the synchronized timing data
            if nargin >= 5 && ~isempty(task) && ~isempty(eventTag)
               self.saveSyncronizedTime(frameInfo.onsetTime, true, task, eventTag)
            end
            
         else
            
            % Conditionally store the timing data
            if nargin >= 2 && ~isempty(task) && ~isempty(eventTag)
               task.setTrialData([], eventTag, feval(self.clockFunction));
            end
         end
         
         % Possibly wait again
         pause(theGroup.pauseDuration);
         
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
   
   methods (Static)

      % Show a text message
      %
      % Optional arguments are sent to addGroup (see above)
      function showTextMessage(textToShow, varargin)
         
         % Make the helper
         helper = topsTaskHelperMessage();
         
         % Add the text
         helper.addGroup('text', 'text', textToShow, varargin{:});
         
         % Show it
         helper.show('text');
      end
   end
end