function rInit(varargin)% rInit(varargin)%%   Initialize DotsX -- set up global ROOT_STRUCT%       and add objects from default and given%       classes%%   Arguments:%       First optional argument provides a convenient way%           to set up dXscreen:%               {cell array} for arglist to dXscreen%               <window number> for screenMode = local, windowNumber = wn%               'local' for screenMode = local%               'remote' for screenMode = remote%               'debug' for screenMode = debug%               'none' for no dXscreen%       Remaining arguments are classes to add via rAdd, optionally%           followed by a cell array of arguments to also send to rAdd%%   See also dXscreen dXkbHID% Copyright 2005 by Joshua I. Gold%   University of Pennsylvania%%%% create global ROOT_STRUCT%%%%   classes          ... struct containing structs for each class added%   methods          ... struct of method lists%   groups           ... 'grouped' object info. See rGroup.%% First figure out Data directory based on machine name[s,w] = unix('hostname');if strncmp(w, 'Gold-MacBook', 12)    % Josh's computer    dataDir = '/junk'; %'/Users/jigold/GoldWorks/Mirror_lab/Data';elseif strncmp(w, 'Gold-MacBook.local', 18)    % psychophysics room computer    dataDir = '/Users/jigold/GoldWorks/Mirror_lab/Data';else    % otherwise dump everything in top-level DotsX folder    path    = fileparts(mfilename('fullpath'));    pinds   = strfind(path, filesep);    dataDir = path(1:pinds(end)-1);endglobal ROOT_STRUCTROOT_STRUCT = struct( ...    'dataDir',          fullfile(dataDir, 'DotsX'), ...    'error',            {{}},    ...    'guiFigure',        nan,     ...    'jumpState',        [],      ...    'jumpTime',         [],      ...    'classes',          struct('names', {{}}),       ...    'methods',          struct('names', {{}}),       ...    'groups',           struct('name','root','index',1,'names',{{'root'}},'root',struct('specs', {{}},'methods',struct('names', {{}}))));% conditionally add HID supportif exist('HIDx')    ROOT_STRUCT.HIDxInit = HIDx('init');end% pick a new seed for MATLAB's random number generator%   unique for this sessionROOT_STRUCT.randSeed = GetSecs;ROOT_STRUCT.randMethod = 'twister';rand(ROOT_STRUCT.randMethod, ROOT_STRUCT.randSeed);% check for 'noDefaults' keywordif ~isempty(varargin) && any(strcmp(varargin, 'noDefaults'))    % found it    varargin(strcmp(varargin, 'noDefaults')) = [];else    % Default classes .. make sure dXscreen is first    defaults = { ...        'dXscreen', {'screenMode', 'local'}; ...        'dXkbHID', {}; ...        };    % check for screenMode keywords in first position    if ~isempty(varargin)        % cell array is full arglist to dXscreen        if iscell(varargin{1})            defaults{1,2} = varargin{1};            varargin(1)   = [];            % scalar is local windowNumber        elseif isscalar(varargin{1})            defaults{1,2} = {'screenMode', 'local', 'windowNumber', varargin{1}};            varargin(1)   = [];        elseif strcmp(varargin{1}, 'none')            defaults(1,:) = [];            varargin(1)   = [];        elseif any(strcmp(varargin{1}, {'local', 'remote', 'debug'}))            defaults{1,2} = {'screenMode', varargin{1}};            varargin(1)   = [];        end    end    % loop through the defaults    for ii = 1:size(defaults, 1)        % check whether the class is in the arglist & has        %   another set of arguments...        ci = find(strcmp(defaults{ii,1}, varargin));        if ~isempty(ci)            varargin(ci) = [];            if size(varargin,2) >= ci && iscell(varargin{ci})                defaults{ii,2} = cat(2, defaults{ii,2}, varargin{ci});                varargin(ci) = [];            end        end        % add the object        rAdd(defaults{ii,1}, defaults{ii,2}{:});    endend% loop through the arglistwhile ~isempty(varargin)    % check for args    if size(varargin, 2) > 1 && iscell(varargin{2})        rAdd(varargin{1}, varargin{2}{:});        varargin(1:2) = [];    else        rAdd(varargin{1});        varargin(1) = [];    endend