classdef topsTreeNodeTaskReversingDots4AFC < topsTreeNodeTask
    % @class topsTreeNodeTaskReversingDots4AFC
    %
    % Reversing dots (RD) task
    %
    % For standard configurations, call:
    %  topsTreeNodeTaskReversingDots.getStandardConfiguration
    %
    % Otherwise:
    %  1. Create an instance directly:
    %        task = topsTreeNodeTaskReversingDots();
    %
    %  2. Set properties. These are required:
    %        task.screenEnsemble
    %        task.helpers.readers.theObject
    %     Others can use defaults
    %
    %  3. Add this as a child to another topsTreeNode
    %
    % 10/01/19 created by aer
    
    properties % (SetObservable)
        
        % Trial properties.
        %
        % Set useQuest to a handle to a topsTreeNodeTaskRTDots to use it
        %     to get coherences
        settings = struct( ...
            'useQuest',                   [],   ...
            'valsFromQuest',              [],   ... % % cor vals on pmf to get
            'targetDistance',             8,    ...
            'dotsSeedBase',               1, ...
            'reversalSet',                [0.3 0.6 0.9], ... % if reversal<-1
            'reversalType',               'time'); % 'time' or 'hazard'; see prepareDrawables
        
        % Timing properties, referenced in statelist
        timing = struct( ...
            'fixationTimeout',           5.0,   ...
            'holdFixation',              0,   ...
            'duration',                  [0.2 0.5 1.0], ... % min mean max
            'finalEpochDuration',        [],    ...
            'minEpochDuration',          0.1,   ...
            'maxEpochDuration',          5.0,   ...
            'minimumRT',                 0.05,  ...
            'showFeedback',              0.5,   ...
            'interTrialInterval',        1.0,   ...
            'preDots',                   [0.1 0.3 0.6], ...
            'dotsTimeout',               5.0,   ...
            'choiceTimeout',             8.0);
        
        % Fields below are optional but if found with the given names
        %  will be used to automatically configure the task
        
        % Array of structures of independent variables, used by makeTrials
        % NOTE that this is the simple way of setting up this struct. You can
        % also still use:
        %  indepdendentVariables = struct( ...
        %     'direction',   struct('values', [0 180], 'priors', []), ...
        %     etc.
        independentVariables = struct( ...
            'direction',      [0 180],   ...
            'coherence',      90,        ...
            'reversal',       [0.2 0.5], ...
            'duration',       1.0,       ...
            'finalDuration',  []);
        
        % dataFieldNames are used to set up the trialData structure
        trialDataFields = { ...
            'RT', ...
            'cpRT', ...
            'dirChoice', ...
            'cpChoice', ...
            'dirCorrect', ...
            'cpCorrect', ...
            'direction', ...
            'coherence', ...
            'randSeedBase', ...
            'fixationOn', ...
            'fixationStart', ...
            'targetOn', ...
            'dotsOn', ...
            'finalCPTime', ...  % actual CP time
            'dotsOff', ...
            'choiceTime', ...
            'cpChoiceTime', ...
            'blankScreen', ...
            'feedbackOn', ...
            'subject', ...
            'date', ...
            'probCP', ...
            'cpScreenOn', ...
            'dummyBlank', ...
            'cpTimeDotsClock', ...
            'firstDraw', ...
            'lastDraw', ...
            'firstDrawPostCP', ...
            'numberDrawPreCP', ...
            'numberDrawPostCP'};
        
        % Drawables settings
        drawable = struct( ...
            ...
            ...   % Stimulus ensemble and settings
            'stimulusEnsemble',           struct( ...
            ...
            ...   % Fixation drawable settings
            'fixation',                   struct( ...
            'fevalable',                  @dotsDrawableTargets, ...
            'settings',                   struct( ...
            'xCenter',                    0,                ...
            'yCenter',                    0,                ...
            'nSides',                     4,                ...
            'width',                      0.5.*[1.0 0.1],   ...
            'height',                     0.5.*[0.1 1.0],   ...
            'colors',                     [1 1 1])),        ...
            ...
            ...   % Targets drawable settings
            'targets',                    struct( ...
            'fevalable',                  @dotsDrawableTargets, ...
            'settings',                   struct( ...
            'nSides',                     100,              ...
            'width',                      1.3.*[1 1],       ...
            'height',                     1.3.*[1 1])),      ...
            ...
            ...   % Dots drawable settings
            'dots',                       struct( ...
            'fevalable',                  @sdotsDrawableDotKinetogramDebug, ...
            'settings',                   struct( ...
            'xCenter',                    0,                ...
            'yCenter',                    0,                ...
            'coherenceSTD',               10,               ...
            'stencilNumber',              1,                ...
            'pixelSize',                  6,                ...
            'diameter',                   8,                ...
            'density',                    150,              ...
            'speed',                      5)), ...
            ...   % CP Targets drawable settings
            'cpScreen',                   struct( ...
            'fevalable',                  @dotsDrawableText, ...
            'settings',                   struct( ...
            'x',                          0, ...
            'y',                          0))));
        
        % Readable settings
        readable = struct( ...
            ...
            ...   % The readable object
            'reader',                    	struct( ...
            ...
            'copySpecs',                  struct( ...
            ...
            ...   % The keyboard events .. 'uiType' is used to conditionally use these depending on the theObject type
            'dotsReadableHIDKeyboard',    struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'choseTopLeft', 'choseTopRight', 'choseBottomLeft', 'choseBottomRight'}, ...
            'component',                  {'KeyboardSpacebar', 'KeyboardA', 'KeyboardK', 'KeyboardZ', 'KeyboardM'}, ...
            'isRelease',                  {true, false, false, false, false})}}), ...
            ...
            ...   % Gamepad
            'dotsReadableHIDGamepad',     struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'choseLeft', 'choseRight', 'nocpResponse'}, ...
            'component',                  {'Button1', 'Trigger1', 'Trigger2', 'Button2'}, ...  %i.e. A button, Left Trigger, Right Trigger, B button
            'isRelease',                  {true, false, false, false})}}), ...
            ...
            ...   % Dummy to run in demo mode
            'dotsReadableDummy',          struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
            'component',                  {'Dummy1', 'Dummy2', 'Dummy3'})}}))));
        
        % Feedback messages
        message = struct( ...
            ...
            'message',                    struct( ...
            ...
            ...   Instructions
            'Instructions',               struct( ...
            'text',                       {{'bleble', 'blabla'}}, ...
            'duration',                   1, ...
            'pauseDuration',              0.5, ...
            'bgEnd',                      [0 0 0]), ...
            ...
            ...   Correct
            'Correct',                    struct(  ...
            'text',                       'Correct', ...
            ...%'playable',                   'cashRegister.wav', ...
            'bgStart',                    [0 0.25 0], ...
            'bgEnd',                      [0 0 0]), ...
            ...
            ...   Error
            'Error',                      struct(  ...
            'text',                       'Error', ...
            ...%'playable',                   'buzzer.wav', ...
            'bgStart',                    [0.25 0 0], ...
            'bgEnd',                      [0 0 0]), ...
            ...
            ...   No choice
            'No_choice',                  struct(  ...
            'text',                       'No choice - please try again!')));
        
        % metadata
        subject;
        date;
        probCP;
        questThreshold;
        
        % stop condition
        stopCondition;
        consecutiveCorrect;
    end
    
    properties (SetAccess = protected)
        
        % Check for changes in properties that require drawables to be recomputed
        targetDistance;
        
        % Reversal directions/times -- precomputed for each trial and then executed.
        reversals = struct('directions', [], 'plannedTimes', [], ...
            'actualTimes', []);
        
        % Keep track of reversals
        nextReversal;
        
        % indices for drawable objects
        fpIndex;
        targetIndex;
        dotsIndex;
        cpScreenIndex;
    end
    
    methods
        
        %% Constuctor
        %  Use topsTreeNodeTask method, which can parse the argument list
        %  that can set properties (even those nested in structs)
        function self = topsTreeNodeTaskReversingDots4AFC(varargin)
            
            % ---- Make it from the superclass
            %
            self = self@topsTreeNodeTask(varargin{:});
        end
        
        %% Start task (overloaded)
        %
        % Put stuff here that you want to do before each time you run this
        % task
        function startTask(self)
            if ~isempty(self.questThreshold)
                if ~isnumeric(self.questThreshold)
                    self.questThreshold = ...
                        self.questThreshold.getQuestThreshold();
                    if self.questThreshold <= 0 || ...
                            self.questThreshold >= 100
                        error(['Invalid questThreshold of ', ...
                            num2str(self.questThreshold)])
                    end
                end
            end
            self.consecutiveCorrect = 0;
            
            if ~isempty(self.settings.useQuest)
                
                % Update independent variable struct using Quest threshold
                self.independentVariables.coherence = ...
                    self.settings.useQuest.getQuestThreshold( ...
                    self.settings.valsFromQuest);
            end
            
            % ---- Get some useful indices
            %
            fn               = fieldnames(self.drawable.stimulusEnsemble);
            self.fpIndex     = find(strcmp('fixation', fn));
            self.targetIndex = find(strcmp('targets', fn));
            self.dotsIndex   = find(strcmp('dots', fn));
            self.cpScreenIndex = find(strcmp('cpScreen', fn));
            
            % ---- Initialize the state machine
            %
            self.initializeStateMachine();
            
            % ---- Show task-specific instructions
            %
            self.helpers.message.show('Instructions');
        end
        
        %% Finish task (overloaded)
        %
        % Put stuff here that you want to do after each time you run this
        % task
        function finishTask(self)
        end
        
        %% Start trial
        %
        % Put stuff here that you want to do before each time you run a trial
        function startTrial(self)
            
            % ---- Prepare components
            %
            self.prepareDrawables();
            
            % ---- Use the task ITI
            %
            self.interTrialInterval = self.timing.interTrialInterval;
            
            % ---- Show information about the task/trial
            %
            % Task information
            taskString = sprintf('%s (task %d/%d): %d dirCorrect, %d cpCorrect, %d dirError, %d cpError, mean RT=%.2f', ...
                self.name, self.taskID, length(self.caller.children), ...
                sum([self.trialData.dirCorrect]==1), ...
                sum([self.trialData.cpCorrect]==1), ...
                sum([self.trialData.dirCorrect]==0), ...
                sum([self.trialData.cpCorrect]==0), ...
                nanmean([self.trialData.RT]));
            
            % Trial information
            trial = self.getTrial();
            if ~isempty(self.reversals)
                numReversals = length(self.reversals.plannedTimes)-1;
            else
                numReversals = 0;
            end
            
            trialString = sprintf('Trial %d/%d, coh=%.0f, dur=%.2f, nflips=%d', ...
                self.trialCount, numel(self.trialData), trial.coherence, ...
                trial.duration, numReversals);
            
            % Show the information on the GUI
            self.updateStatus(taskString, trialString); % just update the second one
        end
        
        %% Finish Trial
        %
        % Could add stuff here
        function finishTrial(self)
            % update running count of consecutive correct trials
            trial = self.getTrial();
            dcorr = trial.dirCorrect;
            ccorr = trial.cpCorrect;
            
            % fetch important properties from the dotsDrawableDotKinetogram
            % in order to be able to reproduce the dots at a later stage
            dDDK = self.helpers.stimulusEnsemble.theObject;
            trial.firstDraw = dDDK.getObjectProperty( ...
                'firstDraw', ...
                self.dotsIndex);
            trial.firstDrawPostCP = dDDK.getObjectProperty( ...
                'firstDrawPostCP', ...
                self.dotsIndex);
            trial.lastDraw = dDDK.getObjectProperty( ...
                'lastDraw', ...
                self.dotsIndex);
            trial.numberDrawPreCP = dDDK.getObjectProperty( ...
                'numberDrawPreCP', ...
                self.dotsIndex);
            trial.numberDrawPostCP = dDDK.getObjectProperty( ...
                'numberDrawPostCP', ...
                self.dotsIndex);
            trial.cpTimeDotsClock = dDDK.getObjectProperty( ...
                'cpTimeDotsClock', ...
                self.dotsIndex);
            self.setTrial(trial);
            
            if ~isnan(ccorr) && ~isnan(dcorr)
                if dcorr && ccorr
                    self.consecutiveCorrect = self.consecutiveCorrect + 1;
                    if isnumeric(self.stopCondition) && ...
                            self.consecutiveCorrect == self.stopCondition
                        self.abort()
                    end
                else
                    self.consecutiveCorrect = 0;
                end
            end
        end
        
        %% Check for flip
        %
        %
        function next = checkForReversal(self)
            
            % For now, never return anything
            next = '';
            
            % Make sure we're reversing
            if isempty(self.nextReversal)
                return
            end
            
            % Get the trial for timing info
            trial = self.getTrial();
            
            % Check for reversal
            if feval(self.clockFunction) - trial.trialStart - trial.dotsOn >= ...
                    self.reversals.plannedTimes(self.nextReversal)
                
                % Reverse!
                %
                % Set the direction
                eh = self.helpers.stimulusEnsemble;
                eh.theObject.setObjectProperty('direction', ...
                    self.reversals.directions(self.nextReversal), ...
                    self.dotsIndex);
                eh.theObject.setObjectProperty('passedCP', true, ...
                    self.dotsIndex);
                eh.theObject.setObjectProperty('cpTimeDotsClock', ...
                    now, self.dotsIndex);
                
                % Explicitly flip here so we can get the timestamp
                frameInfo = eh.theObject.callObjectMethod(...
                    @dotsDrawable.drawFrame, {}, [], true);
                
                % Save the time in SCREEN time
                self.reversals.actualTimes(self.nextReversal) = ...
                    eh.getSynchronizedTime(frameInfo.onsetTime, true) - ...
                    trial.dotsOn;
                
                % For debugging
                fprintf('FLIPPED to %d at time: %.2f planned, %.2f actual\n', ...
                    self.reversals.directions(self.nextReversal), ...
                    self.reversals.plannedTimes(self.nextReversal), ...
                    self.reversals.actualTimes(self.nextReversal))
                
                % update the counter
                self.nextReversal = self.nextReversal + 1;
                if self.nextReversal > length(self.reversals.plannedTimes)
                    self.nextReversal = [];
                end
            end
        end
        
        %% Check for choice
        %
        % Save choice/RT information and set up feedback for the dots task
        function nextState = checkForChoice(self, events, eventTag, ...
                nextStateAfterChoice)
