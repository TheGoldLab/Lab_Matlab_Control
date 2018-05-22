function addStimulusFramesForSAT(state)
% addStimulusFramesForSAT(state)
% 
% This function adds four additional frames to the graphics field in state.
% Two are for the 'Fast'/'Accurate' cues and the other two are for feedback
% during the 'Fast' trials. All four new frames are words displayed at the
% center of the screen.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 9/19/17    xd  wrote it

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

%% Create SAT cues

speedCue = dotsDrawableText();
speedCue.string = 'Fast';

accuracyCue = dotsDrawableText();
accuracyCue.string = 'Accurate';

speedE = ensembleFunction('speed');
speedE.addObject(speedCue);
speedE.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

accuracyE = ensembleFunction('accuracy');
accuracyE.addObject(accuracyCue);
accuracyE.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

state{'graphics'}{'fastCue'} = speedE;
state{'graphics'}{'accurateCue'} = accuracyE;

%% Create BIAS cues

t1 = dotsDrawableText();
t1.string = '3:1';

t2 = dotsDrawableText();
t2.string = '1:3';

t1E = ensembleFunction('T1');
t1E.addObject(t1);
t1E.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

t2E = ensembleFunction('T2');
t2E.addObject(t2);
t2E.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

state{'graphics'}{'T1Cue'} = t1E;
state{'graphics'}{'T2Cue'} = t2E;

%% Create 'Fast' trial feedback
inTimeFeedback = dotsDrawableText();
inTimeFeedback.string = 'In time';

slowFeedback = dotsDrawableText();
slowFeedback.string = 'Too slow';

intimeE = ensembleFunction('inTime');
intimeE.addObject(inTimeFeedback);
intimeE.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

slowE = ensembleFunction('slow');
slowE.addObject(slowFeedback);
slowE.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

state{'graphics'}{'intimeFeedback'} = intimeE;
state{'graphics'}{'slowFeedback'} = slowE;

end

