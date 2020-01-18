classdef dotsPlayableTone < dotsPlayable
   % @class dotsPlayableTone
   % Play a pure sinusoudal tone
   
   properties
      
      % frequency of the sinusoid (Hz)
      frequency;
      
      % Flag to block until sound has actually started playing (if usePTB)
      waitForStart = 1;      
   end
   
   properties (SetAccess = protected)
      
      % The playable: an audioDeviceWriter object
      player;
   end
   
   methods
      
      % Constructor takes no arguments.
      function self = dotsPlayableTone()
         self = self@dotsPlayable();
      end
      
      % Compute a sinusoidal waveform to play.
      function prepareToPlay(self)
         
         % Compute the waveform
         nCycles = self.frequency * self.duration;
         nSamples = self.sampleFrequency * self.duration;
         rads = linspace(0, nCycles*2*pi, nSamples)';
         self.waveform = sin(rads)*self.intensity;
         if strcmp(self.side,'left')
            self.waveform = [self.waveform; zeros(size(self.waveform))];
         elseif strcmp(self.side,'right')
            self.waveform = [zeros(size(self.waveform)); self.waveform];
         else
            self.waveform = repmat(self.waveform, 1, 2);
         end
         
         % Use matlab's built-in audioplayer
         self.player = audioplayer(self.waveform, ...
            self.sampleFrequency, self.bitsPerSample);
      end
      
      
      % Play the tone.
      function play(self)
         
         if isempty(self.player)
            prepareToPlay(self);
         end
         
         play(self.player); % asynchronous
      end
   end
   
   methods (Static)
      
      % Convenient utility for making a tone object
      %
      % args is 3x1 vector of:
      %    frequency (Hz)
      %    duration  (sec)
      %    intensity (normalized)
      function playableTone = makeTone(args)
         
         % Make the object
         playableTone = dotsPlayableTone();
         
         % Set properties, if given
         if nargin >= 1 && ~isempty(args)
            playableTone.frequency = args(1);
            playableTone.duration  = args(2);
            playableTone.intensity = args(3);
         end
         
         % Prepare to play
         playableTone.prepareToPlay();
      end
   end
end
