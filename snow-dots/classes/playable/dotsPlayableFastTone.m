classdef dotsPlayableFastTone < dotsPlayable
   % @class dotsPlayableFastTone
   % Play a pure sinusoudal tone, quickly
   
   properties
      
      % frequency of the sinusoid (Hz)
      frequency;
      
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
      function self = dotsPlayableFastTone()
         self = self@dotsPlayable();
         
         % Initialize
         devices = PsychPortAudio('GetDevices');
         if isempty(devices)
            disp('dotsPlayableFastTone: No devices!')
            return
         end
         
         % Open audio device for low-latency output, using values
         %  suggested in PsychPortAudioTimingTest
         self.player = PsychPortAudio('Open', -1, [], ...
            2, self.sampleFrequency, 2, 0, []);
         
         % Not sure if this does anything
         prelat  = PsychPortAudio('LatencyBias', self.player, 0);
         postlat = PsychPortAudio('LatencyBias', self.player);
      end
      
      % Compute a sinusoidal waveform to play.
      function prepareToPlay(self)
         
         % Compute the waveform
         nCycles = self.frequency * self.duration;
         nSamples = self.sampleFrequency * self.duration;
         waveform = sin(linspace(0, nCycles*2*pi, nSamples))*self.intensity;
         
         % Always use two channels
         if strcmp(self.side,'left')
            self.waveform = [waveform; zeros(size(waveform))];
         elseif strcmp(self.side,'right')
            self.waveform = [zeros(size(waveform)); waveform];
         else
            self.waveform = repmat(waveform, 2, 1);
         end
                     
         % Fill buffer with fake data
         PsychPortAudio('FillBuffer', self.player, zeros(size(self.waveform)));
         
         % Play it to initialize code
         PsychPortAudio('Start', self.player, 1, 0, 1);
         % PsychPortAudio('Stop', self.player, 1);
         
         % Fill buffer with real data
         PsychPortAudio('FillBuffer', self.player, self.waveform);            
      end
      
      % Play the tone.
      function play(self)
                  
         % Play the audio
         PsychPortAudio('Start', self.player, 1, 0, self.waitForStart);
      end
      
      % Stop the tone
      function stopPlaying(self, waitForEndOfPlayback)
         
         if nargin < 2 || isempty(waitForEndOfPlayback)
            waitForEndOfPlayback = 0;
         end
         
         % Stop it!
         PsychPortAudio('Stop', self.player, waitForEndOfPlayback);
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
         playableTone = dotsPlayableFastTone();
         
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
