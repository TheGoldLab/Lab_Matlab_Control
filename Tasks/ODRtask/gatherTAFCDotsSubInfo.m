function [dataFileName, taskPhase, id] = gatherTAFCDotsSubInfo(tag, id, session)
% GATHERSUBINFO requests information about subject number and ID code.
% Creates a unique filename for saving the data.  Returns some relevant
% info in dataHeader.
% Input:  TAG is the experiment name to be used in the data file.  (a text
% string)

% if no id is specified, ask for a subject ID
if nargin<2 || isempty(id)
    prompt=1;
    id = [];
    while isempty(id)
        id = input('Subject ID:  ','s');
    end
else
    prompt=0;
end


% try to use the subject progress structure to determine phase and cbal
phaseLabels = {'demo', 'main'};
taskPhase = [];

% ask for the task phase
while isempty(taskPhase)
   % fprintf('Task phase:\n');
    %for i = 1:length(phaseLabels)
    %    fprintf('  %d = %s\n',i,phaseLabels{i});
   % end
    if prompt==1
        phaseIdx = 2;
        if ismember(phaseIdx,1:length(phaseLabels))
            taskPhase = phaseLabels{phaseIdx};
        end
    end   
end


% set session number, ensuring a unique filename

if nargin<3 || isempty(session)
session = 1;
end

nameVetted = false;
while ~nameVetted
    dataFileName = fullfile('MainTaskData',sprintf('%s_%s_%s_%d',tag,id,taskPhase,session));
    if exist(sprintf('%s.mat',dataFileName),'file')==2
        session = session+1;
    elseif exist(sprintf('%s.txt',dataFileName),'file')==2
        session = session+1;
    else
        nameVetted = true;
    end
end

%if prompt==1
%input(['Data will be saved in:\n  ',dataFileName,'\n  (ENTER to continue)']);
%end


