function s_ = set(s_, varargin)
%set method for class dXsound: specify property values and recompute dependencies
%   s_ = set(s_, varargin)
%
%   All DotsX classes have set methods which allow properties for one or
%   more instances to be specified, and dependent values recomputed.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% sets properties of a dXsound object
%----------Special comments-----------------------------------------------
%
%   See also set dXsound

% Copyright 2008 by Benjamin Heasly
%   University of Pennsylvania

% set the fields, one at a time.. no error checking
for ii = 1:2:nargin-1

    % change it
    if iscell(varargin{ii+1}) && ~isempty(varargin{ii+1})
        [s_.(varargin{ii})] = deal(varargin{ii+1}{:});
    else
        [s_.(varargin{ii})] = deal(varargin{ii+1});
    end
end

% put the raw waveform format to be played
%   calculate duration for convenience
for ii = 1:length(s_)

    if s_(ii).mute

        % no sound at all
        s_(ii).sound = [0,0];

    elseif ischar(s_(ii).rawSound) && exist(s_(ii).rawSound) == 2

        % locate the file with path
        [p, n, e] = fileparts(s_(ii).rawSound);
        if isempty(p)
            raw = which(s_(ii).rawSound);
        else
            raw = s_(ii).rawSound;
        end

        % get waveform and properties of .wav or .mp3 files
        if strcmp(e, '.wav')

            % MATLAB's builtin .wav reader
            [s_(ii).sound, s_(ii).sampleFrequency, s_(ii).bitrate] = ...
                wavread(raw);

        elseif strcmp(e, '.mp3')

            % mp3read function in DotsX/mex
            % BSH downloaded 2 May 2008 from MATLAB Central File Exchange:
            % http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=13852&objectType=file
            [s_(ii).sound, s_(ii).sampleFrequency, s_(ii).bitrate] = ...
                mp3read(raw);

        else

            disp(sprintf('dXsound(%d): is %s a .wav or .mp3 file?', ...
                ii, s_(ii).rawSound));
        end

    else

        % waveform as an array
        s_(ii).sound = s_(ii).rawSound;
    end

    % calculate duration for convenience
    s_(ii).duration = size(s_(ii).sound, 1) ./ s_(ii).sampleFrequency;
end