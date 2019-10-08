function singlecp(subject_code, experiment_day, probCP, dump_folder)
% function to launch single CP Reversing Dots task
%
% ARGS:
%   subject_code     --  string that identifies subject uniquely, e.g. 'S4'
%   experiment_day   --  integer counting the days of experimentation with this subject
%   probCP           --  numeric value
%   dump_folder      --  e.g '/Users/adrian/Documents/MATLAB/projects/Lab_Matlab_Control/modularTasks/tasks/AdrianTests/'

%
% This function attempts to implement the following rules:
%  1. If experiment_day is > 1, checks that probCP alternates across days
%  2. Check whether a previous session on the same day contains relevant
%     Quest info.
%

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
    'displayIndex',      0, ...
    'remoteDrawing',     false, ...
    'topNode',           topNode);
topNode.addReadable('dotsReadableHIDKeyboard');

pauseBeforeTask = -1; % -1 means wait for keypress -- see topsTreeNode.pauseBeforeTask

    function add_block(topnode, taskID, task_name, trials_file, stop_cond)
        t = topsTreeNodeTaskReversingDots4AFC(task_name);
        t.taskID = taskID;
        t.independentVariables=trials_file;
        t.trialIterationMethod='sequential';
        t.pauseBeforeTask = pauseBeforeTask;
        t.stopCondition = stop_cond;
        
        % must be numeric
        t.subject = num2str(regexprep(subject_code,'[^0-9]',''));
        t.date = num2str(regexprep(timestamp,'_',''));  % must be numeric
        t.probCP = probCP;
        
        topnode.addChild(t);
    end


add_block(topNode, 1, 'training_1', 'training_1.csv', 7)
add_block(topNode, 2, 'training_2', 'training_2.csv', 7)
add_block(topNode, 3, 'training_3', 'training_3.csv', 7)
add_block(topNode, 4, 'training_4', 'training_4.csv', 15)
add_block(topNode, 5, 'training_5', 'training_5.csv', 25)
add_block(topNode, 6, 'training_6', 'training_6.csv', 'button')
add_block(topNode, 7, 'training_7', 'training_7.csv', 'button')
add_block(topNode, 8, 'training_8', 'training_8.csv', 'button')


topNode.run();


    function dumpFIRA(topnode, child)
        task = topnode.children{child};
        csvfile = ...
            [dump_folder, 'completedReversingDots4AFCtrials_task', ...
            num2str(child), '_date_', ...
            timestamp,'.csv'];
        task.saveTrials(csvfile, 'all');
    end

for c = 1:num_children
    dumpFIRA(topNode, c)
end

diary off
end