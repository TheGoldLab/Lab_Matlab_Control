classdef DotrisLogic < handle
    % @class DotrisLogic
    % Organize logical "back end" behavior for the Dotris game.
    % @details
    % Manages things like the game board, pieces, movement of pieces, etc.
    % Does not "know about" things like timing, graphics or player input.
    %
    % @ingroup dotsDemos
    
    properties
        % string name for this game sessions
        name = '';
        
        % the current Dotris game score
        score = 0;
        
        % height of the game board in logical units
        boardHeight = 24;
        
        % width of the game board in logical units
        boardWidth = 12;
        
        % how far down new pieces start and where the game ends
        heightOffset = 1;
        
        % logical matrix representing the game board
        boardGrid;
        
        % logical matrix representing the piled up game pieces
        pileGrid;
        
        % logical matrix representin the current game piece
        currentPieceGrid;
        
        % logical matrix representing the next game piece
        nextPieceGrid;
        
        % string names for each type of game piece
        pieceNames = {'J', 'L', 'Z', 'S', 'O', 'I'};
        
        % string name of the type of the current game piece
        currentPieceName;
        
        % string name of the type of the next game piece
        nextPieceName;
        
        % output value indicating that pieces collided
        outputRatchetLanded = 'pieceLanded';
        
        % output value indicating that pieces did not collide
        outputRatchetOK = 'ready';
        
        % output value indicating that the game is over
        outputGameOver = 'gameOver';
        
        % output value indicating that the game may continue
        outputContinue = 'ready';
    end
    
    methods
        % Constructor takes no arguments.
        function self = DotrisLogic(name)
            if nargin >= 1
                self.name = name;
            end
            self.startDotris();
        end
        
        % Start a new Dotris game.
        function startDotris(self)
            % initialize logical grids for game board and pieces
            %   all have the same size, act like layers
            w = self.boardWidth;
            h = self.boardHeight;
            self.boardGrid = false(h, w);
            self.boardGrid(1,:) = true;
            self.boardGrid(:,[1,w]) = true;
            self.currentPieceGrid = false(h, w);
            self.pileGrid = false(h, w);
            
            % make a new pice and a next piece
            self.newPiece();
            self.newPiece();
            
            % new game
            self.score = 0;
        end
        
        % Make a new piece with a random shape.
        function newPiece(self)
            % bump the "next" piece up to the "current" piece
            self.currentPieceGrid = self.nextPieceGrid;
            self.currentPieceName = self.nextPieceName;
            
            % place the new "next" piece at the top-middle of the board
            w = self.boardWidth;
            col = floor(w/2);
            h = self.boardHeight;
            row = h-self.heightOffset;
            piece = false(h,w);
            
            % randomy choose the shape of the new "next" piece
            %   fill in a grid with the piece shape
            type = 1 + floor(rand()*6);
            self.nextPieceName = self.pieceNames{type};
            switch self.nextPieceName
                case 'J'
                    piece(row, col+[-1 0 1]) = true;
                    piece(row-1, col-1) = true;
                case 'L'
                    piece(row, col+[-1 0 1]) = true;
                    piece(row-1, col+1) = true;
                case 'Z'
                    piece(row, col+[-1 0]) = true;
                    piece(row-1, col+[0 1]) = true;
                case 'S'
                    piece(row, col+[0 1]) = true;
                    piece(row-1, col+[-1 0]) = true;
                case 'O'
                    piece(row, col+[0 1]) = true;
                    piece(row-1, col+[0 1]) = true;
                case 'I'
                    piece(row, col+[-1 0 1 2]) = true;
                    
            end
            self.nextPieceGrid = piece;
        end
        
        % Slide the current piece side-to-side.
        % @param direction + -> right, - -> left
        function slidePiece(self, direction)
            % move the current piece in a temporary variable
            piece = self.currentPieceGrid;
            if direction > 0
                piece = piece(:,[end,1:end-1]);
            else
                piece = piece(:,[2:end,1]);
            end
            
            % only save the movement if there are no collisions
            if ~DotrisLogic.gridsAreColliding( ...
                    piece, self.boardGrid, self.pileGrid)
                self.currentPieceGrid = piece;
            end
        end
        
        % Spin the current piece in place.
        % @param direction + -> counterclockwise, - -> clockwise
        function spinPiece(self, direction)
            % spin the piece in a temporary variable
            piece = self.currentPieceGrid;
            
            % find grid points rotated about the piece's geometric mean
            [row,col,sz] = DotrisLogic.gridSubscripts(piece);
            rowMean = round(prod(row).^(1/4));
            colMean = round(prod(col).^(1/4));
            if direction > 0
                % counterclockwise
                spunRow = colMean-col + rowMean;
                spunCol = row-rowMean + colMean;
                
            else
                % clockwise
                spunRow = col-colMean + rowMean;
                spunCol = rowMean-row + colMean;
            end
            
            % are the rotated points within bounds?
            if all(spunRow > 0) && all(spunRow <= sz(1)) ...
                    && all(spunCol > 0) && all(spunCol <= sz(2))
                
                % replace the piece grid points with rotated grid points
                indexes = DotrisLogic.gridIndexes(spunRow, spunCol, sz);
                piece(piece) = false;
                piece(indexes) = true;
                
                % only save the rotation if there are no collisions
                if ~DotrisLogic.gridsAreColliding( ...
                        piece, self.boardGrid, self.pileGrid)
                    self.currentPieceGrid = piece;
                end
            end
        end
        
        % Move the current piece down as far as it will go, immediately.
        function dropPiece(self)
            piece = self.currentPieceGrid;
            previousPiece = self.currentPieceGrid;
            while ~DotrisLogic.gridsAreColliding( ...
                    piece, self.boardGrid, self.pileGrid)
                previousPiece = piece;
                piece = piece([2:end,1],:);
            end
            self.currentPieceGrid = previousPiece;
        end
        
        % Transfer the current piece to the pile.
        function landPiece(self)
            piece = self.currentPieceGrid;
            self.pileGrid(piece) = true;
            self.currentPieceGrid(piece) = false;
        end
        
        % Drop current piece one row, report if it bumps the pile or board.
        function output = ratchet(self)
            % move the piece down a step
            piece = self.currentPieceGrid;
            piece = piece([2:end,1],:);
            
            % check for collisions
            if DotrisLogic.gridsAreColliding( ...
                    piece, self.boardGrid, self.pileGrid)
                % the piece landed on the pile
                output = self.outputRatchetLanded;
                
            else
                % the piece is OK
                output = self.outputRatchetOK;
                self.currentPieceGrid = piece;
            end
        end
        
        % Detect full lines, clear and score them, and check for game over.
        function output = judge(self)
            % look for lines
            pile = self.pileGrid;
            rowIsLine = all(pile|self.boardGrid,2);
            rowIsLine(1) = false;
            nLines = sum(rowIsLine);
            self.score = self.score + nLines;
            
            % squeeze lines out of the pile
            pile(1:(end-nLines),:) = pile(~rowIsLine,:);
            
            % look for filled up board
            row = self.boardHeight-self.heightOffset;
            if any(pile(row,:))
                output = self.outputGameOver;
            else
                output = self.outputContinue;
            end
            self.pileGrid = pile;
        end
    end
    
    methods (Static)
        % Check whether given grids have colliding elements.
        function isColliding = gridsAreColliding(varargin)
            allGrids = cat(3, varargin{:});
            sumGrids = sum(allGrids, 3);
            isColliding = any(sumGrids(1:end) > 1);
        end
        
        % Convert a true/false grid to 1-based row and column subscripts.
        function [row, col, sz] = gridSubscripts(grid)
            sz = size(grid);
            indexes = find(grid(1:end))-1;
            col = 1 + floor(indexes/sz(1));
            row = 1 + mod(indexes, sz(1));
        end
        
        % Convert 1-based row and column subscripts to linear indexes.
        function indexes = gridIndexes(row, col, sz)
            indexes = row + (col-1)*sz(1);
        end
    end
end