%             disp('JUST ENTERED CHECK FOR CHOICE')
%             disp('events are')
%             disp(events)
%             
            % ---- Check for event
            %
            eventName = self.helpers.reader.readEvent(events, self, ...
                eventTag);

            % Default return
            nextState = [];
            
            % Nothing... keep checking
            if isempty(eventName)
                return
            end
            isCPchoice = strcmp(eventName, 'holdFixation') || ...
                strcmp(eventName, 'nocpResponse');
%             disp('detected Event')
%             disp(eventName)
%             
            % Get current task/trial
            trial = self.getTrial();
            
            % ---- Good choice!
            %
            if isCPchoice
                % Override completedTrial flag
                self.completedTrial = true;
                trial.cpRT = trial.cpChoiceTime - trial.choiceTime;
            else
                % Check for minimum RT, wrt dotsOn for RT, dotsOff for non-RT
                RT = trial.choiceTime - trial.dotsOff;
                % Save RT
                trial.RT = RT;
                if RT < self.timing.minimumRT
                    % write metadata (same for all trials)
                    trial.subject = self.subject;
                    trial.date = self.date;
                    trial.probCP = self.probCP;
                    self.setTrial(trial);
                    return
                end
            end
            
            % Jump to next state when done
            nextState = nextStateAfterChoice;
            
            % Save the choice
            if isCPchoice
                trial.cpChoice = double(strcmp(eventName, 'holdFixation'));
                trial.cpCorrect = double(...
                    (trial.cpChoice==0 && trial.reversal == 0) || ...
                    (trial.cpChoice==1 && trial.reversal ~= 0));
            else
                trial.dirChoice = double(strcmp(eventName, 'choseRight'));
                % Mark as correct/error
                trial.dirCorrect = double( ...
                    (trial.dirChoice==0 && cosd(trial.direction)<0) || ...
                    (trial.dirChoice==1 && cosd(trial.direction)>0));
            end

            % Save the final reversal time
            if ~isempty(self.reversals)
                trial.finalCPTime = self.reversals.actualTimes(end);
            end
            
            % Store the reversal times
            topsDataLog.logDataInGroup(self.reversals, ...
                'ReversingDotsReversals');
            
            % write metadata (same for all trials)
            trial.subject = self.subject;
            trial.date = self.date;
            trial.probCP = self.probCP;
            
            % ---- Re-save the trial
            %
            self.setTrial(trial);
        end
        
        %% Show feedback
        %
        function showFeedback(self)
            
            % Get current task/trial
            trial = self.getTrial();
            
            % Get feedback message group
            if trial.dirCorrect * trial.cpCorrect == 1
                messageGroup = 'Correct';
            elseif trial.dirCorrect * trial.cpCorrect == 0
                messageGroup = 'Error';
            else
                messageGroup = 'No_choice';
            end
            
            % --- Show trial feedback in GUI/text window
            %
            trialString = ...
                sprintf('Trial %d/%d: %s, RT=%.2f', ...
                self.trialCount, numel(self.trialData), ...
                messageGroup, trial.RT);
            self.updateStatus([], trialString); % just update the second one
            
            % ---- Show trial feedback on the screen
            %
            if self.timing.showFeedback > 0
                self.helpers.message.show(messageGroup, self, ...
                    'feedbackOn');
            end
        end
        
