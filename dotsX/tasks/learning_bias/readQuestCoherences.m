function readQuestCoherences(taski, varargin)
% get coherence values stored in the userData of another dXtask

questTaskName = varargin{1};
questInfo = rGetTaskByName(questTaskName, 'userData')

% info from quest:
% questInfo.subCoh
% questInfo.testCoh

if isempty(questInfo)
    disp('THERE ARE NO QUEST COHERENCES')
else

    % set new coherences for one of the tuning curves
    rSet('dXtc', 3, 'values', questInfo.testCoh);

    % put the subthreshold coherence in an accessible place
    %   be sure not to use bidirectional dots
    rSet('dXdots', 1, ...
        'dirDomain',    [], ...
        'dirCDF',       [], ...
        'userData',     questInfo.subCoh);

    % RESET *ALL* TUNING CURVES AS A GROUP!
    global ROOT_STRUCT
    ROOT_STRUCT.dXtc = reset(ROOT_STRUCT.dXtc, true);
end