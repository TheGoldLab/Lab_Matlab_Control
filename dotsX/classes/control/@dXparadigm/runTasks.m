function runTasks(p)
% function runTasks(p)
%
% Execute the tasks that were loaded with dXparadigm/loadTasks.
%
% Returns nothing.  Modifies global instance of dXparadigm.  All object
% props should be editable on the fly, so keep local copies of dXparadigm
% as fresh as reasonably possible and only assign to
% ROOT_STRUCT.dXparadigm.
%
% 2006 by Benjamin Heasly at University of Pennsylvania

global ROOT_STRUCT FIRA

% prevent FIRA session contamination
%   happens esp. when BSH runs a few test trials without the subject
FIRA = [];

% Purge old messages
%   then trigger one timestamp return
if ROOT_STRUCT.screenMode == 2
    while ~isempty(getMsg)
        WaitSecs(0.001);
    end
    sendMsg('%%dXparadigm/loadTasks%%');
end

% keep track of total execution time and intertrial time
start_time = GetSecs;
iti_start = 0;

% by default, don't use debug mode in dXtask/trial
debug = false;

% intex of current task
taski = nan;
task_end = true;

% assume GUI figure handles won't change during each exp.
if ishandle(ROOT_STRUCT.guiFigure)
    % get handles, refresh guis
    handles = guidata(ROOT_STRUCT.guiFigure);
    if ~isempty(handles)
        dXGUI_sync(handles);
    end
else
    handles = [];
end

% record the session date and start time in a nice format
% duplicate original task proportions to be restored upon repeatAllTasks
% set time markers for periodic writing to disk of ROOT, FIRA
ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, ...
    'sessionTime',      clock, ...
    'totalTrials',      0, ...
    'goodTrials',       0, ...
    'correctTrials',    0, ...
    'proportionsCopy',  p.taskProportions, ...
    'ROOT_nextWrite',   start_time + p.ROOT_writeInterval, ...
    'FIRA_nextWrite',   start_time + p.FIRA_writeInterval);

% reset all tasks!
%   force helpers, like dXtc, to reset as well
for ii = 1:length(ROOT_STRUCT.dXtask)
    ROOT_STRUCT.dXtask(ii) = reset(ROOT_STRUCT.dXtask(ii), true);
end