%         function displayCPchoiceScreen(self)
%                 % do nothing on purpose
%         end
    end
    
    methods (Access = protected)
        
        %% Prepare drawables for this trial
        %
        function prepareDrawables(self)
            
            % ---- Get the current trial and other useful stuff, and set
            %        values
            %
            trial = self.getTrial();
            
            % negative coherence in the .csv file is our way to code for
            % threshold coherence
            if trial.coherence < 0
                trial.coherence = self.questThreshold;
            end
            
            % Set the seed base for the random number generator
            trial.randSeedBase = trial.trialIndex; %sum(clock*10);
            
            % Set the dots duration if not already given in trial struct
            if ~isfinite(trial.duration)
                trial.duration = self.timing.duration; % Set the dots duration
            end
            
            % Funny value in case we want to control timing after final
            % change-point
            if ~isfinite(trial.finalDuration)
                trial.finalDuration = self.timing.finalEpochDuration;
            end
            
            % ---- Compute reversal times, start/final directions
            %
            % Defaults -- no flippy!
            self.reversals    = [];
            self.nextReversal = [];
            startDirection    = trial.direction;
            
            % Use trial.reversal property
            if trial.reversal ~= 0
                
                % Setting up reversals array
                switch(self.settings.reversalType)
                    case 'hazard'
                        
                        % Interpret "reversal" as fixed hazard rate.
                        [plannedTimes, trial.duration] = ...
                            computeChangePoints(trial.reversal, ...
                            self.timing.minEpochDuration, ...
                            self.timing.maxEpochDuration, ...
                            trial.duration, ...
                            trial.finalDuration);
                        
                    otherwise % case 'time'
                        
                        % Special case -- check if trial.reversal < 0 ... if so,
                        % that's just a flag saying to use the set
                        if trial.reversal < 0
                            plannedTimes = self.settings.reversalSet;
                        else
                            plannedTimes = trial.reversal;
                        end
                        
                        % Strip unnecessary values
                        plannedTimes = plannedTimes(plannedTimes < ...
                            trial.duration);
                end
                
                % Check that we have reversals
                numReversals = length(plannedTimes);
                if numReversals > 0
                    
                    % Set up reversals struct, with one entry per direction epoch
                    otherDirection = setdiff(...
                        self.independentVariables.direction, ...
                        trial.direction);
                    self.reversals.directions = repmat(trial.direction, ...
                        1, numReversals+1);
                    self.reversals.directions(end:-2:1) = otherDirection;
                    self.reversals.plannedTimes = [0 plannedTimes];
                    self.reversals.actualTimes  = ...
                        [0 nans(1, numReversals)];
                    self.nextReversal           = 2;
                    startDirection              = ...
                        self.reversals.directions(1);
                    % note how trial.direction represents the direction of 
                    % motion in the last epoch of the trial
                    trial.direction             = ...
                        self.reversals.directions(end);  
                end
            end
            
            % Set the dots duration in the statelist
            self.stateMachine.editStateByName('showDots', 'timeout', ...
                trial.duration);
            
            % ---- Possibly update all stimulusEnsemble objects if settings
            %        changed
            %
            ensemble = self.helpers.stimulusEnsemble.theObject;
            td       = self.settings.targetDistance;
            if isempty(self.targetDistance) || self.targetDistance ~= td
                
                % Save current value(s)
                self.targetDistance = self.settings.targetDistance;
                
                %  Get target locations relative to fp location
                fpX = ensemble.getObjectProperty('xCenter', self.fpIndex);
                fpY = ensemble.getObjectProperty('yCenter', self.fpIndex);
                
                %  Now set the targets x,y
                ensemble.setObjectProperty('xCenter', ...
                    [fpX + td, fpX - td], self.targetIndex);
                ensemble.setObjectProperty('yCenter', ...
                    [fpY, fpY], self.targetIndex);
            end
            
            % ---- Save dots properties
            %
            ensemble.setObjectProperty('randBase',  trial.randSeedBase, ...
                self.dotsIndex);
            ensemble.setObjectProperty('coherence', trial.coherence, ...
                self.dotsIndex);
            ensemble.setObjectProperty('direction', startDirection, ...
                self.dotsIndex);
            
            % reset the timestamps and draw counters for current trial
            ensemble.setObjectProperty('firstDraw', nan, self.dotsIndex);
            ensemble.setObjectProperty('firstDrawPostCP', nan, ...
                self.dotsIndex);
            ensemble.setObjectProperty('lastDraw', nan, self.dotsIndex);
            ensemble.setObjectProperty('numberDrawPreCP', 0, ...
                self.dotsIndex);
            ensemble.setObjectProperty('numberDrawPostCP', 0, ...
                self.dotsIndex);
            ensemble.setObjectProperty('cpTimeDotsClock', nan, ...
                self.dotsIndex);
            ensemble.setObjectProperty('passedCP', false, self.dotsIndex);
            
            self.setTrial(trial);
            
            % ---- Set CP screen instructions
            %
