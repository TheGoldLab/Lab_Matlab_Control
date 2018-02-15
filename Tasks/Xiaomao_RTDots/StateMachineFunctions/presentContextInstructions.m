function presentContextInstructions(state)
% presentContextInstructions(state)
% 
% This is run at the start of each trial. If we are in a context switch,
% then it presents the instructions for the next block of trials which all
% follow the same context. Otherwise, this function does nothing.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 9/21/17    xd  wrote it

%% Check that we are in SAT/BIAS
if state{'Flag'}{'QUEST'} || state{'Flag'}{'meanRT'} || state{'Flag'}{'coherence'} %#ok<BDSCA>
    return;
end

%% Check if context switch
switchContext = state{'SAT/BIAS'}{'contextSwitch'};
if switchContext
    contexts = state{'SAT/BIAS'}{'contexts'};
    contextCounter = state{'SAT/BIAS'}{'contextCounter'};
    
    % Load graphics object based on which context we are about to switch
    % into.
    switch contexts{contextCounter}
        case 'A'
            instructions = state{'graphics'}{'accurateCue'};
        case 'S'
            instructions = state{'graphics'}{'fastCue'};
        case 'T1' 
            instructions = state{'graphics'}{'T1Cue'};
        case 'T2'
            instructions = state{'graphics'}{'T2Cue'};
    end
    
    % Present the graphics object for the pre-specified duration.
    instructions.callObjectMethod(@prepareToDrawInWindow);
    instructions.run(state{'Timing'}{'instructionPresentation'});
    
    state{'SAT/BIAS'}{'contextSwitch'} = false;
end

end

