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
      defaultSpacing = 2;
   end
   
   properties (SetAccess = private)
      
      % Message groups
      messageGroups=[];
      
      % Flag, whether or not "prepareToDraw" needs to be called.. may
      % revisit this later
      isPreparedToDraw = false;
   end
   
   methods
      
      % Constuctor. Arguments are sent to setResources
      %
      function self = topsTaskHelperMessage(groupArgs, varargin)
         
         % Call the topsTaskHelper constructor
         self = self@topsTaskHelper('message', [], varargin{:});
         
         % If group args given, add the group
         self.addGroup(groupArgs{:});
      end
      
      % addGroup
      %  message.addGroup(<groupName>, ...
      %  	'texts',  {'<string1>', {args1}, '<string2>'}, ...
      %     'images', {'<filename2>', {args1}, '<filename2>, {args2}}, ...
      %     'drawables',   ...
      %        {{<function handle>, {args}}, ...
      %     'playable', '<filename>', ...
      %     <other args>
      %
      % Other optional arguments are property/value pairs used by showMessage:
      %  duration   ... in sec
      %  hideAll    ... hide all graphics objects
      %  blank      ... whether or not to blank screen at the end (default=true)
      %  task       ... the topsTreeNode task caller
      %  eventTag   ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      function addGroup(self, groupName, varargin)
         
         % parse args
         p = inputParser;
         p.addRequired('self');
         p.addRequired('groupName');
         p.addParameter('useExisting', true);
         p.addParameter('texts',       {});
         p.addParameter('images',      {});
         p.addParameter('drawables',   {});
         p.addParameter('playable',    {});
         p.addParameter('duration',    self.defaultDuration);
         p.addParameter('hideAll',     true);
         p.addParameter('bgStart',     []);
         p.addParameter('bgEnd',       []);
         p.parse(varargin{:});

         % Check for existing
         if p.Results.useExisting && isfield(self.messageGroups, name)
            return
         end
         
         % Make the group
         theGroup = struct( ...
            'ensemble',       dotsDrawable.makeEnsemble(groupName, [], true), ...
            'textIndices',    [],                  ...
            'imageIndices',   [],                  ...
            'sound',          [],                  ...
            'duration',       p.Results.duration,  ...
            'hideAll',        p.Results.hideAll,   ...
            'bgStart',        p.Results.bgStart,   ...
            'bgEnd',          p.Results.bgEnd);
         
         % Collect fevalables, which are handle/argument cell pairs
         fevalables = p.Results.drawables;
         
         % Check for text/image to add to fevalables: 
         % First argument is string (text string or file name)
         % Second (optional) argument is cell array of property/value pairs
         specs = { ...
            'texts',  'string',    'textIndices', @dotsDrawableText; ...
            'images', 'fileNames', 'imageIndices', @dotsDrawableImage};         
         for ss = 1:size(specs, 2)
            
            % Check for arguments
            if ~isempty(p.Results.(specs{ss,1}))

               % Get the cell array of arguments
               argCell = p.Results.(specs{ss,1});
               if ischar(argCell)
                  argCell = {argCell};
               end
               theGroup.(specs{ss,3}) = find(cellfun('ischar', argCell));
               numObjects = length(theGroup.(specs{ss,3}));
               
               % Make y offsets
               ys = (0:numObjects-1).*self.defaultSpacing;
               ys = -(ys - mean(ys));
            
               % Make fevalables
               for ii = 1:numObjects
                  ind  = theGroup.(specs{ss,3})(ii);
                  args = {specs{ss,2}, argCell{ind}, 'isVisible', true};
                  if length(argCell) > ind && ~ischar(argCell{ind+1})
                     args = cat(2, args, argCell{ind+1});
                  end
               end
               
               % Add to the running list
               fevalables = cat(1, fevalables, {specs{ss,4}, args});
            end
         end
         
         % Loop through to make/add/set the drawables ensemble
         for ii = 1:length(fevalables);
            
            % Make the  object
            object = feval(fevalables{ii}{1});
            
            % Add to the ensemble
            index = theGroup.ensemble.addObject(object);
            
            % Set the properties
            if length(fevalables{ii}) > 1
               for jj = 1:2:length(fevalables{ii}{2})
                  theGroup.ensemble.setObjectProperty( ...
                     fevalables{ii}{2}(jj), fevalables{ii}{2}(jj+1), index);
               end
            end
         end
         
         % Prepare to draw
         theGroup.ensemble.callObjectMethod(@prepareToDrawInWindow);
         
         % Add the playable
         if p.Results.playable
            theGroup.playable = dotsPlayableFile();
            theGroup.playable.fileName = p.Results.playable;
            theGroup.playable.prepareToPlay();
         end
         
         % Add the group
         self.messageGroups.(groupName) = theGroup;
      end
      
      % Remove group
      %
      function removeGroup(self, groupName)
         self.messageGroups = rmfield(self.messageGroups groupName);
      end
      
      % Set and show multiple messages with text, images, and sounds
      %
      % strings and images are cell arrays
      %  rows are shown on separate screens
      %  columns are set to indexed values
      function showMultiple(self, groupName, varargin)
         
         % parse args
         p = inputParser;
         p.addRequired('self');
         p.addRequired('groupName');
         p.addParameter('strings',       {});
         p.addParameter('images',        {});
         p.addParameter('sounds',        {});
         p.addParameter('pauseDuration', 0);
         p.parse(varargin{:});
         
         % Get group & ensemble
         theGroup = self.messageGroups.(groupName);
         ensemble = theGroup.ensemble;
         
         % Count multiples
         numRepeats = max([size(p.Results.strings, 1) ...
            size(p.Results.images, 1) size(p.Results.sounds, 1)]);

         for ii = 1:numRepeats
            
            % Flag indicating whether drawables were updated
            prepareFlag = false;
            
            % Texts
            if (size(p.Results.strings, 1) == 1 && ii == 1) || ...
                  (size(p.Results.strings, 1) == numRepeats)
               
               for jj = 1:size(p.Results.strings, 2)
                  ensemble.setObjectProperty('string', ...
                     p.Results.strings{ii,jj}, theGroup.textIndices(jj));
                  prepareFlag = true;
               end
            end
            
            % Images
            if (size(p.Results.images, 1) == 1 && ii == 1) || ...
                  (size(p.Results.images, 1) == numRepeats)
               
               for jj = 1:size(p.Results.images, 2)
                  ensemble.setObjectProperty('fileNames', ...
                     p.Results.images{ii,jj}, theGroup.imageIndices(jj));
                  prepareFlag = true;
               end
            end
            
            % Prepare to draw
            if prepareFlag
               theGroup.ensemble.callObjectMethod(@prepareToDrawInWindow);
            end
            
            % Sounds
            if (size(p.Results.sounds, 1) == 1 && ii == 1) || ...
                  (size(p.Results.sounds, 1) == numRepeats)
               
               theGroup.playable.fileName = p.Results.sounds{ii};
               theGroup.playable.prepareToPlay();
            end

            % Play
            self.show(groupName);
            
            % Pause
            if p.Results.pauseDuration > 0
               pause(p.Results.pauseDuration);
            end
         end
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
         
         % Show the drawables
         if ~isempty(theGroup.ensemble)
                     
         frameInfo = self.theObject.callObjectMethod(...
            @dotsDrawable.drawFrame, {}, [], true);

            
            
            theGroup.ensemble.
         
         % Check for positions
         if ~isempty(p.Results.text) && ~isempty(p.Results.image)
            defaultY = 5;
         else
            defaultY = 0;
         end
         
         % Text args can be:
         %  string
         %  cell array of one or two strings
         %  cell array of cell property/value lists
         if ~isempty(p.Results.text)
            textArgs = p.Results.text;
            if ischar(textArgs)
               textArgs = {{'string', textArgs, 'y', defaultY}, {}};
            elseif iscell(textArgs)
               if ischar(textArgs{1})
                  textArgs{1} = ['string', textArgs(1), 'y', defaultY+2];
               end
               if length(textArgs) == 2 && ischar(textArgs{2})
                  textArgs{2} = ['string', textArgs(2), 'y', defaultY-2];
               end
            end
            for ii = 1:length(textArgs)
               for jj = 1:2:length(textArgs{ii})-1
                  self.theObject.setObjectProperty(textArgs{ii}{jj}, textArgs{ii}{jj+1}, ii);
               end
               if ~isempty(textArgs{ii})
                  self.theObject.setObjectProperty('isVisible', true, ii);
               end
            end
         end
         
         % Image arg can be index or cell array of:
         %  {<index>, <property/value pairs>}
         if ~isempty(p.Results.image)
            imageArgs = p.Results.image;
            if isnumeric(imageArgs)
               imageArgs = {imageArgs, 'y', -defaultY, 'isVisible', true};
            else
               imageArgs = [imageArgs, 'isVisible', true];
            end
            for ii = 2:2:length(imageArgs)-1
               self.theObject.setObjectProperty(imageArgs{ii}, ...
                  imageArgs{ii+1}, self.numText+imageArgs{1});
            end
            self.theObject.callObjectMethod(@prepareToDrawInWindow);
         end
         
         
         % Possibly play sounds
         if ~isempty(p.Results.sound)
            self.sounds(p.Results.sound).play();
         end
         
         % Wait
         pause(p.Results.duration);
         
         % Set background
         if ~isempty(p.Results.backgroundEndColor)
            dotsTheScreen.blankScreen(p.Results.backgroundEndColor);
         end
         
         % Conditionally store the timing data, with synchronization offset
         if ~isempty(p.Results.task) && ~isempty(p.Results.eventTag)
            [offsetTime, referenceTime] = dotsTheScreen.getSyncTimes();
            p.Results.setTrialData([], p.Results.eventTag, ...
               frameInfo.onsetTime - referenceTime + offsetTime);
         end
         
         % Always store the specs in the data log
         topsDataLog.logDataInGroup(varargin, 'feedbackMessage');
      end
   end
end