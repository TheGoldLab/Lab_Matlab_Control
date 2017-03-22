classdef dotsPlayable < handle
    % @class dotsPlayable
    % Superclass for objects that play sounds and are managed by
    % dotsThePlayablesManager.  dotsThePlayablesManager should expect to be
    % able to use any of the dotsPlayable properties or methods for its
    % managed objects.
    properties
        % true or false, whether this object should play() sonds
        isAudible = true;
        
        % scale factor to apply to waveform during playback
        intensity = 1;
        
        % frequency in Hz of sound samples stored in waveform
        sampleFrequency = 44100;
        
        % bit-depth of each sound sample in waveform
        bitsPerSample = 16;
        
        % duration of the sound to play (may be set automatically)
        duration;
        
        % system path to locate sound files
        soundsPath;
        
        % mXn double matrix of sound samples (arbitrary units, 0-1)
        % @details
        % m is the number of audio channels, 1 for mono and 2 for stereo.
        % n is the number of sound samples (i.e. the length of the sound).
        waveform;
    end
    
    properties (SetAccess = protected)
        % timestamp from the last time this object was play()ed
        lastPlayTime;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsPlayable()
            mc = dotsTheMachineConfiguration.theObject();
            mc.applyClassDefaults(self, mc.defaultGroup);
        end
        
        % play() or not, depending on isAudible and possibly other factors.
        function mayPlayNow(self)
            if self.isAudible
                self.play();
            end
        end
        
        % Do any pre-play setup.
        function prepareToPlay(self)
        end
        
        % Subclass must redefine play() to play a sound.
        function play(self)
        end
        
        % Shorthand to set isAudible=true.
        function unMute(self)
            self.isAudible = true;
        end
        
        % Shorthand to set isAudible=false.
        function mute(self)
            self.isAudible = false;
        end
    end
end