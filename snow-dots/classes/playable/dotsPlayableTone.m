classdef dotsPlayableTone < dotsPlayable
   % @class dotsPlayableTone
   % Play a pure sinusoudal tone
   
   properties
      
      % frequency of the sinusoid (Hz)
      frequency;
      
      % Test to use PTB PsychPortAudio
      usePTB = true;
      
      % Flag to block until sound has actually started playing (if usePTB)
      waitForStart = 1;
   end
   
   properties (SetAccess = protected)
      
      % The playable: either a Matlab audioplayer object
      %  or PsychPortAudio device
      player;
   end
   
   methods
      % Constructor takes no arguments.
      function self = dotsPlayableTone()
         self = self@dotsPlayable();
         
         % Possibly set up PTB PsychPortAudio player
         if self.usePTB
            
            % Initialize
            devices = PsychPortAudio('GetDevices');

            % Open audio device for low-latency output, using values
            %  suggested in PsychPortAudioTimingTest
            self.player = PsychPortAudio('Open', -1, [], ...
               2, self.sampleFrequency, 2, 0, []);
            
            % Not sure if this does anything
            prelat  = PsychPortAudio('LatencyBias', self.player, 0);
            postlat = PsychPortAudio('LatencyBias', self.player);            
         end
      end
      
      % Compute a sinusoidal waveform to play.
      function prepareToPlay(self)
         
         % Compute the waveform
         nCycles = self.frequency * self.duration;
         nSamples = self.sampleFrequency * self.duration;
         rads = linspace(0, nCycles*2*pi, nSamples);
         self.waveform = sin(rads)*self.intensity;
         if strcmp(self.side,'left')
            self.waveform = [self.waveform; zeros(size(self.waveform))];
         elseif strcmp(self.side,'right')
            self.waveform = [zeros(size(self.waveform)); self.waveform];
         end
         
         % Make the player
         if self.usePTB
            
            if size(self.waveform, 1) == 1
               self.waveform = repmat(self.waveform, 2, 1);
            end
            
            % Fill buffer with fake data
            PsychPortAudio('FillBuffer', self.player, zeros(size(self.waveform)));
            
            % Play it to initialize code
            PsychPortAudio('Start', self.player, 1, 0, 1);
            % PsychPortAudio('Stop', self.player, 1);

            % Fill buffer with real data
            PsychPortAudio('FillBuffer', self.player, self.waveform);
            
         else
            
            % Use matlab's built-in audioplayer
            self.player = audioplayer(self.waveform, ...
               self.sampleFrequency, self.bitsPerSample);
         end
      end
      
      % Play the tone.
      function play(self)
         
         if isempty(self.player)
            prepareToPlay(self);
         end
         
         % Check for player type
         if self.usePTB
            
            % Play the audio
            PsychPortAudio('Start', self.player, 1, 0, self.waitForStart);            
         else
            
            % Check for synchronous/asynchronous
            if self.playBlocking
               playblocking(self.player); % synchronous
            else
               play(self.player); % asynchronous
            end
         end
      end
      
      % Stop the tone
      function stopPlaying(self, waitForEndOfPlayback)
         
         if nargin < 2 || isempty(waitForEndOfPlayback)
            waitForEndOfPlayback = 0;
         end
         
         if self.usePTB            
            PsychPortAudio('Stop', self.player, waitForEndOfPlayback);
         end
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
