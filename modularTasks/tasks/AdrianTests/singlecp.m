function singlecp(subject_code, experiment_day, first_block_of_day, ...
    probCP, dump_folder, quest_task_topsDataLog)
% function to launch single CP Reversing Dots task
%
% ARGS:
%   subject_code     --  string that identifies subject uniquely, e.g. 'S4'
%   experiment_day   --  integer counting the days of experimentation with this subject
%   first_block_of_day --  true or false
%   probCP           --  numeric value
%   dump_folder      --  e.g
%   '/Users/adrian/Documents/MATLAB/projects/Lab_Matlab_Control/modularTasks/tasks/AdrianTests/'
%   quest_task_topsDataLog -- full path to topsDataLog containing the Quest
%   task
%


%
% This function attempts to implement the following rules:
%  1. If experiment_day is > 1, checks that probCP alternates across days
%  2. Check whether a previous session on the same day contains relevant
%     Quest info.
%

if nargin < 1
    subject_code = 'S1';
    experiment_day = 1;
    first_block_of_day = true;
    probCP = 0.3;
    dump_folder = '/Users/adrian/Documents/MATLAB/projects/Lab_Matlab_Control/modularTasks/tasks/AdrianTests/';
    quest_task_topsDataLog = '/Users/adrian/oneCP/raw/2019_10_03_10_01/2019_10_03_10_01_topsDataLog.mat';  % made up
end

topNode = topsTreeNodeTopNode('oneCP');

    function ts = extract_timestamp(tn)
        % returns the timestamp as a string 'YYYY_MM_DD_HH_mm' associated with
        % the topsTreeNodeTopNode object tn
        ts = regexprep(tn.filename, ...
            '[^[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{2}_[0-9]{2}]', '');
        ts = ts(1:16);
    end

timestamp = extract_timestamp(topNode);

diary([dump_folder, 'session_console_',timestamp,'.log'])

topNode.addHelpers('screenEnsemble',  ...
    'displayIndex',      1, ...
    'remoteDrawing',     false, ...
    'topNode',           topNode);
topNode.addReadable('dotsReadableHIDKeyboard');

pauseBeforeTask = -1; % -1 means wait for keypress -- see topsTreeNode.pauseBeforeTask

    function add_block(topnode, taskID, task_name, trials_file, ...
            stop_cond, block_description)
        t = topsTreeNodeTaskReversingDots4AFC(task_name);
        t.taskID = taskID;
        t.independentVariables=trials_file;
        t.trialIterationMethod='sequential';
        t.pauseBeforeTask = pauseBeforeTask;
        t.stopCondition = stop_cond;
        
        % must be numeric
        t.subject = str2double(regexprep(subject_code,'[^0-9]',''));
        t.date = str2double(regexprep(timestamp,'_',''));  % must be numeric
        t.probCP = probCP;
        
        t.message.message.Instructions.text = {...
            block_description ...
        };
        
        topnode.addChild(t);
    end

    function add_training_block(tid, name, condstop)
        add_block(topNode, tid, name, [name,'.csv'], condstop, ...
            {'training block',num2str(tid)})
    end

num_training_blocks=1;

stop_conditions = {...
    3, 3, 3, 3, 3, 'button', 'button', 'button' ...
    };

for jj = 1:num_training_blocks
    add_training_block(jj, ['training_',num2str(jj)], stop_conditions{jj})
end

% Optional Quest
% only put Quest block if this is the first block of the day
if first_block_of_day
    questTask = topsTreeNodeTaskRTDots('Quest');
    questTask.taskID = 99;
    questTask.trialIterations = 25;
    questTask.timing.dotsDuration = 0.4;
    questTask.pauseBeforeTask = pauseBeforeTask;
    questTask.message.message.Instructions.text = {{'Quest block','There are no switches'}};
    topNode.addChild(questTask);
    
    
    
%     questTask = topsTreeNodeTaskRTDots('Quest');
%     questTask.taskID = 1;
%     questTask.trialIterations = 1;
%     questTask.timing.dotsDuration = 0.4;
%     questTask.pauseBeforeTask = pauseBeforeTask;
%     topNode.addChild(questTask);
else
    % get questTask from first topsDataLog of the day
    % right now, stops at first Quest block found
    ts = regexprep(quest_task_topsDataLog, ...
        '[^[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{2}_[0-9]{2}]', '');
    ts = ts(1:16);
    [oldTopNode, ~] = topsTreeNodeTopNode.loadRawData('oneCP', ts);
    for tt = 1:length(oldTopNode.children)
        task_child = oldTopNode.children{tt};
        if strcmp(task_child.name,'Quest')
            questTask = task_child;
            break
        end
    end
end


% Task blocks
if probCP < 0.5
    task_file = 'task_low.csv';
else
    task_file = 'task_high.csv';
end

ttt = topsTreeNodeTaskReversingDots4AFC('TASK');
ttt.taskID = 100;
ttt.independentVariables=task_file;
ttt.trialIterationMethod='sequential';
ttt.pauseBeforeTask = pauseBeforeTask;
ttt.stopCondition = 'button';

% must be numeric
ttt.subject = str2double(regexprep(subject_code,'[^0-9]',''));
ttt.date = str2double(regexprep(timestamp,'_',''));  % must be numeric
ttt.probCP = probCP;

ttt.message.message.Instructions.text = {...
    {{'REAL TASK', 'RARE SWITCHES'}} ...
    };

if ~first_block_of_day
    ttt.questThreshold = questTask.getQuestThreshold();
else 
    ttt.questThreshold = questTask;
end

topNode.addChild(ttt);



topNode.run();


    function dumpFIRA(topnode, child)
        task = topnode.children{child};
        csvfile = ...
            [dump_folder, 'completedReversingDots4AFCtrials_task', ...
            num2str(child), '_date_', ...
            timestamp,'.csv'];
        task.saveTrials(csvfile, 'all');
    end

num_children = length(topNode.children);

for c = 1:num_children
    if numel(topNode.children{c}.trialData)
        dumpFIRA(topNode, c)
    end
end

diary off
end