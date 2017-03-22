% Build the Snow Dots c-language extensions to the mgl project.
% @param rebuild logical, whether to rebuild all mex functions, or only
% build recently modified mexfunctions
% @param varargin optional, arbitrary command line options
% @details
% Builds C-language mex functions which are Snow Dots extensions to the mgl
% project.  These functions deal mostly with OpenGL graphics.  If @a
% rebuild is false (the default) only rebuilds functions whose source code
% has been modified since the last build.  If @a rebuild is true, rebuilds
% all of the mex functions in the mex/dotsMgl/ folder.
% @details
% Builds using mex(), which is Matlab's built in compiler and linker.  You
% can pass arbitrary command line options to mex() after the @a rebuild
% argument.  If @a rebuild is a string, it will also be treated  as a
% command line option.  Command line options must begin with a '-'.
% @details
% dotsMglMake.m is copyright (c) 2011 Benjamin Heasly and distributed under
% the GNU General Public License.  dotsMglMake.m is is based on mglMake.m,
% which is part of the mgl project and also distributed under the
% GNU General Public License.  See mex/dotsMgl/COPYING.
function retval = dotsMglMake(rebuild, varargin)

% check arguments
if any(nargin > 10) % arbitrary...
    help dotsMglMake
    return
end

% interpret rebuild argument
if ~exist('rebuild','var')
    rebuild=0;
    [s,r] = system('uname -r');
    osmajorver = str2num(strtok(r,'.'));
    if ismac() && osmajorver < 9
        varargin = {'-D__carbon__', varargin{:}};
        fprintf(2,'(dotsMglMake) Defaulting to carbon')
    end
else
    if isequal(rebuild,1) || isequal(rebuild,'rebuild')
        rebuild = 1;
    elseif isequal(rebuild,'carbon')
        varargin = {'-D__carbon__', varargin{:}};
        rebuild = 1;
    elseif isequal(rebuild,'cocoa')
        varargin = {'-D__cocoa__', varargin{:}};
        rebuild = 1;
    elseif ischar(rebuild) && isequal(rebuild(1), '-')
        varargin = {rebuild, varargin{:}};
        rebuild=0;
    else
        help dotsMglMake
        return
    end
end

% close all open displays
mglSwitchDisplay(-1);

% clear the MGL global
clear global MGL;

% will need to cd around during build, cd back when done
lastPath = pwd;

% locate build resources
dotsMglHeader = which('dotsMgl.h');
if isempty(dotsMglHeader)
    error('Cannot locate dotsMgl.h.  Is Snow Dots mex/ on the Matlab path?');
end

mglHeader = which('mgl.h');
if isempty(mglHeader)
    error('Cannot locate mgl.h.  Is mgl on the Matlab path?');
end
mglHeaderPath = fileparts(mglHeader);
pathArg = sprintf('-I"%s"', mglHeaderPath);
if isunix
    optExt = 'sh';
else
    optExt = 'bat';
end
optsArg = sprintf('-f "%s"', fullfile(mglHeaderPath, ['mexopts.' optExt]));
varargin = {pathArg, optsArg, varargin{:}};

% validate mex() arguments
for nArg = 1:numel(varargin)
    if ischar(varargin{nArg}) && isequal(varargin{nArg}(1), '-')
        arg(nArg).name = varargin{nArg};
    else
        error('Attempted to pass an argument that is not a mex() option.');
    end
end

% change to the dotsMgl folder where Snow Dots mgl extensions live
dotsMglPath = fileparts(mfilename('fullpath'));
cd(dotsMglPath);

sourceInfo = dir('*.c');
mglHeaderInfo = dir(mglHeader);
dotsMglHeaderInfo = dir(dotsMglHeader);
for ii = 1:length(sourceInfo)
    
    % check to make sure this is not a temp file
    if (~strcmp('.#',sourceInfo(ii).name(1:2)))
        
        % see if it is already compiled
        [sourcePath, sourceBase, sourceExt] = ...
            fileparts(sourceInfo(ii).name);
        mexName = [sourceBase '.' mexext()];
        mexFile = dir(mexName);
        
        % mex the file if either there is no mexFile or
        % the date of the mexFile is older than the date of the source file
        if isempty(mexFile)
            mexDate = -inf;
        else
            mexDate = datenum(mexFile(1).date);
        end
        if (rebuild || length(mexFile)<1) || ...
                (datenum(sourceInfo(ii).date) > mexDate) || ...
                (datenum(mglHeaderInfo(1).date) > mexDate) || ...
                (datenum(dotsMglHeaderInfo(1).date) > mexDate)
            
            command = sprintf('mex ');
            if exist('arg', 'var') && isfield(arg, 'name');
                command = [command sprintf('%s ',arg.name)];
            end
            command = [command sprintf('%s', sourceInfo(ii).name)];
            
            disp(command);
            try
                eval(command);
                disp('...OK');
            catch err
                disp(['Error compiling ' sourceInfo(ii).name]);
                disp(err.message);
                disp(err.identifier);
            end
        else
            disp(sprintf('%s is up to date',sourceInfo(ii).name));
        end
    end
end

cd(lastPath);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% removes file extension if it exists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = stripext(filename,delimiter)

if ~any(nargin == [1 2])
    help stripext;
    return
end
% dot delimits end
if exist('delimiter', 'var')~=1
    delimiter='.';
end

retval = filename;
dotloc = findstr(filename,delimiter);
if ~isempty(dotloc)
    retval = filename(1:dotloc(length(dotloc))-1);
end

