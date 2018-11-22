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
      
      % Default spacing for text (deg visual angle)
      defaultTextSpacing = 4; 
   end   
   
   properties (SetAccess = private)
      
      % Indices in the ensemble of the text objects
      textIndices;
      
      % Indices in the ensemble of the image objects
      imageIndices;

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
         
         % Add images
         if nargin < 1 || isempty(images)
            images = {'thumbsUp.jpg', 12; 'greatJob.jpg', 12; 'Oops.jpg', 12};
         end
         
         % Add sounds
         if nargin < 2 || isempty(sounds)
            sounds = {'correct1.mp3' 'error1.wav'};
         end
         
         % Always add 2 text objects
         args = { ...
            'text1', struct('fevalable', @dotsDrawableText, 'settings', struct('y',  2)), ...
            'text2', struct('fevalable', @dotsDrawableText, 'settings', struct('y', -2))};

         % Add images
         for ii = 1:size(images,1)
            args = cat(2, args, {['image' num2str(ii)], struct( ...
               'fevalable', @dotsDrawableImages)});
         end
         
         % Call the topsTaskHelper constructor
         self = self@topsTaskHelper('feedback', [], args{:}, varargin{:});
         
         % Save the indices
         self.textIndices  = find(cellfun(@(x) isa(x, 'dotsDrawableText'),   self.theObject.objects));
         self.imageIndices = find(cellfun(@(x) isa(x, 'dotsDrawableImages'), self.theObject.objects));
         
         % Create correct/error sound playables
         soundArray = cell(length(sounds),1);
         for ii = 1:length(sounds)
            soundArray{ii} = dotsPlayableFile();
         end
         self.sounds = cat(2, soundArray{:});

         % Set default images and sounds
         self.setResources( ...
            'images',   images, ...
            'sounds',   sounds);
      end
      
      % Utility to set images, sounds
      %
      % Arguments are property/value pairs:
      %  'images', <image file or cell array with <optional> height>
      %  'imageIndex', <scalar index of image to set>
      %  'sounds', <sound file>
      %  'soundIndex', <scalar index of sound to set>
      function setResources(self, varargin)
         
         imageIndex = 1;
         soundIndex = 1;
         for ii = 1:2:nargin-1
            
            property = varargin{ii+1};
            switch(varargin{ii})
               
               case 'images'
                  
                  % Set fileName, <optional> height properties to given values
                  if ischar(property)
                     property = {property};
                  end
                  imageIndex = imageIndex - 1;
                  for jj = 1:length(property)
                     if ischar(property{jj})
                        imageIndex = imageIndex + 1;
                        index = self.imageIndices(imageIndex);
                        self.theObject.setObjectProperty('fileNames', property(jj), index);
                     else
                        self.theObject.setObjectProperty('height', property{jj}, index);
                     end
                  end
                  
                  % Need to prepare to draw
                  self.isPreparedToDraw = false;
                  
               case 'imageIndex'
                  
                  % Which index
                  imageIndex = property;
                  
               case 'sounds'
                  
                  % Set file(s) and prepare to play
                  if ischar(property)
                     property = {property};
                  end
                  for jj = 1:length(property)
                     self.sounds(soundIndex).fileName = property{jj};
                     self.sounds(soundIndex).prepareToPlay();
                     soundIndex = soundIndex + 1;
                  end
                  
               case 'soundIndex'
                  
                  % Which index
                  soundIndex = property;
            end
         end
      end
      
      % Standard feedback with text, image, sound
      %
      % Optional arguments are property/value pairs used by showMessage:
      %  showDuration   ... in sec
      %  blank          ... whether or not to blank screen at the end (default=true)
      %  task           ... the topsTreeNode task caller
      %  eventTag       ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      function showFeedback(self, textStrings, imageIndex, soundIndex, varargin)
         
         % Check args -- if both text and image are given, offset them on
         % the screen. Otherwise center them.
         if nargin < 2
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
         argSets = {p.Results.text, self.textIndices; p.Results.image, self.imageIndices};
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
   end
end