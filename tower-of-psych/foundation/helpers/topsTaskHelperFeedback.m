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
      
      % 
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
            images = {'thumbsUp.jpg', 12; 'greatJob.jpg', 12; 'Oops.jpg', 12; 'goFast.jpg', 12};
         end
         self.setImages(images);
         
         % Add sounds
         if nargin < 2 || isempty(sounds)
            sounds = {'correct1.mp3' 'error1.wav' 'cashRegister.wav' 'buzzer.wav'};
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

      % Set and show multiple messages with text, images, and sounds
      %
      function showMultiple(self, varargin)
         
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
            self.show( ...
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
      %  hideAll        ... hide all graphics objects
      %  blank          ... whether or not to blank screen at the end (default=true)
      %  task           ... the topsTreeNode task caller
      %  eventTag       ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      function show(self, varargin)
         
         % parse args
         p = inputParser;
         p.addRequired('self');
         p.addParameter('text',       {});
         p.addParameter('image',      {});
         p.addParameter('sound',      {});
         p.addParameter('duration',   self.defaultDuration);
         p.addParameter('hideAll',    true);
         p.addParameter('bgStart',    []);
         p.addParameter('bgEnd',      []);
         p.addParameter('task',       []);
         p.addParameter('eventTag',   []);
         p.parse(self, varargin{:});
         
         % First hide everything
         if p.Results.hideAll
            self.theObject.setObjectProperty('isVisible', false);
         end

         % Set background
         if ~isempty(p.Results.backgroundStartColor)
            dotsTheScreen.blankScreen(p.Results.backgroundStartColor);
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

         % Draw 'em, getting back timestamps
         frameInfo = self.theObject.callObjectMethod(...
            @dotsDrawable.drawFrame, {}, [], true);
         
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