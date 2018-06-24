classdef dotsPlayableTone < dotsPlayable
    % @class dotsPlayableTone
    % Play a pure sinusoudal tone
    
    properties
        % frequency of the sinusoid (Hz)
        frequency;
    end
    
    properties (SetAccess = protected)
        % Matlab audioplayer object
        player;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsPlayableTone()
            self = self@dotsPlayable();
        end
        
        % Compute a sinusoidal wavform to play.
        function prepareToPlay(self)
            nCycles = self.frequency * self.duration;
            nSamples = self.sampleFrequency * self.duration;
            rads = linspace(0, nCycles*2*pi, nSamples);
            self.waveform = sin(rads)*self.intensity;
            if strcmp(self.side,'left')
               self.waveform = [self.waveform; zeros(size(self.waveform))];
            elseif strcmp(self.side,'right')
               self.waveform = [zeros(size(self.waveform)); self.waveform];
            end
            self.player = audioplayer(self.waveform, ...
               self.sampleFrequency, self.bitsPerSample);
        end
        
        % Play the tone.
        function play(self)
           
           if isempty(self.player)
              prepareToPlay(self);
           end
           
           % Check for synchronous/asynchronous
           if self.playBlocking
              playblocking(self.player); % synchronous
           else
              play(self.player); % asynchronous
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
       function playableTone = makePlayableTone(args)
          
          playableTone           = dotsPlayableTone();
          playableTone.frequency = args(1);
          playableTone.duration  = args(2);
          playableTone.intensity = args(3);
          
          playableTone.prepareToPlay();
       end
    end
end
