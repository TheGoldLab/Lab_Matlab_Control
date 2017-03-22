classdef PredInfAVHelicopter < PredInfAV
    % Predictive inference task with "Helicopter" audiovisual style
    
    properties
        % an image file to show in the bg
        backgroundImageFile = 'bison.jpg';
        
        % how wide to stretch the bg image
        backgroundWidth = 30;
        
        % how tall to stretch the bg image
        backgroundHeight = 20;
        
        % whether or not to show clouds in place of the helicopter
        isCloudy = false;
        
        % an image file which contains clouds
        cloudsImageFile = 'clouds.tiff';
        
        % how wide to stretch the clouds image
        cloudsWidth = 30;
        
        % how tall to stretch the clouds image
        cloudsHeight = 4;
        
        % height of the helicopter image
        yHelicopter = 8;
        
        % height of the clouds image
        yClouds = 8;
        
        % height of the "delta" error line and tick marks
        yDelta = -7.5;
        
        % height of the ground where coins fall
        yGround = -8;
        
        % width of the hole in the ground
        holeWidth = 3;
        
        % height of the hole in the ground
        holeHeight = 2;
        
        % an image file with a helicopter
        heliImageFile = 'helicopter.tiff';
        
        % width of the helicopter image
        heliWidth = 3;
        
        % height of the helicopter image
        heliHeight = 3;
        
        % an image file with a bag
        bagImageFile = 'bag-of-coins.tiff';
        
        % width of the bag image
        bagWidth = 2;
        
        % height of the bag image
        bagHeight = 2;
        
        % how many coins to explode from the bag
        nExplCoins = 200;
        
        % pixel size of each explosion coin
        explCoinSize = 4;
        
        % standard deviation of coins explosion
        explStd = 1;
        
        % a color that might be described as "hot"
        hotColor = [0.9 0.6 0.3];
        
        % a color that might be described as "cool"
        coolColor = [0.1 0.1 0.6];
        
        % a color that might be described as "dull"
        dullColor = [0.4 0.4 0.6];
        
        % a color that might be described as "red"
        redColor = [0.8 0.1 0.1];
        
        % struct array of data for different coin types
        coins = struct( ...
            'name', 'gold', ...
            'color', [1.0 0.84 0], ...
            'value', 1, ...
            'frequency', 1);
        
        % where to start the ground, pile, and cursor each trial
        inactivePrediction;
    end
    
    properties (SetAccess = protected)
        % whether doing graphics remotely (true) or locally (false)
        isClient = false;
        
        % ensemble object for drawable objects
        drawables;
        
        % bg image (drawables index)
        background;
        
        % cloudy image (drawables index)
        clouds;
        
        % line for the ground (drawables index)
        ground;
        
        % line showing the trial "delta" error (drawables index)
        delta;
        
        % line tracing falling bags paths (drawables index)
        tracer;
        
        % animator extending tracer along the bag path (drawables index)
        tracerAnimator;
        
        % tick mark showing subject current prediction (drawables index)
        prediction;
        
        % tick mark showing subject previous prediction (drawables index)
        lastPrediction;
        
        % tick mark showing previous trial outcome (drawables index)
        lastOutcome;
        
        % helicopter image (drawables index)
        helicopter;
        
        % animator moving the helicopter vertically (drawables index)
        hoverAnimator;
        
        % animator moving the helicopter horizontally (drawables index)
        flyAnimator;
        
        % bag image (drawables index)
        bag;
        
        % animator for the bag (drawables index)
        bagAnimator;
        
        % explosion for lots of coins (drawables index)
        explosion;
        
        % animator for the explosion (drawables index)
        explAnimator;
        
        % pile of coins accumulated during a block (drawables index)
        pile;
        
        % text showing message to the subject (drawables index)
        message;
    end
    
    methods
        % Make a new AV object.
        % @param isClient whether to do graphics remotely (true)
        function self = PredInfAVHelicopter(isClient)
            if nargin < 1 || isempty(isClient)
                isClient = false;
            end
            self.isClient = isClient;
            
            % ensemble for grouping drawables
            self.drawables = dotsEnsembleUtilities.makeEnsemble( ...
                'drawables', self.isClient);
            
            % tell the ensemble how to open and close a window
            self.drawables.addCall({@dotsTheScreen.openWindow}, 'open');
            self.drawables.addCall({@dotsTheScreen.closeWindow}, 'close');
            self.drawables.setActiveByName(false, 'open');
            self.drawables.setActiveByName(false, 'close');
        end
        
        % Set up audio-visual resources as needed.
        function initialize(self)
            % make many drawables
            
            % instructions and task share a background image
            bg = dotsDrawableImages();
            bg.fileNames = {self.backgroundImageFile};
            bg.width = self.backgroundWidth;
            bg.height = self.backgroundHeight;
            self.background = self.drawables.addObject(bg);
            
            % instructions uses a text object
            m = dotsDrawableText();
            m.color = 255*self.hotColor;
            m.fontSize = self.fontSize;
            m.x = 0;
            m.y = 0;
            self.message = self.drawables.addObject(m);
            
            % task has a line at ground level
            g = dotsDrawableVertices();
            g.y = self.yGround + [0 0 -self.holeHeight, ...
                -self.holeHeight 0 0];
            g.pixelSize = 3;
            g.usageHint = 6;
            g.primitive = 1;
            self.ground = self.drawables.addObject(g);
            
            % task has a "delta" error bar
            d = dotsDrawableLines();
            d.yFrom = self.yDelta;
            d.yTo = self.yDelta;
            d.colors = self.redColor;
            d.pixelSize = 10;
            self.delta = self.drawables.addObject(d);
            
            % task animations all need to agree on a timecourse
            tDrop = 0;
            tLand = self.tOutcome/2;
            tExploded = self.tOutcome;
            
            fallPoints = 25;
            fallInterval = tLand - tDrop;
            fallTimes = linspace(0, fallInterval, fallPoints);
            yStart = self.yHelicopter ...
                - self.heliHeight/2 - self.bagHeight/2;
            yFall = yStart + ...
                (self.yDelta-yStart)*(fallTimes.^2)/(fallTimes(end).^2);
            bagFallTimes = tDrop + fallTimes;
            
            % task has animated tracer which follows a falling bag
            traceAnim = dotsDrawableAnimator();
            traceAnim.isAggregateDraw = false;
            traceAnim.addMember('yTo', bagFallTimes, yFall, true);
            
            trace = dotsDrawableLines();
            trace.pixelSize = 1;
            trace.yFrom = self.yHelicopter;
            trace.colors = self.dullColor;
            
            % wire up the tracer and its animator
            %   add animator first, so it can update before tracer draws
            self.tracerAnimator = self.drawables.addObject(traceAnim);
            self.tracer = self.drawables.addObject(trace);
            self.drawables.passObject( ...
                self.tracer, self.tracerAnimator, @addDrawable);
            
            % task has a tick mark showing last trial outcome
            lastOut = dotsDrawableLines();
            lastOut.yFrom = self.yDelta + 0.25;
            lastOut.yTo = self.yDelta - 0.25;
            lastOut.colors = self.dullColor;
            lastOut.pixelSize = 3;
            self.lastOutcome = self.drawables.addObject(lastOut);
            
            % task has a tick mark showing last trial prediction
            lastPredict = dotsDrawableLines();
            lastPredict.yFrom = self.yDelta + 0.25;
            lastPredict.yTo = self.yDelta - 0.25;
            lastPredict.colors = self.coolColor;
            lastPredict.pixelSize = 3;
            self.lastPrediction = self.drawables.addObject(lastPredict);
            
            % task has a tick mark showing current prediction
            predict = dotsDrawableLines();
            predict.yFrom = self.yDelta + 0.25;
            predict.yTo = self.yDelta - 0.25;
            predict.pixelSize = 3;
            self.prediction = self.drawables.addObject(predict);
            
            % task has animated helicopter that hovers and flies
            heli = dotsDrawableImages();
            heli.fileNames = {self.heliImageFile};
            heli.width = self.heliWidth;
            heli.height = self.heliHeight;
            heli.isFlippedHorizontal = true;
            
            flyAnim = dotsDrawableAnimator();
            flyAnim.isAggregateDraw = false;
            
            hoverAnim = dotsDrawableAnimator();
            hoverAnim.isAggregateDraw = false;
            hoverTimes = linspace(0, 2, 25);
            yHover = self.yHelicopter ...
                + 0.5*sin(hoverTimes/max(hoverTimes)*2*pi);
            hoverAnim.addMember('y', hoverTimes, yHover, true);
            hoverAnim.setMemberCompletionStyle( ...
                'y', 'wrap', hoverTimes(end));
            
            % wire up the helicopter and its animators
            %   add animators first, so they can update before heli draws
            self.hoverAnimator = self.drawables.addObject(hoverAnim);
            self.flyAnimator = self.drawables.addObject(flyAnim);
            self.helicopter = self.drawables.addObject(heli);
            self.drawables.passObject( ...
                self.helicopter, self.flyAnimator, @addDrawable);
            self.drawables.passObject( ...
                self.helicopter, self.hoverAnimator, @addDrawable);
            
            % task has a bag that falls from helicopter to ground
            b = dotsDrawableImages();
            b.fileNames = {self.bagImageFile};
            b.width = self.bagWidth;
            b.height = self.bagHeight;
            
            bagAnim = dotsDrawableAnimator();
            bagAnim.isAggregateDraw = false;
            tVis = [tDrop, tLand];
            vis = [1 0];
            bagAnim.addMember('isVisible', tVis, vis, false);
            bagAnim.addMember('y', bagFallTimes, yFall, true);
            
            % wire up the bag and its animator
            %   add animator first, so it can update before bag draws
            self.bagAnimator = self.drawables.addObject(bagAnim);
            self.bag = self.drawables.addObject(b);
            self.drawables.passObject( ...
                self.bag, self.bagAnimator, @addDrawable);
            
            % task has animated explosion of coins out of the bag
            expl = dotsDrawableExplosion();
            expl.y = self.yDelta;
            expl.gravity = -20;
            expl.bounceDamping = [.25 .5];
            expl.pixelSize = self.explCoinSize;
            expl.isInternalTime = false;
            
            explAnim = dotsDrawableAnimator();
            explAnim.isAggregateDraw = false;
            tVisible = [tDrop, tLand];
            visible = [0 1];
            explAnim.addMember('isVisible', tVisible, visible, false);
            
            % rush the explosion at the end to make sure it finishes
            tExpl = tLand + (tExploded-tLand)*[0 .9 1];
            tExplInternal = [0 2 10];
            explAnim.addMember('currentTime', tExpl, tExplInternal, true);
            
            % wire up the explosion and its animator
            %   add animator first, so it can update before explosion draws
            self.explAnimator = self.drawables.addObject(explAnim);
            self.explosion = self.drawables.addObject(expl);
            self.drawables.passObject( ...
                self.explosion, self.explAnimator, @addDrawable);
            
            % task has a pile of coins that grows each trial
            p = dotsDrawableVertices();
            p.pixelSize = self.explCoinSize;
            p.usageHint = 6;
            p.primitive = 0;
            self.pile = self.drawables.addObject(p);
            
            % task has clouds that can cover the sky
            cloud = dotsDrawableImages();
            cloud.fileNames = {self.cloudsImageFile};
            cloud.width = self.cloudsWidth;
            cloud.height = self.cloudsHeight;
            cloud.y = self.yClouds;
            self.clouds = self.drawables.addObject(cloud);
            
            % automate the task of drawing a message
            inds = [self.background, self.message];
            isCell = true;
            isActive = false;
            self.drawables.automateObjectMethod( ...
                'drawMessage', @dotsDrawable.drawFrame, {}, inds, ...
                isCell, isActive);
            
            % automate the task of drawing task graphics
            %   all objects besides message
            nObj = numel(self.drawables.objects);
            inds = setdiff(1:nObj, self.message);
            self.drawables.automateObjectMethod( ...
                'drawTask', @dotsDrawable.drawFrame, {}, inds, ...
                isCell, isActive);
            
            % automate the task of drawing feedback graphics
            inds = [self.background, self.message, self.pile];
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
            concurrents = {self.drawables};
        end
        
        % Give the previous or first task instruction.
        function doPreviousInstruction(self)
            self.doMessage(self.pleasePressString);
        end
        
        % Give the next or last task instruction.
        function doNextInstruction(self)
            self.doMessage(self.pleasePressString);
        end
        
        % Indicate that its time to predict.
        function doPredict(self)
            % stop drawing while performing updates
            self.drawables.setActiveByName(false, 'drawTask');
            
            % Some graphics would be meaningless on the first trial
            if self.logic.blockTotalTrials <= 0
                % center the helicopter
                self.drawables.setObjectProperty('x', 0, self.helicopter);
                
                % hide several objects
                inds = [self.delta, self.lastPrediction, ...
                    self.lastOutcome, self.tracer, self.pile];
                self.drawables.setObjectProperty('isVisible', false, inds);
            end
            
            % Cloudy behavior literally hides the helicopter,
            %   not just masking it
            inds = [self.hoverAnimator, self.helicopter];
            self.drawables.setObjectProperty( ...
                'isVisible', ~self.isCloudy, inds);
            self.drawables.setObjectProperty( ...
                'isVisible', self.isCloudy, self.clouds);
            
            % trials start with no coins in the hole
            self.logic.trialData.coinsInHole = 0;
            
            % for calculations below, what would be a perfect block?
            bestCoin = self.getBestCoin();
            self.logic.trialData.bestScore = self.logic.trialsPerBlock ...
                * self.nExplCoins * bestCoin.value;
            
            % downplay some visual elements
            inds = [self.tracer, self.tracerAnimator, ...
                self.flyAnimator, ...
                self.bag, self.bagAnimator, ...
                self.explosion, self.explAnimator];
            self.drawables.setObjectProperty('isVisible', false, inds);
            
            % move the prediction cursor
            self.updatePredict();
            
            % start drawing now that updates are done
            self.drawables.setActiveByName(true, 'drawTask');
        end
        
        % Let the prediction reflect new subject input.
        function updatePredict(self)
            % pack up some "params" that specify a prediction update
            %   instead of doing calculations here,
            %   pack up a single method call to execute remotely
            %   this reduces network traffic and improves streaming
            %   from subject's local inputs to remote graphics
            %   this helps when isClient = true
            %   it works fine when isClient = false
            
            % params for scaling graphics
            params.yGround = self.yGround;
            params.holeHeight = self.holeHeight;
            params.holeWidth = self.holeWidth;
            params.width = self.width;
            
            % choose a flavor of prediction update
            if self.logic.isPredictionActive
                % move to a prediction chosen by the subject
                p = self.logic.getPrediction() / self.logic.maxOutcome;
                params.xPred = p*self.width - (self.width/2);
                
                % highlight the ground and cursor
                params.predictionColor = self.hotColor;
                params.groundColor = self.hotColor;
                
                % paint the pile in the color of the best coin
                coin = self.getBestCoin();
                params.pileColor = coin.color;
                
                % show the prediction tick mark
                %   don't alter the pile visiblilty
                params.predictionIsVisible = true;
                params.pileIsVisible = [];
                
            else
                % move to a fixed prediction
                if isempty(self.inactivePrediction)
                    params.xPred = 0;
                    
                else
                    p = self.logic.getPrediction() / self.logic.maxOutcome;
                    params.xPred = p*self.width - (self.width/2);
                end
                
                % gray out the ground, cursor, and pile
                params.predictionColor = self.dullColor;
                params.groundColor = self.dullColor;
                params.pileColor = self.dullColor;
                
                % hide the prediction tick mark and the pile
                params.predictionIsVisible = false;
                params.pileIsVisible = false;
            end
            
            % update the prediction with a single method call
            % 	updatePredictFromParams() is a static method, below
            %   it expects a cell array of drawables and a struct of params
            inds = [self.prediction, self.ground, self.pile];
            isCell = true;
            self.drawables.callObjectMethod( ...
                @PredInfAVHelicopter.updatePredictFromParams, ...
                {params}, inds, isCell);
        end
        
        % Indicate that the prediction is now commited.
        function doCommit(self)
            % stop drawing while performing updates
            self.drawables.setActiveByName(false, 'drawTask');
            
            % convert prediciton units to x-location
            p = self.logic.getPrediction() / self.logic.maxOutcome;
            xPred = p*self.width - (self.width/2);
            
            % pass prediction into last prediciton
            self.drawables.setObjectProperty( ...
                'xFrom', xPred, self.lastPrediction);
            self.drawables.setObjectProperty( ...
                'xTo', xPred, self.lastPrediction);
            self.drawables.setObjectProperty( ...
                'isVisible', true, self.lastPrediction);
            self.drawables.setObjectProperty( ...
                'isVisible', false, self.prediction);
            
            % dull out the ground
            self.drawables.setObjectProperty( ...
                'colors', self.coolColor, self.ground);
            
            % helicopter may fly to a new place
            if ~self.isCloudy ...
                    && (self.logic.blockTotalTrials <= 0 ...
                    || self.logic.isChangeTrial)
                
                xFrom = self.drawables.getObjectProperty('x', self.helicopter);
                p = self.logic.currentMean ./ self.logic.maxOutcome;
                xTo = p .* self.width - (self.width/2);
                xFly = [xFrom, xTo];
                tFly = [0 self.tCommit/2];
                self.drawables.callObjectMethod( ...
                    @addMember, {'x', tFly, xFly, true}, self.flyAnimator);
                self.drawables.callObjectMethod( ...
                    @prepareToDrawInWindow, {}, self.flyAnimator);
                self.drawables.setObjectProperty( ...
                    'isVisible', true, self.flyAnimator);
            end
            
            % start drawing now that updates are done
            self.drawables.setActiveByName(true, 'drawTask');
        end
        
        % Indicate the new trial outcome.
        function doOutcome(self)
            % stop drawing while performing updates
            self.drawables.setActiveByName(false, 'drawTask');
            
            % tell the bag and tracer where to drop
            p = self.logic.currentOutcome / self.logic.maxOutcome;
            xOutcome = p*self.width - (self.width/2);
            self.drawables.setObjectProperty('x', xOutcome, self.bag);
            self.drawables.setObjectProperty('xFrom', xOutcome, self.tracer);
            self.drawables.setObjectProperty('xTo', xOutcome, self.tracer);
            self.drawables.setObjectProperty('isVisible', true, self.tracer);
            
            % pick the coin type for this trial
            coin = self.pickCoin();
            self.logic.trialData.coinType = coin;
            
            % tell the coins where to explode and land
            xCoins = normrnd(xOutcome, self.explStd, 1, self.nExplCoins);
            self.drawables.setObjectProperty('x', xOutcome, self.explosion);
            self.drawables.setObjectProperty('xRest', xCoins, self.explosion);
            self.drawables.setObjectProperty( ...
                'colors', coin.color, self.explosion);
            
            % choose how long each coint takes to bounce
            tRest = normrnd(1, 1, 1, self.nExplCoins);
            self.drawables.setObjectProperty('tRest', tRest, self.explosion);
            
            % choose which coins fall in the hole vs on the ground
            yCoins = self.yGround*ones(1, self.nExplCoins);
            if self.logic.isPredictionActive
                p = self.logic.getPrediction() / self.logic.maxOutcome;
                xPred = p*self.width - (self.width/2);
                isInHole = xCoins >= (xPred-self.holeWidth/2) ...
                    & xCoins <= (xPred+self.holeWidth/2);
                yCoins = self.yGround*ones(1, self.nExplCoins);
                yCoins(isInHole) = self.yGround - self.holeHeight;
                self.logic.trialData.coinsInHole = sum(isInHole);
            end
            self.drawables.setObjectProperty('yRest', yCoins, self.explosion);
            
            % show animators for falling and exploding
            inds = [self.tracerAnimator, self.bagAnimator, ...
                self.explAnimator];
            self.drawables.setObjectProperty('isVisible', true, inds);
            self.drawables.callObjectMethod(@prepareToDrawInWindow, {}, inds);
            
            % start drawing now that updates are done
            self.drawables.setActiveByName(true, 'drawTask');
        end
        
        % Get data for the (first) coin of highest value.
        function coin = getBestCoin(self)
            values = [self.coins.value];
            [high, ii] = max(values);
            coin = self.coins(ii);
        end
        
        % Get data for a random coin, chosen by frquency.
        function coin = pickCoin(self)
            frequencies = [self.coins.frequency];
            cdf = cumsum(frequencies) / sum(frequencies);
            pick = rand(1,1);
            ii = find(cdf >= pick, 1, 'first');
            coin = self.coins(ii);
        end
        
        % Indicate the prediction delta.
        function doDelta(self)
            % stop drawing while performing updates
            self.drawables.setActiveByName(false, 'drawTask');
            
            p = self.logic.getPrediction() / self.logic.maxOutcome;
            xPred = p*self.width - (self.width/2);
            
            p = self.logic.currentOutcome / self.logic.maxOutcome;
            xOutcome = p*self.width - (self.width/2);
            
            self.drawables.setObjectProperty('xFrom', xPred, self.delta);
            self.drawables.setObjectProperty('xTo', xOutcome, self.delta);
            self.drawables.setObjectProperty('isVisible', true, self.delta);
            
            self.drawables.setObjectProperty( ...
                'xFrom', xOutcome, self.lastOutcome);
            self.drawables.setObjectProperty( ...
                'xTo', xOutcome, self.lastOutcome);
            self.drawables.setObjectProperty( ...
                'isVisible', true, self.lastOutcome);
            
            % start drawing now that updates are done
            self.drawables.setActiveByName(true, 'drawTask');
        end
        
        % Indicate success of the trial.
        function doSuccess(self)
            coin = self.logic.trialData.coinType;
            trialScore = self.logic.trialData.coinsInHole * coin.value;
            self.logic.blockScore = self.logic.blockScore + trialScore;
            
            % redraw the pile, if any value accumulated this trial
            if trialScore > 0
                % stop drawing while performing updates
                self.drawables.setActiveByName(false, 'drawTask');
                
                score = self.logic.blockScore;
                bestScore = self.logic.trialData.bestScore;
                [pileX, pileY] = PredInfAVHelicopter.pilePosition( ...
                    score, bestScore, self.holeWidth, self.holeHeight);
                
                self.drawables.setObjectProperty('x', pileX, self.pile);
                self.drawables.setObjectProperty('y', pileY, self.pile);
                self.drawables.setObjectProperty('isVisible', true, self.pile);
                
                % start drawing now that updates are done
                self.drawables.setActiveByName(true, 'drawTask');
            end
        end
        
        % Indicate failure of the trial.
        function doFailure(self)
        end
        
        % Describe feedback about the subject performance.
        function doFeedback(self)
            % stop drawing for this trial
            self.drawables.setActiveByName(false, 'drawTask');
            
            score = self.logic.blockScore;
            bestScore = self.logic.trialData.bestScore;
            m = sprintf('You earned %d out of %d points!', ...
                score, bestScore);
            self.drawables.setObjectProperty('string', m, self.message);
            
            if score > 0
                % draw the pile, larger than usual
                coin = self.getBestCoin();
                trans = [0 self.yGround - self.holeHeight 0];
                self.drawables.setObjectProperty( ...
                    'translation', trans, self.pile);
                self.drawables.setObjectProperty( ...
                    'scaling', [3 3 0], self.pile);
                self.drawables.setObjectProperty( ...
                    'pixelSize', self.explCoinSize * 3, self.pile);
                self.drawables.setObjectProperty( ...
                    'colors', coin.color, self.pile);
                self.drawables.setObjectProperty( ...
                    'isVisible', true, self.pile);
                
                % draw just the pile from the task ensemble
                self.drawables.callObjectMethod(@mayDrawNow, {}, self.pile);
                
            else
                self.drawables.setObjectProperty( ...
                    'isVisible', false, self.pile);
            end
            
            self.drawables.callByName('drawFeedback');
            
            if score > 0
                self.drawables.setObjectProperty( ...
                    'scaling', [], self.pile);
                self.drawables.setObjectProperty( ...
                    'pixelSize', self.explCoinSize, self.pile);
            end
        end
        
        % Display a message.
        function doMessage(self, message)
            if nargin > 1
                m = message;
            else
                m = '';
            end
            self.drawables.setObjectProperty('string', m, self.message);
            self.drawables.callByName('drawMessage');
        end
    end
    
    methods (Static)
        % Calculate positions for coins in a pile.
        function [x, y] = pilePosition(n, nMax, w, h)
            if n <= 0
                x = 0;
                y = 0;
                return
            end
            
            % take n picks from the standard Gaussian
            % chop Gaussian into several bins
            % stack up picks for each bin
            nBins = 10;
            wBins = 4;
            picks = normrnd(0, 1, 1, n);
            bins = [-inf linspace(-wBins/2, wBins/2, nBins) inf];
            stacked = zeros(1, n);
            for ii = 2:nBins+2
                isThisBin = (picks > bins(ii-1)) & (picks <= bins(ii));
                binStacked = cumsum(isThisBin);
                stacked(isThisBin) = binStacked(isThisBin);
            end
            
            % stretch the stacks into graphical coordinates
            x = (w/wBins)*picks;
            x = min(max(x, -w/2), w/2);
            y = (h*(n/nMax)/max(stacked))*stacked;
        end
        
        % Encapsulate streaming prediction updates in a single function.
        function updatePredictFromParams(drawables, params)
            % unpack the cell array of drawables
            [prediction, ground, pile] = deal(drawables{:});
            
            % move the prediction tick mark
            prediction.xFrom = params.xPred;
            prediction.xTo = params.xPred;
            
            % redraw the hole in the ground under the tick mark
            leftHole = params.xPred - 0.5*params.holeWidth;
            rightHole = params.xPred + 0.5*params.holeWidth;
            leftSide = min(-0.5*params.width, leftHole);
            rightSide = max(0.5*params.width, rightHole);
            holeX = [leftSide, leftHole, leftHole, ...
                rightHole, rightHole, rightSide];
            ground.x = holeX;
            
            % translate the pile of coins in the hole in the ground
            trans = [params.xPred params.yGround - params.holeHeight 0];
            pile.translation = trans;
            
            % color each object
            prediction.colors = params.predictionColor;
            ground.colors = params.groundColor;
            pile.colors = params.pileColor;
            
            % show the prediction cursor?
            if ~isempty(params.predictionIsVisible)
                prediction.isVisible = params.predictionIsVisible;
            end
            
            % show the pile?
            if ~isempty(params.pileIsVisible)
                pile.isVisible = params.pileIsVisible;
            end
        end
    end
end