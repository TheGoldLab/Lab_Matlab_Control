function [sessionTree, tList]=configCounter

tList = topsGroupedList;
tList{'control'}{'maxCount'} = 3;
tList{'control'}{'count'} = tList{'control'}{'maxCount'};
tList{'control'}{'remote'} = 1;
tList{'control'}{'fullScreen'} = 1;
tList{'graphics'}{'textSize'} = 30;

%% Graphics
dm = dotsTheDrawablesManager.theObject;

if tList{'control'}{'remote'}
    dm.reset('serverMode', false, 'clientMode', true);   % try dotsTheDrawablesManager.reset instead?       % reset also initiliaze
else
    dm.reset('serverMode', false, 'clientMode', false);
end

if tList{'control'}{'fullScreen'}
    dm.setScreenProperty('displayRect', []);
end

dm.setScreenTextSetting('TextSize', tList{'graphics'}{'textSize'});

% dotsDrawableText object
text = dm.newObject('dotsDrawableText');
text.string = 'Press any key to begin.';
text.isVisible = true;
tList{'graphics'}{'text'} = text;

% dotsDrawableTargets object
targs = dm.newObject('dotsDrawableTargets');
targs.dotSize = 5;
% targs.density = 40;
targs.x = [-.5 .5];
targs.y = [1 1]*tList{'control'}{'maxCount'};
targs.isVisible = true;
tList{'graphics'}{'targs'} = targs;

% dotsDrawableDotKinetogram object
stim = dm.newObject('dotsDrawableDotKinetogram');
stim.dotSize = 3;
stim.density = 40;
stim.diameter = 10;
stim.speed = 6;
stim.x = 0;
stim.y = 0;
stim.isVisible = true;
tList{'graphics'}{'stim'} = stim;

dm.addObjectToGroup(text,'first');
dm.addObjectToGroup(targs,'first');
dm.activateGroup('first');

dm.addObjectToGroup(targs, 'text');
dm.addObjectToGroup(stim, 'text');
dm.addObjectToGroup(text, 'text');
% dm.activateGroup('text');

%% Input
taskName = 'counter';
qm = dotsTheQueryablesManager.theObject;
gp = qm.newObject('dotsQueryableHIDGamepad');
tList{'input'}{'gamepad'} = gp;
if gp.isAvailable
    left = gp.phenomenons{'pressed'}{'pressed_button_5'};   % L finger key
    right = gp.phenomenons{'pressed'}{'pressed_button_6'};  % R finger key
    
    % 'escape' key
    pressL = gp.phenomenons{'axes'}{'any_axis'};  % left set of keys
    pressR = gp.phenomenons{'pressed'}{'any_pressed'};  % right set
    quit = dotsPhenomenon.composite([pressL,pressR],'intersection');
    
    % any key
    any = dotsPhenomenon.composite([pressL,pressR],'union');

    hid = gp;
else
    kb = qm.newObject('dotsQueryableHIDKeyboard');
    tList{'input'}{'keyboard'} = kb;
    left = kb.phenomenons{'pressed'}{'pressed_KeyboardLeftArrow'};
    right = kb.phenomenons{'pressed'}{'pressed_KeyboardRightArrow'};
    quit = kb.phenomenons{'pressed'}{'pressed_KeyboardEscape'};

    any = dotsPhenomenon.composite([left,right],'union');
    
    hid = kb;
end
tList{'input'}{'using'} = hid;
% classify phenomenons to produce arbitrary outputs
%   each output will match a state name, below
hid.addClassificationInGroupWithRank(left, 'leftward', taskName, 1);
hid.addClassificationInGroupWithRank(right, 'rightward', taskName, 2);
hid.addClassificationInGroupWithRank(quit, 'quit', taskName, 3);
hid.addClassificationInGroupWithRank(any, 'anyPressed', taskName, 4);
hid.activeClassificationGroup = taskName;

%% Tree
sessionTree = topsTreeNode;
sessionTree.name = 'sessionTree';
sessionTree.iterations = 1;
sessionTree.startFevalable={@openScreenWindow, dm};
sessionTree.finishFevalable={@closeScreenWindow, dm};

