function createStimulusFrame(state,coherence,direction)
% createStimulusFrame(state,coherence,direction)
%
% Generates the moving dots stimulus using the coherence and direction
% values given as parameters. The frame is then added to the state under
% 'graphics'. This allows the rest of the program to draw it when
% necessary.
%
% Inputs:
%   state      -  A topsGroupedList object containing experimental parameters
%                 as well as data recorded during the experiment.
%   coherence  -  A single number describing the coherence of the dots for
%                 this stimulus.
%   direction  -  A single number (degrees) describing the direction of
%                 general motion.
%
% 10/2/17    xd  wrote it 

%% Check whether we want to use a client-server set up
usingRemote = state.containsGroup('Remote');
if ~usingRemote
    ensembleFunction = @(X)topsEnsemble;
else
    clientIP = state{'Remote'}{'clientIP'};
    clientPort = state{'Remote'}{'clientPort'};
    serverIP = state{'Remote'}{'serverIP'};
    serverPort = state{'Remote'}{'serverPort'};
    ensembleFunction = @(X)dotsClientEnsemble(X,clientIP,clientPort,serverIP,serverPort);
end

%% Generate stimulus
saccadeTargets = state{'graphics'}{'saccadeTargetsFrame'};

% Assign parameters from the state object to the moving dots drawable.
movingDotStim = dotsDrawableDotKinetogram();
movingDotStim.stencilNumber = state{'MovingDots'}{'stencilNumber'};
movingDotStim.pixelSize = state{'MovingDots'}{'pixelSize'};
movingDotStim.diameter = state{'MovingDots'}{'diameter'};
movingDotStim.density = state{'MovingDots'}{'density'};
movingDotStim.speed = state{'MovingDots'}{'speed'};
movingDotStim.yCenter = 0;
movingDotStim.xCenter = 0;
movingDotStim.direction = direction;
movingDotStim.coherence = coherence;

% Combine the moving dots stimulus and the saccade targets into a
% topsEnsemble so that we can draw both of them simultaneously on the
% screen.
stimulusAndSaccadeTargets = ensembleFunction('stimulusAndSaccadeTargets');
stimulusAndSaccadeTargets.addObject(movingDotStim);
stimulusAndSaccadeTargets.addObject(saccadeTargets);
stimulusAndSaccadeTargets.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

% Save the stimulus to the state to be used by other functions
state{'graphics'}{'stimulusAndSaccadeTargets'} = stimulusAndSaccadeTargets;

end

