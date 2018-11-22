classdef topsTaskHelperFeedback < topsTaskHelper
   % Class topsTaskHelperFeedback
   %
   % Add topsTaskHelperFeedback, a subclass of topsTaskHelper
   % includes text, image, and sound objects
   %
   % The text and image objects are held in an ensemble
   % The sound obects are private properties
   
   properties (SetObservable)
      
      % Default duration for showing (in sec)
      defaultDuration = 1.0;
      
      % For text spacing
      defaultTextSpacing = 4;
   end   
   
   properties (SetAccess = private)
      
      % Indices in the ensemble of the text objects
      numText=2;
      
      % Indices in the ensemble of the image objects
      numImages=0;

      % The sound objects
      sounds;         
      
      % Flag, whether or not "prepareToDraw" needs to be called.. may
      % revisit this later
      isPreparedToDraw = false;
   end
   
   methods
      
      % Constuctor. Arguments are sent to setResources
      %
      function self = topsTaskHelperFeedback(images, sounds, varargin)
         
         % Call the topsTaskHelper constructor with 2 text objects
         self = self@topsTaskHelper('feedback', [], varargin{:}, ...
            'text1', struct('fevalable', @dotsDrawableText, 'settings', struct('y',  2)), ...
            'text2', struct('fevalable', @dotsDrawableText, 'settings', struct('y', -2)));
            
         % Add images
         if nargin < 1 || isempty(images)
            images = {'thumbsUp.jpg', 12; 'greatJob.jpg', 12; 'Oops.jpg', 12};
         end
         self.setImages(images);
         
         % Add sounds
         if nargin < 2 || isempty(sounds)
            sounds = {'correct1.mp3' 'error1.wav'};
         end
         self.setSounds(sounds);         
      end
      
      % Set images
      %
      % Images is cell array
      %  columns are:
      %     1. filename
      %     2. default height or cell array of property/value pairs
      function setImages(self, images)
      
         % Remove existing images
         for ii = 1:self.numImages
            self.theObject.removeObject(self.numText + ii);
         end
         
         % Add new images
         for ii = 1:size(images,1)
            
            % Get the image
            self.theObject.addObject(dotsDrawableImages());
            
            % Set the image
            self.theObject.setObjectProperty('fileNames', images(ii,1), ...
               self.numText + ii);
            
            % Check for args
            if size(images,2) == 2
               
               if ischar(images{ii,2})

                  % height given
                  self.theObject.setObjectProperty('height', images{ii,2}, ...
                     self.numText + ii);
               
               elseif iscell(images{ii,2})
                  
                  % cell array of args
                  for jj = 1:2:length(images{ii,2})
                     self.theObject.setObjectProperty(images{ii,2}{jj}, ...
                        images{ii,2}{jj+1}, self.numText + ii);
                  end
               end
            end
         end
      end
            
      % Set sounds
      %
      % Images is cell array of sound file names
      function setSounds(self, sounds)
         
         if isempty(sounds)
            
            % Blank
            self.sounds = [];

         else
            % Set new
            soundArray = cell(length(sounds),1);
            for ii = 1:length(sounds)
               playable = dotsPlayableFile();
               playable.fileName = sounds{ii};
               playable.prepareToPlay();
               soundArray{ii} = playable;
            end
            self.sounds = cat(2, soundArray{:});
         end
      end

      % Standard feedback with text, image, sound
      %
      % Arguments:
      %  textArgs       ... 
      %  imageArgs      ... for now can just show one image
      %  soundIndex     ... play one sound
      % Optional arguments are property/value pairs used by showMessage:
      %  showDuration   ... in sec
      %  blank          ... whether or not to blank screen at the end (default=true)
      %  task           ... the topsTreeNode task caller
      %  eventTag       ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      function showFeedback(self, textArgs, imageArgs, soundIndex, varargin)
         
         % Check args -- if both text and image are given, offset them on
         % the screen. Otherwise center them.
         if nargin < 2
            return
         end
         if nargin < 3
            imageIndex = [];
         end
         
         if ~isemty(te
         
         if ~isempty(textStrings)
            
            textStrings = {};
         end
         if nargin < 3
            imageIndex = [];
         end
         
         % Check if we are showing both
         if ~isempty(textStrings) && ~isempty(imageIndex)
            imageY = -5;
            textY  = 5;
         else
            imageY = 0;
            textY  = 0;
         end
         
         % Get text args
         textArgs = cell(1,2);
         if ~isempty(textStrings)
            if ischar(textStrings)
               textArgs{1} = {'string', textStrings, 'y', textY};
            elseif length(textStrings) == 1
               textArgs{1} = {'string', textStrings{1}, 'y', textY};
            else
               textArgs{1} = {'string', textStrings{1}, 'y', textY+2};
               textArgs{2} = {'string', textStrings{2}, 'y', textY-2};
            end   
         end
         
         % get image args
         imageArgs = {};
         if ~isempty(imageIndex)
            imageArgs = cell(1,imageIndex);
            imageArgs{end} = {'y', imageY};
         end
         
         % Setup sound
         if nargin < 4
            soundIndex = [];
         end
         
         self.showMessage('text', textArgs, 'image', imageArgs, ...
            'sound', soundIndex, varargin{:});
      end
      
      % showText
      %
      % Utility to show text using the textEnsemble or command window. If
      % task and eventTag arguments are given, the synchronized timestamp
      % is stored in the current trial. Remember that
      %  syncronization is done by the screenEnsemble helper, which stores 
      %  the result in the dotsTheScreen singleton object so everyone else
      %  can access it.
      %
      % Arguments:
      %  textStrings       ... cell array of strings to show
      %  useDefaultSpacing ... flag
      %
      % Optional property/value pairs send to showMessage:
      %  showDuration      ... in sec
      %  blank             ... whether or not to blank screen at the end (default=true)
      %  task              ... the topsTreeNode task caller
      %  eventTag          ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      function showText(self, textStrings, useDefaultSpacing, varargin)
         
         % Check args
         if nargin < 2 || isempty(textStrings)
            return
         end
         
         if nargin < 3 || isempty(useDefaultSpacing)
            useDefaultSpacing = true;
         end
         
         % Package the text strings into arguemnts used by showMessge
         if ischar(textStrings)
            textStrings = {textStrings};
         end
         numStrings = length(textStrings);
         textArgs   = cell(1, numStrings);

         % Set up spacing
         if useDefaultSpacing
            ys = (0:self.defaultTextSpacing:self.defaultTextSpacing*(numStrings-1));
            ys = mean(ys) - ys;
         end
         
         for ii = 1:numStrings
            if useDefaultSpacing
               textArgs{ii} = {'string', textStrings{ii}, 'y', ys(ii)};
            else
               textArgs{ii} = {'string', textStrings{ii}};
            end
         end
         
         % Call showMessage to do the work
         self.showMessage('text', textArgs, varargin{:});
      end
      
      % Set and show multiple messages with text, images, and sounds
      %
      function showMultipleMessages(self, varargin)
         
         % parse args
         p = inputParser;
         p.KeepUnmatched = true;
         p.addParameter('text',          {});
         p.addParameter('image',         {});
         p.addParameter('pauseDuration', 0);        
         p.parse(varargin{:});
         
         % collect unmatched args
         unmatched = struct2args(p.Unmatched);
         
         % multiple messages are given in rows of images/text
         for mm = 1:max([size(p.Results.text,1), size(p.Results.image,1)])
            
            % Call showMessage to do the work with the current text/image args
            self.showMessage( ...
               'text',  p.Results.text(min(mm, size(p.Results.text,1)),:), ...
               'image', p.Results.image(min(mm, size(p.Results.image,1)),:), ...
               unmatched{:});
            
            % Possibly wait
            pause(p.Results.pauseDuration);
         end
      end      
      
      % Set and show messages with text, images, and sounds
      %
      % Example:
      %  feedback.showMessage( ...
      %  	'text',  {{'string', 'hello World!'} {'string', 'another world'}}, ...
      %     'image', {'fileName', 'goodJob.jpg', 'y', 1, 'height', 13}, ...
      %     'sound', [<index to play>], 
      %     'duration', 1.0);
      %     'blank', true
      %
      % Other optional arguments are property/value pairs used by showMessage:
      %  showDuration   ... in sec
      %  blank          ... whether or not to blank screen at the end (default=true)
      %  task           ... the topsTreeNode task caller
      %  eventTag       ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      function showMessage(self, varargin)
         
         % parse args
         p = inputParser;
         p.KeepUnmatched = true;
         p.addParameter('text',          {});
         p.addParameter('image',         {});
         p.addParameter('sound',         {});
         p.addParameter('showDuration',  self.defaultDuration);
         p.addParameter('blank',         true);
         p.addParameter('task',          []);
         p.addParameter('eventTag',      []);
         p.parse(varargin{:});

         % Set values for text, images
         % First hide everything
         self.theObject.setObjectProperty('isVisible', false);
         
         % If tag 'show' or properties are given, show it
         argSets = {p.Results.text, 1:self.numText; p.Results.image, self.numText+(1:self.numImages)};
         for ii = 1:2
            
            args = argSets{ii, 1};
            inds = argSets{ii, 2};
            
            if isempty(args)
               args = cell(length(inds), 1);
            else
               if ~iscell(args{1}) && ~isempty(args{1}) && ~(ischar(args{1}) && strcmp(args{1}, 'show'))
                  args = {args};
               end
               [args{end+1:length(inds)}] = deal({});
            end
            
            for aa = 1:length(args)
               if ~isempty(args{aa})
                  if ischar(args{aa})
                     theseArgs = {'isVisible', true};
                  else
                     theseArgs = cat(2, args{aa}, {'isVisible', true});
                     if ii == 2
                        % Set flag here, in case args given to images
                        self.isPreparedToDraw = false;
                     end
                  end
                  for jj = 1:2:length(theseArgs)
                     self.theObject.setObjectProperty(theseArgs{jj}, theseArgs{jj+1}, inds(aa));
                  end
               end
            end
         end

         % Call prepare to draw, if necessary, and reset
         if ~self.isPreparedToDraw
            self.theObject.callObjectMethod(@prepareToDrawInWindow);
         	self.isPreparedToDraw = true;
         end

         % Draw 'em, getting back timestamps
         frameInfo = self.theObject.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
         
         % Possibly play sounds
         if ~isempty(p.Results.sound)
            self.sounds(p.Results.sound).play();
         end
         
         % Wait
         pause(p.Results.showDuration);
         
         % Blank the screen
         if p.Results.blank
            dotsTheScreen.blankScreen();
         end
         
         % Conditionally store the timing data, with synchronization offset
         if ~isempty(p.Results.task) && ~isempty(p.Results.eventTag)
            p.Results.task.setTrialTime([], p.Results.eventTag, ...
               frameInfo.onsetTime + dotsTheScreen.getOffsetTime() - ...
               self.sync.results.referenceTime);
         end
         
         % Always store the specs in the data log
         topsDataLog.logDataInGroup(varargin, 'feedbackMessage');
      end
      
      
      
        % Set and show messages with text, images, and sounds
      %
      % Example:
      %  feedback.showMessage( ...
      %  	'text',  {{'string', 'hello World!'} {'string', 'another world'}}, ...
      %     'image', {'fileName', 'goodJob.jpg', 'y', 1, 'height', 13}, ...
      %     'sound', [<index to play>], 
      %     'duration', 1.0);
      %     'blank', true
      %
      % Other optional arguments are property/value pairs used by showMessage:
      %  showDuration   ... in sec
      %  blank          ... whether or not to blank screen at the end (default=true)
      %  task           ... the topsTreeNode task caller
      %  eventTag       ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      function show(self, textArgs, imageArgs, sounds, varargin)
         
         % parse args
         p = inputParser;
         p.addParameter('text',          {});
         p.addParameter('image',         {});
         p.addParameter('sound',         {});
         p.addParameter('showDuration',  self.defaultDuration);
         p.addParameter('clearAll',      true);
         p.addParameter('blank',         true);
         p.addParameter('task',          []);
         p.addParameter('eventTag',      []);
         p.parse(self, textArgs, imageArgs, sounds, varargin{:});
         
         % First hide everything
         if p.Results.clearAll
            self.theObject.setObjectProperty('isVisible', false);
         end
         
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
            end
         end
         
         % Image arg can be index or cell array of:
         %  {<index>, <property/value pairs>}
         if ~isempty(p.Results.image)
            imageArgs = p.results.image;
            if isnumeric(imageArgs)
               imageArgs = {imageArgs, 'isVisible', true, 'y', -defaultY};
            end
            for ii = 2:2:length(imageArgs)-1
               self.theObject.setObjectProperty(imageArgs{ii}, ...
                  imageArgs{ii+1}, self.numText+imageArgs{1});
            end
            self.theObject.callObjectMethod(@prepareToDrawInWindow);
         end

         % Draw 'em, getting back timestamps
         frameInfo = self.theObject.callObjectMethod(...
            @dotsDrawable.drawFrame, {}, [], true);
         
         % Possibly play sounds
         if ~isempty(p.Results.sound)
            self.sounds(p.Results.sound).play();
         end
         
         % Wait
         pause(p.Results.showDuration);
         
         % Blank the screen
         if p.Results.blank
            dotsTheScreen.blankScreen();
         end
         
         % Conditionally store the timing data, with synchronization offset
         if ~isempty(p.Results.task) && ~isempty(p.Results.eventTag)
            p.Results.task.setTrialTime([], p.Results.eventTag, ...
               frameInfo.onsetTime + dotsTheScreen.getOffsetTime() - ...
               self.sync.results.referenceTime);
         end
         
         % Always store the specs in the data log
         topsDataLog.logDataInGroup(varargin, 'feedbackMessage');
      end
   end
end