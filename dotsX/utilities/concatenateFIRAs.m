function concatenateFIRAs(getDir)
%Make one giant FIRA from multiple saved FIRA files
%
%   concatenateFIRAs(getDir)
%
%   Get multiple FIRA structures saved to disk and append them to make one
%   big FIRA.  This is useful for analyzing multiple sessions of data from
%   FIRA files that are not very big (i.e. psychophysics, not physiology).
%
%   The ecodes of all the FIRA files will be concatenated and ecodes with
%   matching names will be concatenated to the same column.
%
%   Other data types in FIRA.(something) will be concatenated by field
%   name.
%
%   getDir is optional.  If it is a string specifying a directory that
%   exists, concatenateFIRAs will open all .mat files in that directory and
%   look for FIRA structures to concatenate.  If getDir is a boolean and
%   true, concatenateFIRAs will open a dialog for selecting a directory.
%   Otherwise, concatenateFIRAs will open a dialog for selecting individual
%   files.
%
%   The field FIRA.allHeaders will be added.  This will contain an array
%   of structures with each element corresponding to FIRA.header from one
%   of the concatenated FIRA structs.
%
%   FIRA.allHeaders(ii).trialSelect will contain an array of indices for
%   selecting trials that correspond to the iith header.  These can select
%   ecodes or data from FIRA.(something).
%
%   If there's an existing FIRA already, new FIRA files will be
%   concatenated with it, even if they are duplicates.  So watch out!
%
%   See also unifyFIRATaskNames, findFIRASessionsAndBlocks

% copyright 2008 by Benjamin Heasly at University of Pennsylvania

if ~nargin
    getDir = false;
end

% where are data usually found?
if exist('/Volumes/XServerData')
    suggestion = ...
        '/Volumes/XServerData/Psychophysics';
else
    suggestion = '/Users/lab/GoldLab/Data';
end

if ischar(getDir) && exist(getDir) == 7

    % get the list of .mat files in this directory
    d = dir(fullfile(getDir, '*.mat'));
    matList = {d.name};

elseif islogical(getDir) && getDir

    % open a dialog to get a directory and get its .mat files
    getDir = uigetdir(suggestion, 'Pick a directory with .mat files');
    d = dir(fullfile(getDir, '*.mat'));
    matList = {d.name};

else

    % open a dialog to get individual .mat files
    [matList, getDir, filteri] = ...
        uigetfile({'*.mat'},'Pick some .mat files', ...
        suggestion, 'MultiSelect', 'on');

    if ischar(matList)
        matList = {matList};
    end
end

% don't make annoying errors
if isempty(matList) || ~iscell(matList)
    return
end

% load in each file and concatenate any FIRA there
for mf = matList
    DUMP = load(fullfile(getDir, mf{1}));

    if isfield(DUMP, 'FIRA') && isstruct(DUMP.FIRA)
        disp(sprintf('Found a FIRA in %s', mf{1}))
        appendFIRA(DUMP.FIRA);
    else
        disp(sprintf('No FIRA in %s', mf{1}))
    end
end


%%%
function appendFIRA(F);

global FIRA
if isempty(FIRA)

    % this is the first FIRA,
    %   just copy it, account for trials, and duplicate the header
    FIRA = F;
    F.header.trialSelect = (1:size(F.ecodes.data, 1))';

    % make a placeholder for session ID, which should be filled in by
    %   findFIRASessionsAndBlocks()
    F.header.sessionID = nan;

    FIRA.allHeaders = F.header;

else

    % append this FIRA

    % copy the data types in FIRA.(something)
    %   allign these data with incoming ecodes
    %   so that there can be gaps types are missing
    dataFields = fieldnames(F);

    % ignore header, spm and ecodes, just for here
    dataFields(strcmp(dataFields, 'header')) = [];
    dataFields(strcmp(dataFields, 'spm')) = [];
    dataFields(strcmp(dataFields, 'ecodes')) = [];

    buildFIRA_addTrial('add');
    inds = (1:size(F.ecodes.data, 1))' + size(FIRA.ecodes.data, 1) - 1;
    for dt = dataFields'
        FIRA.(dt{1})(inds) = F.(dt{1});
    end

    % concetenate ecodes by column name
    d = F.ecodes.data;
    n = F.ecodes.name;
    t = F.ecodes.type;
    buildFIRA_addTrial('ecodes', {d, n, t});

    % copy the header with an account of trials
    F.header.trialSelect = inds;

    % make a placeholder for session ID, which should be filled in by
    %   findFIRASessionsAndBlocks()
    F.header.sessionID = nan;
    
    % concatenate the headers
    FIRA.allHeaders = cat(1, FIRA.allHeaders, F.header);
end