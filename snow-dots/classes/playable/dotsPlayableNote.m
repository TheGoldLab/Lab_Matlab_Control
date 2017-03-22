classdef dotsPlayableNote < dotsPlayable
    %by M.Kabir (kabir.naim@gmail.com), using superclass by Ben Heasly
    %and amplitude-envelope concept by Chris Glaze
    
    properties
        % frequency of the sinusoid (Hz)
        frequency;
        
        waitTime = 0;
        
        ampenv;
        
        noise = 0;
    end
    
    properties (SetAccess = protected)
        % Psychtoolbox audioplayer object
        player;
    end
    
     methods
        % Constructor takes no arguments.
        function self = dotsPlayableNote()
            self = self@dotsPlayable();
            InitializePsychSound
            self.player = PsychPortAudio('Open', [], [], 0, self.sampleFrequency, 2);
        end
        
        % Compute a waveform to play.
        function prepareToPlay(self)
            N = ceil(self.sampleFrequency * self.duration);
            
            dt = 1/self.sampleFrequency; %gives time duration of one element of our array
            array = (1:N)*dt; %translate elementwise array into a time stamp array
            
            %Setting 'pluck' amplitude envelope if no presepecified ampenv
            if isempty(self.ampenv)
                ampenv = exp(-array/(self.duration/10))-exp(-array/(self.duration/20));
                ampenv = ampenv/max(ampenv); %Normalize
            else
                ampenv = self.ampenv;
            end
            
             %Find cutoff point to cut off sound signal, in case it trails off or something
            fraction = 1; %to cutoff, make this go below 1
            cutoff = ceil(length(array)*fraction);
            note = sin(2*pi*self.frequency*array(1:cutoff));
            
            if self.noise > 0
                note = note + ((randn(1,length(note))-0.5)*self.noise);
            end
            
            note = note.*ampenv(1:cutoff); %creating sound with specific frequency
            note = [note; note];
            note = note*self.intensity;
            
            self.waveform = note;
        end
        
        % Play the waveform.
        function play(self)
            if ~isempty(self.waveform)
                % play is async, playblocking would be sync
                PsychPortAudio('FillBuffer', self.player, self.waveform);
                self.lastPlayTime = PsychPortAudio('Start', self.player, 1, GetSecs + self.waitTime, 1, inf, 0);
            end
        end
        
        %Stop the waveform
        function stop(self)
            PsychPortAudio('Stop', self.player)
        end
        
     end
    
end


    
    
   
    
    