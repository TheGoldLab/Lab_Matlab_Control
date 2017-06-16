classdef dotsPlayableFile < dotsPlayable
    % @class dotsPlayableFile
    % Play a sound from a .wav or .mp3 file.
    properties
        % string file name of a .wav or .mp3 file to play
        fileName = '';
        
        % whether to play synchonously (true) or asynchronously
        % @details
        % Be warned that using isBlocking = false can lead to errors
        % because Matlab's audioplayer class is limited.
        isBlocking = true;
    end
    
    properties (SetAccess = protected)
        % Matlab audioplayer object
        player;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsPlayableFile()
            self = self@dotsPlayable();
        end
        
        % Read audio data from the the sound file.
        function prepareToPlay(self)
            
            % resolve the correct sound file
            fileWithPath = fullfile(self.soundsPath, self.fileName);
            soundFile = '';
            if exist(fileWithPath, 'file')
                % found file with explicit path
                soundFile = fileWithPath;
                
            else
                % look for any file on Matlab's search path
                anyFile = which(self.fileName);
                if exist(anyFile, 'file')
                    soundFile = anyFile;
                else
                    message = sprintf('No file %s or %s found', ...
                        fileWithPath, self.fileName);
                    ID = sprintf('%s:fileNotFound', mfilename());
                    warning(ID, message);
                end
            end
            
            % get waveform and properties of .wav or .mp3 files
            [filePath, fileName, fileType] = fileparts(soundFile);
            if strcmp(fileType, '.wav')
                % MATLAB's builtin .wav reader
                [self.waveform, self.sampleFrequency] = audioread(soundFile);
                self.bitsPerSample = getfield(audioinfo(soundFile), 'BitsPerSample');
                
            elseif strcmp(sfileType, '.mp3')
                if exist('mp3read', 'file')
                    [self.waveform, self.sampleFrequency, self.bitsPerSample] = ...
                        mp3read(soundFile);
                else
                    warning('%s: cannot read .mp3 files', mfilename)
                    disp(sprintf('please download the mp3read function: \n%s', ...
                        'http://www.mathworks.com/matlabcentral/fileexchange/13852-mp3read-and-mp3write'))
                end
                
            else
                message = sprintf('%s should be a .wav or.mp3 file.', ...
                    soundFile);
                ID = sprintf('%s:unknownFileType', mfilename());
                warning(ID, message);
            end
            
            self.duration = length(self.waveform) ./ self.sampleFrequency;
            
            if isobject(self.player)
                self.player.stop();
                self.player = [];
            end
            
            self.player = audioplayer(self.waveform.*self.intensity, ...
                self.sampleFrequency, self.bitsPerSample);
        end
        
        % Play from the sound file.
        function play(self)
            if isobject(self.player)
                if self.isBlocking
                    self.player.playblocking();
                else
                    % asynchronous playing doesn't work well
                    self.player.play();
                end
            end
        end
    end
end