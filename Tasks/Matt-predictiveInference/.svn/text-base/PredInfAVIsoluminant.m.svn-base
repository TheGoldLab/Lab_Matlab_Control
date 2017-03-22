classdef PredInfAVIsoluminant < PredInfAV
    % Predictive inference task with "Isoluminant" audiovisual style
    
    properties
        % a sound file for commitment
        commitSoundFile = 'Super_Mario_2-Door.wav';
        
        % a sound file for outcome
        outcomeSoundFile = 'Pause.wav';;
        
        % a sound file for success
        successSoundFile = 'Coin.wav';
        
        % a sound file for success
        perfectSoundFile = '1_up.wav';
        
        % a sound file for failure
        failureSoundFile = 'Pipe_Warp.wav';
        
        % a gray color that might be described as "light"
        lightGray = [1 1 1]*40;
        
        % a gray color that might be described as "medium"
        mediumGray = [1 1 1]*255;
        
        % a gray color that might be described as "dark"
        darkGray = [1 1 1]*0;
        
        % grid size in pixels of the checkered background
        checkerSize = 2;
        
        % "texture maker" function to produce a checkered background
        textureMaker = @textureMakerCheckers;
        
        % degrees visual angle width of fixation point
        fixationSize = 1;
    end
    
    properties (SetAccess = protected)
        % whether doing graphics remotely (true) or locally (false)
        isClient = false;
        
        % ensemble object for drawable objects
        drawables;
        
        % texture with a checkered background (drawables index)
        background;
        
        % fixation point (drawables index)
        fixation;
        
        % cursor indicating what the subject should do (drawables index)
        cursor;
        
        % text for showing subject's prediction (drawables index)
        prediction;
        
        % text for showing the trial random outcome (drawables index)
        outcome;
        
        % text for showing the trial "delta" error (drawables index)
        delta;
        
        % text for subject info (drawables index)
        subjectError;
        
        % text for gold tier (drawables index)
        goldError;
        
        % text for silver tier (drawables index)
        silverError;
        
        % text for bronze tier (drawables index)
        bronzeError;
        
        % ensemble object for playable objects
        playables;
        
        % sound to play when the subject commits (playables index)
        commitSound;
        
        % sound to play with the trial outcome (playables index)
        outcomeSound;
        
        % sound to play for trial success (playables index)
        successSound;
        
        % sound to play for a perfect prediction (playables index)
        perfectSound;
        
        % sound to play for trial failure (playables index)
        failureSound;
    end
    
    methods
        % Make a new AV object.
        % @param isClient whether to do graphics remotely (true)
        function self = PredInfAVIsoluminant(isClient)
            if nargin < 1 || isempty(isClient)
                isClient = false;
            end
            self.isClient = isClient;
            
            % choose a large default font size
            self.fontSize = 64;
            
            % ensemble for grouping drawables
            self.drawables = dotsEnsembleUtilities.makeEnsemble( ...
                'drawables', self.isClient);
            
            % ensemble for grouping playables
            self.playables = dotsEnsembleUtilities.makeEnsemble( ...
                'playables', self.isClient);
            
            % tell the ensemble how to open and close a window
            self.drawables.addCall({@dotsTheScreen.openWindow}, 'open');
            self.drawables.addCall({@dotsTheScreen.closeWindow}, 'close');
            self.drawables.setActiveByName(false, 'open');
            self.drawables.setActiveByName(false, 'close');
        end
        
        % Set up audio-visual resources as needed.
        function initialize(self)
            % create several playable objects
            cs = dotsPlayableFile();
            cs.fileName = self.commitSoundFile;
            self.commitSound = self.playables.addObject(cs);
            
            os = dotsPlayableFile();
            os.fileName = self.outcomeSoundFile;
            self.outcomeSound = self.playables.addObject(os);
            
            ss = dotsPlayableFile();
            ss.fileName = self.successSoundFile;
            self.successSound = self.playables.addObject(ss);
            
            ps = dotsPlayableFile();
            ps.fileName = self.perfectSoundFile;
            self.perfectSound = self.playables.addObject(ps);
            
            fs = dotsPlayableFile();
            fs.fileName = self.failureSoundFile;
            self.failureSound = self.playables.addObject(fs);
            
            % let each sound prepare itself
            self.playables.callObjectMethod(@prepareToPlay);
            
            % create several drawable objects
            bg = dotsDrawableTextures();
            bg.textureMakerFevalable = { ...
                self.textureMaker, ...
                self.checkerSize, ...
                self.checkerSize, ...
                [], ...
                [], ...
                self.darkGray, ...
                self.lightGray};
            self.background = self.drawables.addObject(bg);
            
            fix = dotsDrawableTargets();
            fix.colors = self.mediumGray;
            fix.width = self.fixationSize;
            fix.height = self.fixationSize;
            self.fixation = self.drawables.addObject(fix);
            
            pred = dotsDrawableText();
            pred.y = 0.1*self.height;
            pred.color = self.mediumGray;
            pred.fontSize = self.fontSize;
            self.prediction = self.drawables.addObject(pred);
            
            out = dotsDrawableText();
            out.y = 0.1*self.height;
            out.color = self.mediumGray;
            out.fontSize = self.fontSize;
            self.outcome = self.drawables.addObject(out);
            
            %del = dotsDrawableText();
            %del.y = -0.2*self.height;
            %del.color = self.mediumGray;
            %del.fontSize = self.fontSize;
            %self.delta = self.drawables.addObject(del);
            
            curs = dotsDrawableTargets();
            curs.yCenter = 0.1*self.height;
            curs.colors = self.mediumGray;
            curs.width = self.fixationSize/2;
            curs.height = self.fixationSize/2;
            self.cursor = self.drawables.addObject(curs);
            
            sErr = dotsDrawableText();
            sErr.color = self.mediumGray;
            sErr.fontSize = self.fontSize;
            self.subjectError = self.drawables.addObject(sErr);
            
            gErr = dotsDrawableText();
            gErr.color = self.mediumGray;
            gErr.fontSize = self.fontSize;
            self.goldError = self.drawables.addObject(gErr);
            
            sErr = dotsDrawableText();
            sErr.color = self.mediumGray;
            sErr.fontSize = self.fontSize;
            self.silverError = self.drawables.addObject(sErr);
            
            bErr = dotsDrawableText();
            bErr.color = self.mediumGray;
            bErr.fontSize = self.fontSize;
            self.bronzeError = self.drawables.addObject(bErr);
            
            % automate the task of drawing instructions
            inds = [self.background, self.fixation];
            isCell = true;
            isActive = false;
            self.drawables.automateObjectMethod( ...
                'drawInstructions', @dotsDrawable.drawFrame, {}, inds, ...
                isCell, isActive);
            
            % automate the task of drawing task graphics
            inds = [self.background, self.fixation, self.cursor, ...
                self.prediction, self.outcome];
            self.drawables.automateObjectMethod( ...
                'drawTask', @dotsDrawable.drawFrame, {}, inds, ...
                isCell, isActive);
            
            % automate the task of drawing feedback graphics
            inds = [self.background, self.subjectError, ...
                self.goldError, self.silverError, self.bronzeError];
            self.drawables.automateObjectMethod( ...
                'drawFeedback', @dotsDrawable.drawFrame, {}, inds, ...
                isCell, isActive);
            
            % open a drawing window and let objects react to it
            self.drawables.callByName('open');
            self.drawables.callObjectMethod(@prepareToDrawInWindow);
        end
        
        % Clean up audio-visual resources as needed.
        function terminate(self)
            self.drawables.callByName('close');
        end
        
        % Return concurrent objects, like ensembles, if any.
        function concurrents = getConcurrents(self)
            concurrents = {};
        end
        
        % Give the previous or first task instruction.
        function doPreviousInstruction(self)
            % trivial "instructions"
            self.drawables.callByName('drawInstructions');
        end
        
        % Give the next or last task instruction.
        function doNextInstruction(self)
            % trivial "instructions"
            self.drawables.callByName('drawInstructions');
        end
        
        % Indicate that its time to predict.
        function doPredict(self)
            % hide the result from the last trial
            self.drawables.setObjectProperty( ...
                'isVisible', false, self.outcome);
            
            % move the cursor to indicate subject's prediction
            self.drawables.setObjectProperty( ...
                'xCenter', -0.1*self.width, self.cursor);
            
            % background, fixation, prediction and cursor for this trial
            inds = [self.background, self.fixation, ...
                self.cursor, self.prediction];
            self.drawables.setObjectProperty( ...
                'isVisible', true, inds);
            
            % display the subject's most recent prediction
            self.updatePredict();
        end
        
        % Let the prediction reflect new subject input.
        function updatePredict(self)
            % new text string for the new prediction
            p = self.logic.getPrediction();
            self.drawables.setObjectProperty( ...
                'string', sprintf('%d', p), self.prediction);
            
            self.drawables.callByName('drawTask');
        end
        
        % Indicate that the prediction is not commited.
        function doCommit(self)
            % commitment plays a sound
            self.playables.callObjectMethod( ...
                @mayPlayNow, {}, self.commitSound);
            
            % and hides the cursor
            self.drawables.setObjectProperty( ...
                'isVisible', false, self.cursor);
            
            self.drawables.callByName('drawTask');
        end
        
        % Indicate the new trial outcome.
        function doOutcome(self)
            % outcome plays a sound
            self.playables.callObjectMethod( ...
                @mayPlayNow, {}, self.outcomeSound);
            
            % new text string for the new outcome
            o = self.logic.currentOutcome;
            self.drawables.setObjectProperty( ...
                'string', sprintf('%d', o), self.outcome);
            
            % show and call attention to the outcome
            self.drawables.setObjectProperty( ...
                'xCenter', 0.1*self.width, self.cursor);
            self.drawables.setObjectProperty( ...
                'isVisible', true, [self.outcome, self.cursor]);
            
            % done with predictions for this trial
            self.drawables.setObjectProperty( ...
                'isVisible', false, self.prediction);
            
            self.drawables.callByName('drawTask');
        end
        
        % Indicate the prediction delta.
        function doDelta(self)
            
        end
        
        % Indicate success of the trial.
        function doSuccess(self)
            % play a "good job" or "great job" sound
            if self.logic.currentOutcome == self.logic.getPrediction()
                self.playables.callObjectMethod( ...
                    @mayPlayNow, {}, self.perfectSound);
            else
                self.playables.callObjectMethod( ...
                    @mayPlayNow, {}, self.successSound);
            end
            
            % end of trial, hide the cursor
            self.drawables.setObjectProperty( ...
                'isVisible', false, self.cursor);
            
            self.drawables.callByName('drawTask');
        end
        
        % Indicate failure of the trial.
        function doFailure(self)
            % play a "not very good job" sound
            self.playables.callObjectMethod( ...
                @mayPlayNow, {}, self.failureSound);
            
            % end of trial, hide the cursor
            self.drawables.setObjectProperty( ...
                'isVisible', false, self.cursor);
            
            self.drawables.callByName('drawTask');
        end
        
        % Describe feedback about the subject input.
        function doFeedback(self)
            % fill in feedback strings with error values
            feedbackData = self.logic.getPayout();
            self.drawables.setObjectProperty( ...
                'string', feedbackData.errorString, self.subjectError);
            self.drawables.setObjectProperty( ...
                'string', feedbackData.goldString, self.goldError);
            self.drawables.setObjectProperty( ...
                'string', feedbackData.silverString, self.silverError);
            self.drawables.setObjectProperty( ...
                'string', feedbackData.bronzeString, self.bronzeError);
            
            % arrange feedback strings sorted by error value
            yPositions = [0.3 0.1 -0.1 -0.3]*self.height;
            levels = [ ...
                feedbackData.subjectMeanError, ...
                feedbackData.goldLevel, ...
                feedbackData.silverLevel, ...
                feedbackData.bronzeLevel];
            [sorted, order] = sort(levels);
            texts = [...
                self.subjectError, ...
                self.goldError, ...
                self.silverError ...
                self.bronzeError];
            texts = texts(order);
            for ii = 1:numel(texts)
                % put each text at its sorted-out height
                self.drawables.setObjectProperty( ...
                    'y', yPositions(ii), texts(ii));
            end
            
            self.drawables.callByName('drawFeedback');
        end
        
        % Give a message to the subject.
        function doMessage(self, message)
            
        end
    end
end