%             ensemble.setObjectProperty('string', 'switch', 5);
            ensemble.setObjectProperty('string', ...
                'WAS THERE A SWITCH? (YES=A / NO=B)', ...
                 self.cpScreenIndex);
         
            
            % ---- Prepare to draw dots stimulus
            %
            ensemble.callObjectMethod(@prepareToDrawInWindow);
            
            % ---- Save the trial
            self.setTrial(trial);
        end
        
        %% Initialize StateMachine
        %
        function initializeStateMachine(self)
            
            % ---- Fevalables for state list
            %
            % blanks  = {@dotsTheScreen.blankScreen};
            blanks  = {@blankScreen, self, 'blankScreen'};
            
            % chkuif  = {@getNextEvent, self.helpers.reader.theObject, false, {'holdFixation'}};
            chkuif  = {@getNextEvent, self.helpers.reader.theObject, false, {'holdFixation'}};
            
            chkuib  = {}; % {@getNextEvent, self.readables.theObject, false, {}}; % {'brokeFixation'}
            
            chkuic  = {@checkForChoice, self, {'choseLeft' 'choseRight'}, ...
                'choiceTime', 'waitForCPchoice'};
            
            chkuicp  = {@checkForChoice, self, ...
                {'holdFixation' 'nocpResponse'}, 'cpChoiceTime', 'blank'};
            
            chkrev  = {@checkForReversal, self};
            
            showfx  = {@draw, self.helpers.stimulusEnsemble, ...
                {self.fpIndex, ...
                [self.targetIndex self.dotsIndex self.cpScreenIndex]}, ...
                self, 'fixationOn'};
            
            showt   = {@draw, self.helpers.stimulusEnsemble, ...
                {self.targetIndex, []}, self, 'targetOn'};
            
            showfb  = {@showFeedback, self};
            
            showd   = {@draw,self.helpers.stimulusEnsemble, ...
                {self.dotsIndex, []}, self, 'dotsOn'};
            
            hided   = {@draw,self.helpers.stimulusEnsemble, {[], ...
                [self.fpIndex self.dotsIndex]}, self, 'dotsOff'};
            
            cpscr   = {@draw,self.helpers.stimulusEnsemble, ...
                {[self.cpScreenIndex], ...
                [self.fpIndex self.dotsIndex self.targetIndex]}, self, ...
                'cpScreenOn'};
            
