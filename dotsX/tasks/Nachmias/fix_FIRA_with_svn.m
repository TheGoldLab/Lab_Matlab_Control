function DUMP_ = fix_FIRA_with_svn(pth, file);
% Some nachmias psychophysics sessions left important data out of FIRA.
% Most of those data are stored in DotsX files and ROOT_STRUCT files in the
% svn repository.  So it's possible to figure out what's missing, check it
% out, and append it to a given FIRA.
%
% Takes a filename, file, which should indicate a .mat that contains a
% saved FIRA struct.
%
% Outputs a struct of the form of DUMP_.FIRA, where FIRA came out of the
% .mat file.
%
% Also saves a version of file, with some suffix, if missing data were
% found and appended.

DUMP_ = load(fullfile(pth, file));

% look for ROOT_STRUCTs
if isempty(DUMP_.FIRA.header.session)
    
    date = DUMP_.FIRA.header.date;

    % add a day to the date?  Watch it!
    dv = datevec(date);
    dv(3) = dv(3) + 1;
    date = datestr(dv, 1);

    % download dated ROOT_STRUCT from svn server
    disp(['downloading ROOT_STRUCT from ', date])

    repos = 'http://192.168.1.9:8800/svn/DotsX/trunk/tasks';
    place = pwd;
    [s, wsvn] = unix('which svn');
    cmd = sprintf('%s checkout --non-recursive --revision "{%s}" %s %s', ...
        deblank(wsvn), datestr(date, 30), ...
        repos, fullfile(place, 'dated_tasks'));
    [err,r] = unix(cmd);

    if err
        % checkout failed, get current version on path
        disp('...failed to checkout')
        DUMP_ = [];
        return
    else
        if isempty(DUMP_.FIRA.header.paradigm)
            DUMP_.FIRA.header.paradigm.name = 'no_name';
            fix_taskList = true;
        else
            fix_taskList = false;
        end

        root_name = fullfile(place, 'dated_tasks', ...
            [DUMP_.FIRA.header.paradigm.name, '.mat']);

        % load a ROOT file
        if exist(root_name)
            % preferably by paradigm name
            RDUMP = load(root_name);
            prefix = 'R';
            suffix = '';
        else
            % or else a contemporary root
            % in this case, paradigm stored in FIRA.header is not
            % the same as the paradigm stored in
            disp(sprintf('Can''t find %s', ...
                [DUMP_.FIRA.header.paradigm.name, '.mat']))
            eTask = strcmp(DUMP_.FIRA.ecodes.name, 'task_index');
            disp('Task indices used:')
            disp(unique(DUMP_.FIRA.ecodes.data(:,eTask))')
            disp('Ecode names:')
            disp(DUMP_.FIRA.ecodes.name)
            disp('Total trials:')
            disp(DUMP_.FIRA.header.numTrials)

            [root_name, root_path, filteri] = ...
                uigetfile({'*.mat'},'pick a substitute ROOT', ...
                fullfile(place, 'dated_tasks/*'));
            if isempty(file)
                return
            end
            RDUMP = load(fullfile(root_path, root_name));
            prefix = 'R';
            suffix = 'subROOT';
        end

        % put ROOT_STRUCT in FIRA header
        DUMP_.FIRA.header.session = RDUMP.ROOT_STRUCT;

        if fix_taskList
            taskBook = struct(DUMP_.FIRA.header.session.dXtask);
            
            % task names in ROOT_STRUCT omit the 'task' prefix
            tL = {taskBook.name};
            for ii = 1:length(tL)
                tL{ii} = sprintf('task%s', tL{ii});
            end
            DUMP_.FIRA.header.paradigm.taskList = tL;
            suffix = ['fixedHeader', suffix];
        end

        % save a new FIRA file with the prefix indicating
        %   the actual ROOT_STRUCT used (R), or
        %   a substitute ROOT_STRUCT (Rsub).
        [p, base, ext] = fileparts(file);
        save(fullfile(pth, [prefix,base,suffix,ext]), '-STRUCT', 'DUMP_');
    end
end