while get(ROOT_STRUCT.dXparadigm, 'repeatAllTasks') >= 0
    
    % is there a GUI in use?
    if ~isempty(handles)
        % flush the event queue to get the most recent user input
        drawnow;
    end
    
    % pick the next task based on user-specified order and proportions
    taskPropo = get(ROOT_STRUCT.dXparadigm, 'taskProportions');
    oldi = taski;
    switch get(ROOT_STRUCT.dXparadigm, 'taskOrder')
        
        case 'blockTasks'
            % simply the first task with any trials to run
            taski = find(taskPropo, 1);
            
            % pass the task selection to instance in ROOT_STRUCT
            ROOT_STRUCT.dXparadigm = ...
                set(ROOT_STRUCT.dXparadigm, 'taski', taski);
            
        case 'randomTaskByTrial'
            % a random task weighted by repetitions
            taski = find(ceil(sum(taskPropo)*rand)<=cumsum(taskPropo), 1);
            
            % pass the task selection to instance in ROOT_STRUCT
            ROOT_STRUCT.dXparadigm = ...
                set(ROOT_STRUCT.dXparadigm, 'taski', taski);
            
        case 'randomTaskByBlock'
            
            if task_end
                % a random task weighted by repetitions
                taski = find(ceil(sum(taskPropo)*rand)<=cumsum(taskPropo), 1);
                
                % pass the task selection to instance in ROOT_STRUCT
                ROOT_STRUCT.dXparadigm = ...
                    set(ROOT_STRUCT.dXparadigm, 'taski', taski);
            end
            
        case 'freeChoice'
            % could be the same old moldy task as last time, but
            %   user may select a new one with the GUI, or
            %   the previous task may have changed dXparadigm.taski
            taski = get(ROOT_STRUCT.dXparadigm, 'taski');
            
        case 'repeatTrial'
            % do not select a new task.
            
            if ~strcmp(get(ROOT_STRUCT.dXtask(taski), 'trialOrder'), 'repeat')
                % go to repeat mode for this task's trials
                ROOT_STRUCT.dXtask(taski) = ...
                    set(ROOT_STRUCT.dXtask(taski), 'trialOrder', 'repeat');
            end
    end
    
    p = ROOT_STRUCT.dXparadigm;
    
    % get info about new task
    if oldi ~= taski
        
        % activate new task helpers
        taskName = get(ROOT_STRUCT.dXtask(taski), 'name');
        rGroup(taskName);
        
        % protect against crashing/file corruption by saving a
        % backup file following each task
        save(fullfile('~', get(ROOT_STRUCT.dXtask(taski), 'name')));
        
        % possibly change background color
        taskBg = get(ROOT_STRUCT.dXtask(taski), 'bgColor');
        if ~isempty(taskBg) ...
                && ~isequal(taskBg, get(ROOT_STRUCT.dXscreen, 'bgColor'))
            
            ROOT_STRUCT.dXscreen = ...
                set(ROOT_STRUCT.dXscreen, 'bgColor', taskBg);
        end
    end
    
    % start up or restart this task
    if task_end
        
        % call the new task's special function
        startFcn = get(ROOT_STRUCT.dXtask(taski), 'startTaskFcn');
        if ~isempty(startFcn)
            if length(startFcn) == 1
                feval(startFcn{1}, taski);
            else
                feval(startFcn{1}, taski, startFcn{2:end});
            end
            
            % function may have modified the dXparadigm
            p = struct(ROOT_STRUCT.dXparadigm);
        end
        
        % possibly show feedback
        if isfield(ROOT_STRUCT, 'dXfeedback') && ...
                ~isempty(ROOT_STRUCT.dXfeedback)
            
            % may need to update the special 'more' feedback field
            if ~isempty(p.moreFeedbackFunction)
                ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, ...
                    'moreFeedback', feval(p.moreFeedbackFunction, struct(p)));
            end
            
            if p.showFeedback
                % show paradigm-level feedback between tasks
                ROOT_STRUCT.dXfeedback = ...
                    show(ROOT_STRUCT.dXfeedback, false, true);
            end
        end
        
        % mark the starting time for this task
        ROOT_STRUCT.dXtask(taski) = ...
            set(ROOT_STRUCT.dXtask(taski), 'startTime', GetSecs);
        
    end
    
    % in debug mode, pass stateFigure handle to dXtask/trial
    %     if ~isempty(handles)
    %         if isstruct(handles.stateFigures) ...
    %                 && isfield(handles.stateFigures, taskName) ...
    %                 && ~isempty(handles.stateFigures.(taskName))
    %
    %             % either a false flag or a stateGUI handle
    %             debug = get(handles.debugCheck, 'Value') ...
    %                 *handles.stateFigures.(taskName);
    %         end
    %     end
    
    % execute an actual trial
    [ROOT_STRUCT.dXtask(taski), good_trial, correct_trial, outcome] = ...
        trial(ROOT_STRUCT.dXtask(taski), debug);
    
    % refresh guis
    if ~isempty(handles)
        dXGUI_sync(handles);
    end
    
    % speed things up with a quick little post-trial copy.
    p = struct(ROOT_STRUCT.dXparadigm);
    
    % increment trial counters.
    ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, ...
        'totalTrials',      p.totalTrials   + 1, ...
        'goodTrials',       p.goodTrials    + good_trial, ...
        'correctTrials',    p.correctTrials + correct_trial);
    
    % check for task time limit
    timeOK = (GetSecs - get(ROOT_STRUCT.dXtask(taski), 'startTime')) ...
        < get(ROOT_STRUCT.dXtask(taski), 'timeLimit');
    ROOT_STRUCT.dXtask(taski) = ...
        set(ROOT_STRUCT.dXtask(taski), 'isAvailable', timeOK);
    
    % Call all "endTrial" methods if they exist
    if isfield(ROOT_STRUCT.methods, 'endTrial') ...
            && ~isempty(ROOT_STRUCT.methods.endTrial)
        
        % always call on control helpers first
        if isfield(ROOT_STRUCT.methods, 'control') ...
                && ~isempty(ROOT_STRUCT.methods.control)
            
            % endTrial(control)
            rBatch('endTrial', ROOT_STRUCT.methods.control, ...
                good_trial, outcome);
            
            % endTrial(non-control)
            %   setdiff takes about 2ms
            etb = setdiff(ROOT_STRUCT.methods.endTrial, ROOT_STRUCT.methods.control);
            if ~isempty(etb)
                rBatch('endTrial', etb, good_trial, outcome);
            end
        else
            
            % all at once
            rBatch('endTrial', [], good_trial, outcome);
        end
    end
    
    disp('*** DONE TRIAL ***')
    
    % keep track of intertrial processing time, discount from iti
    iti_start = GetSecs;
    
    % possibly execute the task's intertrial function
    %   this is an arbitrary function, not an endTrial method
    itf = get(ROOT_STRUCT.dXtask(taski), 'intertrialFcn');
    if ~isempty(itf)
        if length(itf) == 1
            feval(itf{1}, taski);
        else
            feval(itf{1}, taski, itf{2:end});
        end
    end
    
    % keep the copy fresh
    p = struct(ROOT_STRUCT.dXparadigm);
    
    % during iti, check keyboard and do MATLAB drawing
    ROOT_STRUCT.dXkbHID = reset(ROOT_STRUCT.dXkbHID);
    iti_end = iti_start + p.iti;
    while GetSecs < iti_end
        HIDx('run');
        v = get(ROOT_STRUCT.dXkbHID, 'values');
        if ~isempty(v) && any(v(:,2))
            % find pressed keys
            dXkbFunctionKeys(v(v(:,2)==1,1));
        end

        % pause() dispatches MATLAB queued events and graphics
        %   WaitSecs() does not
        pause(.01);
    end
    
    % check completion conditions
    p = struct(ROOT_STRUCT.dXparadigm);
    if p.totalTrials >= p.trialLimit ...
            || p.goodTrials >= p.goodTrialLimit ...
            || (GetSecs-start_time)/60 > p.timeLimit
        
        % ran out of trials trials at the paradigm level
        task_end = true;
        ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, ...      
            'totalTrials',      0, ...
            'goodTrials',       0, ...
            'correctTrials',    0, ...
            'repeatAllTasks', p.repeatAllTasks-1);
            start_time = GetSecs;
        
    else
        
        % task is done
        %   nextTrial() will use the value of trialOrder specified before
        %   previous trial's execution, even if order was changed in GUI
        %   during the trial. To get the latest value now, spend the time to
        %   call drawnow().
        task_end = ~nextTrial(ROOT_STRUCT.dXtask(taski));
    end

    if task_end
        
        % Execute end-of-task function before making any changes
        %   make sure we're in the correct group
        rGroup(get(ROOT_STRUCT.dXtask(taski), 'name'));
        endFcn = get(ROOT_STRUCT.dXtask(taski), 'endTaskFcn');
        if ~isempty(endFcn)
            if length(endFcn) == 1
                feval(endFcn{1}, taski);
            else
                feval(endFcn{1}, taski, endFcn{2:end});
            end
            
            % function may have modified the dXparadigm
            p = struct(ROOT_STRUCT.dXparadigm);
        end
        
        % Weed out this task by decrementing its proportion
        if isfinite(p.repeatAllTasks) && ~strcmp(p.taskOrder, 'randomTaskByTrial');
            p.taskProportions(taski) = p.taskProportions(taski) - 1;
            ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, ...
                'taskProportions', p.taskProportions);
        end
        
        % Refresh guis
        if ~isempty(handles)
            dXGUI_sync(handles);
        end
        
        % Always force reset of the task
        ROOT_STRUCT.dXtask(taski) = ...
            reset(ROOT_STRUCT.dXtask(taski), true);
    end
    
    if sum(p.taskProportions) <= 0
        
        % All tasks have been weeded out!
        ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, ...
            'repeatAllTasks', p.repeatAllTasks-1, ...
            'taskProportions',  p.proportionsCopy);
    end
    
    % periodically and conditionally write ROOT_STRUCT, FIRA to disk
    nowness = GetSecs;
    rootNow = nowness > p.ROOT_nextWrite;
    firaNow = nowness > p.FIRA_nextWrite;
    
    % increment time markers for next writes
    %   put useful ROOT data into FIRA
    if rootNow
        ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, ...
            'ROOT_nextWrite', p.ROOT_nextWrite + p.ROOT_writeInterval);
    end
    if firaNow
        % why not save everything?
        p = struct(ROOT_STRUCT.dXparadigm);
        FIRA.header.paradigm = p;
        FIRA.header.subject = p.FIRA_filenameBase;
        FIRA.header.session = ROOT_STRUCT;
        
        ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, ...
            'FIRA_nextWrite', p.FIRA_nextWrite + p.FIRA_writeInterval);
    end
    
    dXwriteExisting(rootNow && p.ROOT_doWrite, firaNow && p.FIRA_doWrite);
end



% After running all tasks:
p = struct(ROOT_STRUCT.dXparadigm);

% possibly show feedback after all tasks
if isfield(ROOT_STRUCT, 'dXfeedback') && ~isempty(ROOT_STRUCT.dXfeedback)
    
    % may need to update the special 'more' feedback field
    if ~isempty(p.moreFeedbackFunction)
        ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, ...
            'moreFeedback', feval(p.moreFeedbackFunction, struct(p)));
    end
    
    if p.showFeedback
        % show paradigm-level feedback
        ROOT_STRUCT.dXfeedback = ...
            show(ROOT_STRUCT.dXfeedback, false, true);
    end
end

% try saving to FIRA one last time
%   after the final endTrial()
rBatch('saveToFIRA');

% why not save everything?
if ~isempty(FIRA)
    FIRA.header.paradigm = p;
    FIRA.header.subject = p.FIRA_filenameBase;
    FIRA.header.session = ROOT_STRUCT;
    dXwriteExisting(p.ROOT_doWrite, p.FIRA_doWrite);
end

% is there any reason not to do rDone here??
%   we are /done/, after all
save(fullfile(p.FIRA_saveDir, 'paradigmDone.mat'));
rDone

disp('***** DONE RUNNING TASKS *****')