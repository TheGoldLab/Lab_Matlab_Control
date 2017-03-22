% Download and configure Snow Dots and dependencies.
% @param localFolder where to save all the Snow Dots stuff (optional)
% @param dotsRepo what version of Snow Dots to use (optional)
% @param topsRepo what version of Tower of Psych to use (optional)
% @details
% installSnowDots() downloads Snow Dots and a bunch of other projects that
% Snow Dots depends on.  By default it saves everything to a subfolder
% folder named "SnowDots", in the current folder.  @a localFolder is
% optional, and can specify a different folder.
% @details
% By default, downloads the "Version 1" revisions of the Snow Dots and
% Tower of Psych projects.  @a dotsRepo and @a topsRepo may specify
% differnt repository paths.  For example, dotsRepo could be something
% like "http://snow-dots.googlecode.com/svn/trunk".
% @details
% Here is a list of things that installSnowDots() attempts to download and
% configure:
%   - is Matlab at version 7.6 or greater?
%   - is Subversion installed?
%   - download MGL with Subversion (OpenGL support)
%   - download Tower of Psych with Subversion (experiment organization)
%   - download Snow Dots with Subversion
%   - download TCP_UDP_IP Toolbox from Matlab Central File Exchange
%   (Ethernet support)
%   - download Matlab xUnit Toolbox from Matlab Central File Exchange
%   (code testing)
%   - build several mex functions locally, as needed
%   - save all of the above to the Matlab path
%   .
% @details
% installSnowDots() requires the Subversion tool for downloading some
% projects.  Read about Subversion and download it at
% http://subversion.tigris.org/.
% @details
% Snow Dots uses object-oriented features of Matlab that were introduced in
% Matlab version 7.6, also known as 2008a.  installSnowDots() checks for
% this version, or later.
% @details
% Once everything is downloaded, installSnowDots() tries to add it all to
% the Matlab path and save the path definition.
% @details
% installSnowDots() returns true if installation of essential components
% was successful, or false otherwise.  Also returns as a second output a
% struct array with data about how each step in the installation process
% went.   Each element represents an installation step.  The struct has a
% few fields:
%   - @b function function_handle for the subfunction here in
%   installSnowDots.m that does an installation step
%   - @b isEssential true or false, whether the step is essential for Snow
%   Dots to run
%   - @b status a status code for success of failure of the step (nonzero
%   values mean the step failed)
%   - @b result a string describing the result of the step
%   .
%
% @ingroup dotsUtilities
function [isSuccess, steps] = installSnowDots( ...
    localFolder, dotsRepo, topsRepo)

% default local folder
if nargin < 1 || isempty(localFolder)
    localFolder = 'SnowDots';
end

% default Subversion repository locations
%   @TODO: change these to Version 1 tags
if nargin < 2 || isempty(dotsRepo)
    dotsRepo = 'http://snow-dots.googlecode.com/svn/tags/Version_1';
end
if nargin < 3 || isempty(topsRepo)
    topsRepo = 'http://tower-of-psych.googlecode.com/svn/tags/Version_1';
end

% want to return to the original folder after installation
originalFolder = pwd();

% create the installation folder and go to it
message = sprintf('\nCreating folder "%s"', localFolder);
disp(message)
mkdir(localFolder);
cd(localFolder);
message = sprintf('Installing Snow Dots in folder\n  "%s"\n', pwd());
disp(message)

% define the installation steps
ii = 0;

ii = ii + 1;
steps(ii).function = @checkMatlabVersion;
steps(ii).isEssential = true;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @checkSubversionInstalled;
steps(ii).isEssential = false;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @downloadMGL;
steps(ii).isEssential = true;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @()downloadTowerOfPsych(topsRepo);
steps(ii).isEssential = true;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @()downloadSnowDots(dotsRepo);
steps(ii).isEssential = true;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @downloadTCP_UDP_IP_Toolbox;
steps(ii).isEssential = false;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @downloadMatalbXUnit;
steps(ii).isEssential = false;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @downloadMp3ReadWrite;
steps(ii).isEssential = false;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @()buildMex('pnet', @()mex('-O', 'pnet.c'));
steps(ii).isEssential = false;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @()buildMex('mglFlush', @mglMake);
steps(ii).isEssential = true;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @()buildMex('dotsMglDrawVertices', @dotsMglMake);
steps(ii).isEssential = true;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @()buildMex('mexUDP', @buildMexUDP);
steps(ii).isEssential = false;
steps(ii).status = -1;
steps(ii).result = '';

ii = ii + 1;
steps(ii).function = @()buildMex('mxGram', @buildMxGram);
steps(ii).isEssential = false;
steps(ii).status = -1;
steps(ii).result = '';

try
    % take each installation step in turn
    nSteps = numel(steps);
    for ii = 1:nSteps
        before = sprintf('(%d/%d) %s:', ...
            ii, nSteps, func2str(steps(ii).function));
        disp(before);
        
        % execute the actual installation step
        [steps(ii).status, steps(ii).result] = feval(steps(ii).function);
        
        after = sprintf('%s\n', steps(ii).result);
        disp(after);
        
        % update Matlab's path from the last step
        %   remove extra folders from the path
        %   save the path for future use
        snowDotsPath = genpath(pwd());
        snowDotsPath = cleanUpPath(snowDotsPath);
        addpath(snowDotsPath);
    end
    
catch err
    cd(originalFolder);
    rethrow(err);
end

% return to original folder
cd(originalFolder)

% how did it go?
isEssential = [steps.isEssential];
status = [steps.status];
isSuccess = all(status(isEssential) == 0);
if isSuccess
    message = sprintf('Installation succeeded.  Saving matlab path.\n');
    savepath();
    
