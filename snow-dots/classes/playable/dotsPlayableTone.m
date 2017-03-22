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
            
            self.player = audioplayer(self.waveform, ...
                self.sampleFrequency, self.bitsPerSample);
        end
        
        % Play the tone.
        function play(self)
            if isobject(self.player)
                % play is async, playblocking would be sync
                play(self.player);
            end
        end
    end
end