%% Blocks
questBlock = sessionTree.newChildNode;
questBlock.name = '  questBlock';
questBlock.iterations = 1;
questBlock.startFevalable={@dispStuff, questBlock};
questBlock.finishFevalable={@dispStuff, questBlock};

% count down timer
countDownM = topsStateMachine;
countDownM.name = 'countDownM';
cDown = {@startCountDown,tList};
cCount = {@checkCountDown,tList};
% sCount = {@startScreen,tList};

QR = {@queryAsOfTime, hid};

cdStates = { ...
    'name',          'entry', 'timeout', 'input', 'exit',       'next';...
    'start',          {},       inf,      QR,     {},  'countDown';...
    'countDown',       cDown,         1,      {}, cCount, 'checkCount';...
    'checkCount',         {},         0,      {},     {},           '';...
    'anyPressed',         {},         0,      {},     {},  'countDown';...
    'leftward',           {},         0,      {},     {},  'countDown';...
    };
countDownM.addMultipleStates(cdStates);
tList{'control'}{'countDownM'} = countDownM;

trialCalls = topsCallList;
trialCalls.name = 'call functions';
trialCalls.alwaysRunning = true;
% trialCalls.startFevalable = {@mayDrawNextFrame, dm, true};        % not
% in Shilpa's
trialCalls.addCall({@readData, hid});
trialCalls.addCall({@mayDrawNextFrame, dm});
% trialCalls.finishFevalable = {@mayDrawNextFrame, dm, false};   % not in
% Shilpa's

countDownCc = topsConcurrentComposite;
countDownCc.name = 'countDownCc';
countDownCc.addChild(dm);   
countDownCc.addChild(trialCalls);
countDownCc.addChild(countDownM);

questBlock.addChild(countDownCc);

% questTrial = questBlock.newChildNode;
% questTrial.name = '    questTrial';
% questTrial.iterations = 5;
% questTrial.startFevalable={@dispStuff, questTrial};
% questTrial.finishFevalable={@dispStuff, questTrial};
% 
% questStartMachine = topsStateMachine; 
% questStartMachine.name = '      questStartMachine';
% questStartMachine.startFevalable={@dispMachine,questStartMachine};
% 
% questTaskMachine = topsStateMachine; 
% questTaskMachine.name = '      questTaskMachine';
% questTaskMachine.startFevalable={@dispMachine,questTaskMachine};
% 
% questTaskConcurrents = topsConcurrentComposite;
% questTaskConcurrents.name = 'questTaskConcurrents';
% questTaskConcurrents.addChild(questTaskMachine);
% 
% questTrial.addChild(questTaskConcurrents);


function startCountDown(tList)
counter = tList{'control'}{'count'};

text = tList{'graphics'}{'text'};
text.string = num2str(counter);
hide(text);

targs = tList{'graphics'}{'targs'};
targs.y = ones(size(targs.y))*(counter-1);

stim = tList{'graphics'}{'stim'};

disp(['counter ' num2str(counter)]);
if counter == tList{'control'}{'maxCount'};
    dm = dotsTheDrawablesManager.theObject;
    dm.activateGroup('text');
%     show(text);
%     show(targs);
%     show(stim);
end




function checkCountDown(tList)
counter = tList{'control'}{'count'};
machine = tList{'control'}{'countDownM'};

if counter > 1
    counter = counter - 1;
    machine.editStateByName('checkCount','next','countDown');
else
    counter = tList{'control'}{'maxCount'};
    hide(tList{'graphics'}{'text'});
    machine.editStateByName('checkCount','next','');
end
tList{'control'}{'count'} = counter;

function dispStuff(treeNode)
% disp('dispStuff');
if strfind(treeNode.name,'Tree')
    disp([treeNode.name]);
else
    disp([treeNode.name num2str(treeNode.caller.iterationCount)]);
end

function dispMachine(machine)
% disp('dispMachine');
if strfind (machine.name, 'Start')
    if machine.caller.caller.iterationCount == 1
        disp([machine.name '.caller.caller.iterationCount = ' num2str(machine.caller.caller.iterationCount)]);
    else
        machine.finish;
    end
else
    disp([machine.name '.caller.caller.iterationCount = ' num2str(machine.caller.caller.iterationCount)]);
end