classdef PredInfAVTitanAttacks < PredInfAV
    % Predictive inference task with "Titan Attacks" audiovisual style
    
    properties
        % instructional slide show file names
        instructionFileNames = { ...
            'Titan_Attacks1.tiff', ...
            'Titan_Attacks2.tiff', ...
            'Titan_Attacks3.tiff', ...
            'Titan_Attacks4.tiff', ...
            'Titan_Attacks5.tiff'};
        
        % a color that might be described as "hot"
        hotColor = [0.9 0.6 0.3];
        
        % a color that might be described as "cool"
        coolColor = [0.1 0.2 0.8];
        
        % a color that might be described as "light"
        lightColor = [0.9 0.8 0.8];
        
        % a color that might be described as "dark"
        darkColor = [0.1 0.1 0.2];
        
        % a color that might be described as "gold"
        goldColor = [1.0 0.84 0];
        
        % a color that might be described as "silver"
        silverColor = [0.7 0.7 0.8];
        
        % a color that might be described as "bronze"
        bronzeColor = [0.8 0.5 0.2];
    end
    
    properties (SetAccess = protected)
        % whether doing graphics remotely (true) or locally (false)
        isClient = false;
        
        % ensemble object for drawable objects
        drawables;
        
        % slide show for instructional images (drawables index)
        slideShow;
        
        % lines for defining the task area (drawables index)
        border;
        
        % line for showing subject's prediction (drawables index)
        prediction;
        
        % line for showing the trial random outcome (drawables index)
        outcome;
        
        % line for showing the trial "delta" error (drawables index)
        delta;
        
        % text for subject info (drawables index)
        subjectError;
        
        % text for gold tier (drawables index)
        goldError;
        
        % text for silver tier (drawables index)
        silverError;
        
        % text for bronze tier (drawables index)
        bronzeError;
    end
    
    methods
        % Make a new AV object.
        % @param isClient whether to do graphics remotely (true)
        function self = PredInfAVTitanAttacks(isClient)
            if nargin < 1 || isempty(isClient)
                isClient = false;
            end
            self.isClient = isClient;
            
            % ensemble for grouping drawables
            self.drawables = dotsEnsembleUtilities.makeEnsemble( ...
                'drawables', self.isClient);
            
            % automate the task of drawing all the objects
            %   the static drawFrame() takes a cell array of objects
            isCell = true;
            isActive = false;
            self.drawables.automateObjectMethod( ...
                'drawFrame', @dotsDrawable.drawFrame, {}, [], ...
                isCell, isActive);
            
            % tell the ensemble how to open and close a window
            self.drawables.addCall({@dotsTheScreen.openWindow}, 'open');
            self.drawables.addCall({@dotsTheScreen.closeWindow}, 'close');
            self.drawables.setActiveByName(false, 'open');
            self.drawables.setActiveByName(false, 'close');
        end
        
        % Set up audio-visual resources as needed.
        function initialize(self)
            slides = dotsDrawableImages();
            slides.fileNames = self.instructionFileNames;
            self.slideShow = self.drawables.addObject(slides);
            
            bord = dotsDrawableLines();
            bord.xFrom = [-0.5 -0.5]*self.width;
            bord.xTo = [0.5 0.5]*self.width;
            bord.yFrom = [-0.125 0.125]*self.height;
            bord.yTo = [-0.125 0.125]*self.height;
            bord.pixelSize = 5;
            self.border = self.drawables.addObject(bord);
            
            pred = dotsDrawableLines();
            pred.yFrom = -0.15*self.height;
            pred.yTo = -0.2*self.height;
            pred.pixelSize = 5;
            self.prediction = self.drawables.addObject(pred);
            
            out = dotsDrawableLines();
            out.yFrom = 0.15*self.height;
            out.yTo = 0.2*self.height;
            out.pixelSize = 5;
            self.outcome = self.drawables.addObject(out);
            
            delt = dotsDrawableLines();
            delt.yFrom = 0;
            delt.yTo = 0;
            delt.pixelSize = 10;
            self.delta = self.drawables.addObject(delt);
            
            sErr = dotsDrawableText();
            sErr.color = 255*self.coolColor;
            sErr.fontSize = self.fontSize;
            self.subjectError = self.drawables.addObject(sErr);
            
            gErr = dotsDrawableText();
            gErr.color = self.goldColor;
            gErr.fontSize = self.fontSize;
            self.goldError = self.drawables.addObject(gErr);
            
            sErr = dotsDrawableText();
            sErr.color = self.silverColor;
            sErr.fontSize = self.fontSize;
            self.silverError = self.drawables.addObject(sErr);
            
            bErr = dotsDrawableText();
            bErr.color = self.bronzeColor;
            bErr.fontSize = self.fontSize;
            self.bronzeError = self.drawables.addObject(bErr);
            
            % automate the task of drawing instructions
            inds = [self.slideShow];
            isCell = true;
            isActive = false;
            self.drawables.automateObjectMethod( ...
                'drawInstructions', @dotsDrawable.drawFrame, {}, inds, ...
                isCell, isActive);
            
            % automate the task of drawing task graphics
            inds = [self.border, self.prediction, ...
                self.outcome, self.delta];
            self.drawables.automateObjectMethod( ...
                'drawTask', @dotsDrawable.drawFrame, {}, inds, ...
                isCell, isActive);
            
            % automate the task of drawing feedback graphics
            inds = [self.subjectError, self.goldError, ...
                self.silverError, self.bronzeError];
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
            % show the first or previous slide
            self.drawables.callObjectMethod(@previous, {}, self.slideShow);
            isCell = true;
            self.drawables.callObjectMethod( ...
                @dotsDrawable.drawFrame, {}, self.slideShow, isCell);
        end
        
        % Give the next or last task instruction.
        function doNextInstruction(self)
            % show the next or last slide
            self.drawables.callObjectMethod(@next, {}, self.slideShow);
            isCell = true;
            self.drawables.callByName('drawInstructions');
        end
        
        % Indicate that its time to predict.
        function doPredict(self)
            % any results to show from last trial?
            inds = [self.outcome, self.delta];
            if self.logic.blockTotalTrials > 0
                self.drawables.setObjectProperty( ...
                    'colors', self.darkColor, inds);
            else
                self.drawables.setObjectProperty( ...
                    'isVisible', false, inds);
            end
            
            % make the game look "active"
            inds = [self.border, self.prediction];
            self.drawables.setObjectProperty( ...
                'colors', self.lightColor, inds);
            
            % move to the most recent subject prediction
            self.updatePredict();
        end
        
        % Let the prediction reflect new subject input.
        function updatePredict(self)
            % show the subject's latest prediction
            p = self.logic.getPrediction() / self.logic.maxOutcome;
            x = p*self.width - (self.width/2);
            self.drawables.setObjectProperty('xFrom', x, self.prediction);
            self.drawables.setObjectProperty('xTo', x, self.prediction);
            
            self.drawables.callByName('drawTask');
        end
        
        % Indicate that the prediction is not commited.
        function doCommit(self)
            % make the game look "inactive"
            inds = [self.border, self.prediction];
            self.drawables.setObjectProperty( ...
                'colors', self.darkColor, inds);
            
            self.drawables.callByName('drawTask');
        end
        
        % Indicate the new trial outcome.
        function doOutcome(self)
            % show the outcome from this trial
            p = self.logic.currentOutcome / self.logic.maxOutcome;
            x = p*self.width - (self.width/2);
            self.drawables.setObjectProperty('xFrom', x, self.outcome);
            self.drawables.setObjectProperty('xTo', x, self.outcome);
            
            % make the outcome look "active"
            self.drawables.setObjectProperty( ...
                'colors', self.hotColor, self.outcome);
            self.drawables.setObjectProperty( ...
                'isVisible', true, self.outcome);
            
            self.drawables.callByName('drawTask');
        end
        
        % Indicate the prediction delta.
        function doDelta(self)
            % show the subject's "delta" prediction error as a bar
            p = self.logic.getPrediction() / self.logic.maxOutcome;
            xFrom = p*self.width - (self.width/2);
            self.drawables.setObjectProperty('xFrom', xFrom, self.delta);
            
            p = self.logic.currentOutcome / self.logic.maxOutcome;
            xTo = p*self.width - (self.width/2);
            self.drawables.setObjectProperty('xTo', xTo, self.delta);
            
            % make the error bar look "active"
            self.drawables.setObjectProperty( ...
                'colors', self.hotColor, self.delta);
            self.drawables.setObjectProperty( ...
                'isVisible', true, self.delta);
            
            % make the outcome look "inactive"
            self.drawables.setObjectProperty( ...
                'colors', self.darkColor, self.outcome);
            
            self.drawables.callByName('drawTask');
        end
        
        % Indicate success of the trial.
        function doSuccess(self)
            
        end
        
        % Indicate failure of the trial.
        function doFailure(self)
            
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
        
        % Display a message.
        function doMessage(self, message)
            
        end
    end
end