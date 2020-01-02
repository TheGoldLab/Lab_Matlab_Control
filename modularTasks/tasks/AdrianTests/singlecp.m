function singlecp(subject_code, probCP)
% function to launch single CP Reversing Dots task
%
% ARGS:
%   subject_code     --  string that identifies subject uniquely, e.g. 'S4'
%   first_block_of_day --  true or false
%   probCP           --  numeric value
%   dump_folder      --  e.g '/Users/joshuagold/Documents/MATLAB/projects/Lab_M
%                        atlab_Control_Adrian_Fork/modularTasks/tasks/AdrianTests/'
%   quest_task_topsDataLog -- full path to topsDataLog containing the Quest
%                             task (can be '' if no prior Quest task is 
%                             required)

%-------------------------- DEFAULT ARGS
dump_folder = '/Users/joshuagold/Documents/MATLAB/projects/Lab_Matlab_Control_Adrian_Fork/modularTasks/tasks/AdrianTests/trials_post_expt/';
first_block_of_day = false;  % if true, Quest block is added


% the following variable should hold the full path to a topsDataLog.mat
% file where a valid Quest block was run. This is when one wants to skip
% the Quest block presently, and thus use the threshold estimated from a
% prior Quest block.
quest_task_topsDataLog = '/Users/joshuagold/Users/Adrian/oneCP/raw/2019_12_13_13_37/2019_12_13_13_37_topsDataLog.mat';  


%-------------------------- DOTS STIMULUS PROPERTIES
ddots.Density = 150;
ddots.Speed = 5;
ddots.PixelSize = 6;
ddots.Diameter = 8;
ddots.CoherenceSTD = 10;

    function newStruct = setDotsParams(dots, someStruct)
        someStruct.density = dots.Density;
        someStruct.speed = dots.Speed;
        someStruct.diameter = dots.Diameter;
        someStruct.pixelSize = dots.PixelSize;
        someStruct.coherenceSTD = dots.CoherenceSTD;
        newStruct = someStruct;
    end


%-------------------------- CREATE TOPNODE
topNode = topsTreeNodeTopNode('oneCP');

    function ts = extract_timestamp(tn)
        % returns the timestamp as a string 'YYYY_MM_DD_HH_mm' associated 
        % with the topsTreeNodeTopNode object tn
        ts = regexprep(tn.filename, ...
            '[^[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{2}_[0-9]{2}]', '');
        ts = ts(1:16);
    end
timestamp = extract_timestamp(topNode);


%-------------------------- TURN DIARY ON (LOG CONSOLE OUTPUT TO FILE)
diary([dump_folder, 'session_console_',timestamp,'.log'])


%-------------------------- SET TOPNODE UP
topNode.addHelpers('screenEnsemble',  ...
    'displayIndex',      2, ...
    'remoteDrawing',     false, ...
    'topNode',           topNode);
%topNode.addReadable('dotsReadableHIDKeyboard');
topNode.addReadable('dotsReadableHIDGamepad');
% -1 means wait for keypress -- see topsTreeNode.pauseBeforeTask
pauseBeforeTask = -1; 

    function add_block(topnode, taskID, task_name, trials_file, ...
            stop_cond, block_description)
        % add a task to the topnode object
        t = topsTreeNodeTaskReversingDots4AFC(task_name);
        t.taskID = taskID;
        t.independentVariables=trials_file;
%        t.trialIterationMethod='sequential';
        t.randomizeWhenRepeating = false;
        t.pauseBeforeTask = pauseBeforeTask;
        t.stopCondition = stop_cond;
        
        % must be numeric
        t.subject = str2double(regexprep(subject_code,'[^0-9]',''));
        t.date = str2double(regexprep(timestamp,'_',''));  % must be numeric
        t.probCP = probCP;
        
        t.message.message.Instructions.text = {...
            block_description ...
        };
    
        % DOTS PROPERTIES
        oldDots = t.drawable.stimulusEnsemble.dots;
        t.drawable.stimulusEnsemble.dots = setDotsParams(ddots, oldDots);
    
        topnode.addChild(t);
    end

    function add_training_block(tid, name, condstop)
        add_block(topNode, tid, name, [name,'.csv'], condstop, ...
            {'training block',num2str(tid)})
    end