else
    message = sprintf('Installation failed.\n');
end
disp(message);

%% subfunctions that define installation steps
function [status, result] = checkMatlabVersion()
oopVersion = '7.6';
thisVersion = version();
if verLessThan('matlab', oopVersion)
    status = -1;
    result = sprintf('Matlab version %s < %s. Too old!', ...
        thisVersion, oopVersion);
else
    status = 0;
    result = sprintf('Matlab version %s >= %s.  OK.', ...
        thisVersion, oopVersion);
end

function [status, result] = checkSubversionInstalled()
[status, result] = system('svn help');
if status == 0
    result = sprintf('Subversion system command "svn" found.  OK.');
end

function [status, result] = downloadMGL()
[status, result] = checkAlreadyInstalled('MGL', 'mglOpen');
if status ~= 0
    % need to download MGL
    repo = 'http://gru.brain.riken.jp/svn/mgl/trunk';
    folder = 'MGL';
    [status, result] = downloadWithSVN(repo, folder);
end

function [status, result] = downloadTowerOfPsych(repo)
[status, result] = checkAlreadyInstalled('Tower of Psych', 'TowerOfPsych');
if status ~= 0
    % need to download Tower of Psych
    folder = 'tower-of-psych';
    [status, result] = downloadWithSVN(repo, folder);
end

function [status, result] = downloadSnowDots(repo)
[status, result] = checkAlreadyInstalled('Snow Dots', 'SnowDots');
if status ~= 0
    % need to download Snow Dots itself
    folder = 'snow-dots';
    [status, result] = downloadWithSVN(repo, folder);
end

function [status, result] = downloadTCP_UDP_IP_Toolbox()
fileName = 'pnet';
toolbox = 'TCP_UDP_IP_Toolbox';
[status, result] = checkAlreadyInstalled(toolbox, fileName);
if status ~= 0
    % need to download the toolbox
    url = 'http://www.mathworks.com/matlabcentral/fileexchange/345-tcpudpip-toolbox-2-0-6?controller=file_infos&download=true';
    [status, result] = downloadFromFileExchange(url, toolbox);
    if status ~= 0
        return;
    end
end

function [status, result] = downloadMatalbXUnit()
fileName = 'runtests';
toolbox = 'MatlabXUnit';
[status, result] = checkAlreadyInstalled(toolbox, fileName);
if status ~= 0
    % need to download the toolbox
    url = 'http://www.mathworks.com/matlabcentral/fileexchange/22846-matlab-xunit-test-framework?controller=file_infos&download=true';
    [status, result] = downloadFromFileExchange(url, toolbox);
    if status ~= 0
        return;
    end
end

function [status, result] = downloadMp3ReadWrite()
fileName = 'mp3read';
toolbox = 'mp3ReadWrite';
[status, result] = checkAlreadyInstalled(toolbox, fileName);
if status ~= 0
    % need to download the toolbox
    url = 'http://www.mathworks.com/matlabcentral/fileexchange/13852-mp3read-and-mp3write?controller=file_infos&download=true';
    [status, result] = downloadFromFileExchange(url, toolbox);
    if status ~= 0
        return;
    end
end

%% general helper functions
function [status, result] = checkAlreadyInstalled(name, findFile)
foundPath = which(findFile);
if isempty(foundPath)
    status = -1;
    result = sprintf('%s not found', name);
else
    status = 0;
    result = sprintf('%s already installed.\n  "%s".  OK.', ...
        name, foundPath);
end

function [status, result] = downloadWithSVN(repo, folder)
svnCommand = sprintf('svn checkout --non-interactive %s %s', ...
    repo, folder);
disp(svnCommand);
[status, result] = system(svnCommand);

function [status, result] = downloadFromFileExchange(url, folder)
try
    % unzip can operate on http urls
    fileNames = unzip(url, folder);
catch err
    disp(err.message);
    fileNames = {};
end

if isempty(fileNames)
    status = -1;
    result = sprintf('Failed to download %s from url\n  "%s"\n', ...
        folder, url);
else
    status = 0;
    result = sprintf('Downloaded %s from url\n  "%s"\n', ...
        folder, url);
end

function [status, result] = buildMex(baseName, buildFunction)
isBuilt = exist(baseName, 'file') == 3;
if isBuilt
    status = 0;
    result = sprintf('Executable "%s" already exists.  OK.', baseName);
else
    % remember the Snow Dots installation folder
    installFolder = pwd();
    
    % go to the source folder and try to build the executable
    sourceFolder = fileparts(which(baseName));
    cd(sourceFolder);
    errMessage = '';
    try
        feval(buildFunction);
    catch err
        errMessage = err.message;
    end
    
    % is the executable there now?
    isBuilt = exist(baseName, 'file') == 3;
    if isBuilt
        status = 0;
        result = sprintf('Built executable.\n  "%s".  OK.', ...
            fullfile(sourceFolder, baseName));
    else
        status = -1;
        result = sprintf('Failed to build executable "%s":\n  "%s"\n', ...
            baseName, errMessage);
    end
    
    % go back to installation folder
    cd(installFolder);
end

function cleanerPathString = cleanUpPath(pathString)
% Remove hidden ".svn" folders from the given path string
pathCell = textscan(pathString, '%s', 'Delimiter', ':');
n = length(pathCell{1});
cleanerPathString = '';
for ii = 1:n
    if isempty(strfind(pathCell{1}{ii}, '.svn'))
        cleanerPathString = [cleanerPathString ':' pathCell{1}{ii}];
    end
end