%             cpopts  = {@draw, self.helpers.stimulusEnsemble, {{'colors', ...
%                 [1 1 1], 1}, {'isVisible', true, [4]}, ...
%                 {'isVisible', false, [1 2 3]}},  self, 'cpScreenOn'};
            
            blank = {@draw,self.helpers.stimulusEnsemble, ...
                {[], [...
                self.fpIndex ...
                self.dotsIndex ...
                self.targetIndex ...
                self.cpScreenIndex]}, self, ...
                'dummyBlank'};
            
            % Drift correction
            hfdc  = {@reset, self.helpers.reader.theObject, true};
            
            % Save values in trialData
            % tdhf = {@setTrialDataValue, self, 'holdFixation', value, trialIndex};
            
            % Activate/deactivate readable events
            % See dotsReadable.setEventsActiveFlag for function signature
            sea   = @setEventsActiveFlag;
            
            % this activates holdFixation and deactivates everything else
            gwfxw = {sea, self.helpers.reader.theObject, ...
                'holdFixation', 'all'};  
            
            % nothing
            gwfxh = {};
            
            % this activates choseLeft and choseRight but deactivates
            % everything else
            gwts  = {sea, self.helpers.reader.theObject, ...
                {'choseLeft', 'choseRight'}, 'all'};
            
            % this activates holdFixation (to report CP) and nocpResponse but deactivates
            % everything else
            gwcp  = {sea, self.helpers.reader.theObject, ...
                {'holdFixation', 'nocpResponse'}, 'all'};
            
            % ---- Timing variables, read directly from the timing property struct
            %
            t = self.timing;
            
            % ---- Make the state machine. These will be added into the
            %        stateMachine (in topsTreeNode)
            %
            states = {...
                'name'              'entry'  'input'  'timeout'          'exit'     'next'            ; ...
                'showFixation'      showfx   {}       0                     {}      'waitForFixation' ; ...
                'waitForFixation'   gwfxw    chkuif   t.fixationTimeout     {}      'blankNoFeedback' ; ...
                'holdFixation'      gwfxh    chkuib   t.holdFixation        hfdc    'showTargets'     ; ...
                'showTargets'       showt    chkuib   t.preDots             {}      'preDots'         ; ...
                'preDots'           {}       {}       0                     {}      'showDots'        ; ...
                'showDots'          showd    chkrev   0                     hided   'waitForChoice'   ; ...
                'waitForChoice'     gwts     chkuic   t.choiceTimeout       cpscr   'blank'           ; ...
                'waitForCPchoice'   gwcp     chkuicp  t.choiceTimeout       blank   'blank'           ; ...       
                'blank'             {}       {}       0.2                   blanks  'showFeedback'    ; ...
                'showFeedback'      showfb   {}       t.showFeedback        blanks  'done'            ; ...
                'blankNoFeedback'   {}       {}       0                     blanks  'done'            ; ...
                'done'              {}       {}       0                     {}      ''                ; ...
                };
            
            % Set up the state list with automatic drawing/fipping of the
            %  objects in stimulusEnsemble in the given list of states
            self.addStateMachineWithDrawing(states, ...
                'stimulusEnsemble', {'preDots' 'showDots'});
            
        end
    end
    
    methods (Static)
        
        %% ---- Utility for defining standard configurations
        %
        % name is string
        function task = getStandardConfiguration(name, varargin)
            
            % ---- Get the task object, with optional property/value pairs
            %
            task = topsTreeNodeTaskReversingDots4AFC(name, varargin{:});
        end
        
        %% ---- Utility for getting test configuration
        %
        function task = getTestConfiguration()
            
            task = topsTreeNodeTaskReversingDots4AFC();
            task.timing.minimumRT = 0.3;
            task.message.message.Instructions.text = {'Testing', 'topsTreeNodeTaskRTDots'};
        end
    end
end
