classdef DotrisAVPueblo < DotrisAV
    % @class DotrisAVPueblo
    % Make handsome "pueblo" graphics for the "Dotris" game.
    % @details
    % DotrisAVPueblo makes handsome graphics for Dotris, using the
    % puebloColors() color scheme.
    %
    % @ingroup dotsDemos
    
    properties
        % whether to send graphics to a remote server
        isClient = false;
        
        % side length of grid squares in degrees visual angle
        squareSize = 0.75;
        
        % gap left between squares in degrees visual angle
        squareBorder = 0.01;
        
        % background color for the task
        backgroundColor = [0 0 0];
        
        % color for the game board
        boardColor;
        
        % color for the current game piece
        currentPieceColor;
        
        % color for the next game piece
        nextPieceColor;
        
        % color for pile of pieces at the bottom
        pileColor;
        
        % color for the score text
        scoreColor;
    end
    
    properties(SetAccess = protected)
        % ensemble wrapper for local or remote screen
        screenEnsemble;
        
        % ensemble wrapper for local or remote drawing
        drawableEnsemble;
        
        % index of drawable object that represents the game board
        board;
        
        % index of drawable object that represents the current game piece
        currentPiece;
        
        % index of drawable object that represents the next game piece
        nextPiece;
        
        % index of drawable object that represents the pile of pieces
        pile;
        
        % index of drawable object that represents the score with text
        score;
    end
    
    methods
        % Make a new DotrisAV object.
        % @param logic DotrisLogic object to work with
        % @param isClient whether to show graphics remotely
        % @details
        % If @a isClient is true, creates ensemble objects that communicate
        % with a remote ensemble server, using default newtowrk addresses,
        % and delegates graphics remotely.  Otherwise creates local
        % ensembles for local graphics.
        function self = DotrisAVPueblo(logic, isClient)
            if nargin >= 1
                self.logic = logic;
            end
            
            if nargin >= 2
                self.isClient = isClient;
            end
            
            % choose some handsome default colors
            nColors = 9;
            colors = puebloColors(nColors);
            shuffle = randperm(nColors);
            self.boardColor = colors(shuffle(1),:);
            self.currentPieceColor = colors(shuffle(2),:);
            self.nextPieceColor = colors(shuffle(3),:);
            self.pileColor = colors(shuffle(4),:);
            self.scoreColor = colors(shuffle(5),:);
        end
        
        % Set up audio-visual resources as needed.
        function initialize(self)
            % wrap various drawables in a local or remote ensemble
            self.drawableEnsemble = dotsEnsembleUtilities.makeEnsemble( ...
                'Dotris Drawables', self.isClient);
            
            % represent the game board with square targets
            sideLength = self.squareSize - self.squareBorder;
            b = dotsDrawableTargets();
            b.width = sideLength;
            b.height = sideLength;
            b.xCenter = [];
            b.yCenter = [];
            b.colors = self.boardColor;
            b.nSides = 4;
            b.isVisible = true;
            self.board = self.drawableEnsemble.addObject(b);
            
            % represent the current piece with square targets
            cp = dotsDrawableTargets();
            cp.width = sideLength;
            cp.height = sideLength;
            cp.xCenter = [];
            cp.yCenter = [];
            cp.colors = self.currentPieceColor;
            cp.nSides = 4;
            cp.isVisible = true;
            self.currentPiece = self.drawableEnsemble.addObject(cp);
            
            % represent the next piece with square targets
            %   offset the next piece to the right
            np = dotsDrawableTargets();
            np.width = sideLength;
            np.height = sideLength;
            np.xCenter = [];
            np.yCenter = [];
            np.colors = self.nextPieceColor;
            np.nSides = 4;
            np.isVisible = true;
            offset = 2 + (0.5 * self.squareSize * self.logic.boardWidth);
            np.translation = [offset 0 0];
            self.nextPiece = self.drawableEnsemble.addObject(np);
            
            % represent the pile of pieces with square targets
            p = dotsDrawableTargets();
            p.width = sideLength;
            p.height = sideLength;
            p.xCenter = [];
            p.yCenter = [];
            p.colors = self.pileColor;
            p.nSides = 4;
            p.isVisible = true;
            self.pile = self.drawableEnsemble.addObject(p);
            
            % represent the current score with text
            s = dotsDrawableText();
            s.fontSize = 24;
            s.color = self.scoreColor;
            s.x = offset;
            self.score = self.drawableEnsemble.addObject(s);
            
            % wrap dotsTheScreen in a local or remote ensemble
            self.screenEnsemble = dotsEnsembleUtilities.makeEnsemble( ...
                'Dotris Screen', self.isClient);
            self.screenEnsemble.addObject(dotsTheScreen.theObject());
            
            % open up the drawing window
            self.screenEnsemble.setObjectProperty( ...
                'backgroundColor', self.backgroundColor);
            self.screenEnsemble.callObjectMethod(@open);
            
            % let all the drawable objects react to the new window
            self.drawableEnsemble.callObjectMethod(@prepareToDrawInWindow);
            
            % draw the initial state of the game
            self.updateEverything();
        end
        
        % Clean up audio-visual resources from initialize().
        function terminate(self)
            % finish with the drawing window
            self.screenEnsemble.callObjectMethod(@close);
        end
        
        % Update the game board.
        function doBoard(self)
            [x, y] = self.getXYFromGrid(self.logic.boardGrid);
            self.setTargetsXYCenters(self.board, x, y);
        end
        
        % Update the current game piece.
        function doCurrentPiece(self)
            [x, y] = self.getXYFromGrid(self.logic.currentPieceGrid);
            self.setTargetsXYCenters(self.currentPiece, x, y);
        end
        
        % Update the next game piece.
        function doNextPiece(self)
            [x, y] = self.getXYFromGrid(self.logic.nextPieceGrid);
            self.setTargetsXYCenters(self.nextPiece, x, y);
        end
        
        % Update the pile of pieces at the bottom.
        function doPile(self)
            [x, y] = self.getXYFromGrid(self.logic.pileGrid);
            self.setTargetsXYCenters(self.pile, x, y);
        end
        
        % Update the score text.
        function doScore(self)
            scoreString = sprintf('%d', self.logic.score);
            self.drawableEnsemble.setObjectProperty( ...
                'string', scoreString, self.score);
            self.drawableEnsemble.callObjectMethod( ...
                @prepareToDrawInWindow, [], self.score);
        end
        
        % Hide the game board while paused.
        function doPause(self)
            self.doBoard();
            self.drawableEnsemble.callObjectMethod( ...
                @mayDrawNow, [], self.board);
            self.screenEnsemble.callObjectMethod(@nextFrame);
        end
        
        % Show the game board after pausing.
        function doUnpause(self)
            self.updateEverything();
        end
        
        % Draw all objects and flip screen buffers.
        function updateEverything(self)
            % update graphics parameters
            self.doBoard();
            self.doCurrentPiece();
            self.doNextPiece();
            self.doPile();
            self.doScore();
            
            % let all drawables draw
            self.drawableEnsemble.callObjectMethod(@mayDrawNow);
            
            % flip screen buffers
            self.screenEnsemble.callObjectMethod(@nextFrame);
        end
        
        % Get x and y points from a logical grid.
        function [x, y] = getXYFromGrid(self, grid)
            [row, col, sz] = DotrisLogic.gridSubscripts(grid);
            x = (col-(sz(2)/2))*self.squareSize;
            y = (row-(sz(1)/2))*self.squareSize;
        end
        
        % Set x- and yCenter points for indexed targets objects.
        function setTargetsXYCenters(self, index, x, y)
            if isempty(x) || isempty(y)
                self.drawableEnsemble.setObjectProperty( ...
                    'isVisible', false, index);
            else
                self.drawableEnsemble.setObjectProperty( ...
                    'xCenter', x, index);
                self.drawableEnsemble.setObjectProperty( ...
                    'yCenter', y, index);
                self.drawableEnsemble.setObjectProperty( ...
                    'isVisible', true, index);
            end
        end
    end
end