%-------------------------- ADD TRAINING BLOCKS TO TOPNODE
num_training_blocks=2;

stop_conditions = {...
    7, 'button' ...
    };

for jj = 1:num_training_blocks
    if jj == 2
        if probCP < .5
            add_training_block(jj, 'training_2_lowprob', stop_conditions{jj})
        else
            add_training_block(jj, 'training_2_highprob', stop_conditions{jj})
        end
    else
        add_training_block(jj, ['training_',num2str(jj)], stop_conditions{jj})
    end
end



%-------------------------- ADD OPTIONAL QUEST BLOCK TO TOPNODE
% only put Quest block if this is the first block of the day
if first_block_of_day
    questTask = topsTreeNodeTaskRTDots('Quest');
    questTask.taskID = 99;
    questTask.trialIterations = 60;
    questTask.timing.dotsDuration = 0.4;
    questTask.timing.showFeedback = 0;
    questTask.pauseBeforeTask = pauseBeforeTask;
    questTask.message.message.Instructions.text = {{'Quest block', ...
        'There are no switches'}};
    % DOTS PROPERTIES
    oldieDots = questTask.drawable.stimulusEnsemble.dots;
    questTask.drawable.stimulusEnsemble.dots = ...
        setDotsParams(ddots, oldieDots);
    topNode.addChild(questTask);

else
    % extract timestamp from full path
    ts = regexprep(quest_task_topsDataLog, ...
        '[^[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{2}_[0-9]{2}]', '');
    ts = ts(1:16);
    
    
    % get questTask from first topsDataLog of the day
    % right now, stops at first Quest block found
    [oldTopNode, ~] = topsTreeNodeTopNode.loadRawData('oneCP', ts);
    
    
    for tt = 1:length(oldTopNode.children)
        task_child = oldTopNode.children{tt};
        if strcmp(task_child.name,'Quest')
            questTask = task_child;
            break
        end
    end
end



%-------------------------- ADD TASK BLOCKS (4 by default)


ttt = topsTreeNodeTaskReversingDots4AFC('TASK');
ttt.timing.showFeedback = 0;
ttt.taskID = 100;

if probCP < 0.5
    task_file = 'Block1.csv';
    ttt.message.message.Instructions.text = {...
    {'REAL TASK', 'RARE SWITCHES'} ...
    };
else
    task_file = 'Block0.csv';
    ttt.message.message.Instructions.text = {...
    {'REAL TASK', 'FREQUENT SWITCHES'} ...
    };
end

ttt.independentVariables=task_file;
% ttt.trialIterationMethod='sequential';
ttt.randomizeWhenRepeating = false;
ttt.pauseBeforeTask = pauseBeforeTask;
ttt.stopCondition = 'button';

% subject, date and probCP must be numeric
ttt.subject = str2double(regexprep(subject_code,'[^0-9]',''));
ttt.date = str2double(regexprep(timestamp,'_',''));  
ttt.probCP = probCP;

% set theshold coherence obtained from Quest
if ~first_block_of_day
    threshold = questTask.getQuestThreshold();
    if (threshold <= 0) || (100 <= threshold)
        error(['invalid threshold of', num2str(threshold)])
    else
        ttt.questThreshold = threshold; 
    end
else
    % if threshold hasn't been estimated yet, pass the Quest task instead
    ttt.questThreshold = questTask;
end

% DOTS PROPERTIES
oldieDots = ttt.drawable.stimulusEnsemble.dots;
ttt.drawable.stimulusEnsemble.dots = ...
    setDotsParams(ddots, oldieDots);

topNode.addChild(ttt);


%-------------------------- RUN TOPNODE

topNode.run();


%-------------------------- DUMP FIRA INFO (ONE FILE PER BLOCK)

    function dumpFIRA(topnode, child)
        task = topnode.children{child};
        csvfile = ...
            [dump_folder, 'completed4AFCtrials_task', ...
            num2str(task.taskID), '_date_', ...
            timestamp,'.csv'];
        task.saveTrials(csvfile, 'all');
    end

num_children = length(topNode.children);

for c = 1:num_children
    if numel(topNode.children{c}.trialData)
        dumpFIRA(topNode, c)
    end
end

%-------------------------- TURN OFF DIARY
disp(['file with timestamp ', timestamp, ' produced'])
diary off
end
