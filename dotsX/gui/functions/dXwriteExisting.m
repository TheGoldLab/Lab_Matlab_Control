function dXwriteExisting(doROOT, doFIRA)
% function dXwriteExisting(doROOT, doFIRA)
%
% If there's an existing ROOT_STRUCT or FIRA, prompt the user to write each
% to disk as a .mat.  Use an existing dXparadigm or a default dXparadigm
% to suggeest filenames from  e.g. dXparadigm.ROOT_filenameBase.  Append to
% the filename the date and time in ISO 8601 format.
%
% Options:  0 = skip ROOT_STRUCT or FIRA altogether
%           1 = save straightaway using default path/filename
%           2 = prompt for path/filename
%
% 2006 Benjamin Heasly at University of Pennsylvania

if nargin ~= 2
    return
end

global ROOT_STRUCT FIRA

if doROOT || doFIRA
    % need at least a default dXparadigm to proceed.
    if isfield(ROOT_STRUCT, 'dXparadigm')
        dXp = ROOT_STRUCT.dXparadigm;
    else
        dXp = dXparadigm(1);
    end

    % use matching suffix for ROOT and FIRA
    if strcmp(get(dXp, 'fileSuffixMode'), 'session')
        time = get(dXp, 'sessionTime');
    else
        time = clock;
    end
    suffix = datestr(time, 30);
end

if doROOT > 0 && ~isempty(ROOT_STRUCT)

    % defaults to suggest in prompt
    dir = get(dXp,'ROOT_saveDir');
    file = [get(dXp,'ROOT_filenameBase'), suffix, 'R'];

    if doROOT == 2
        suggestion = fullfile(dir,file);
        [file, dir, filteri] = ...
            uiputfile('*.mat', 'Save existing ROOT_STRUCT?', suggestion);
    end

    if ischar(file) && ischar(dir)
        file = fullfile(dir,file);
        if exist(file)
            save(file, 'ROOT_STRUCT', '-append');
        else
            save(file, 'ROOT_STRUCT');
        end
        disp('WROTE ROOT_STRUCT TO DISK');
    end
end

if doFIRA > 0 && ~isempty(FIRA)

    % defaults to suggest in prompt
    dir = get(dXp,'FIRA_saveDir');
    file = [get(dXp,'FIRA_filenameBase'), suffix, 'F'];

    if doFIRA == 2
        suggestion = fullfile(dir,file);
        [file, dir, filteri] = ...
            uiputfile('*.mat', 'Save existing FIRA?', suggestion);
    end

    % make good with the filename
    FIRA.header.filename = file;

    if ischar(file) && ischar(dir)
        file = fullfile(dir,file);
        if exist(file)
            save(file, 'FIRA', '-append');
        else
            save(file, 'FIRA');
        end
        disp('WROTE FIRA TO DISK');
    end
end