classdef SquareTagAVPlus < SquareTagAV
    % @class SquareTagAVPlus
    % Draw Square Tag graphics with OpenGL.
    % @details
    % SquareTagAVPlus is a graphical "front end" of the SquareTag task.
    % It draws graphics with the Snow Dots OpenGL features.
    %
    % @ingroup dotsDemos
    
    properties
        % width of the play field in degrees visual angle
        width = 30;
        
        % height of the play field in degrees visual angle
        height = 20;
        
        % background color for the task
        backgroundColor = [0 0 0];
        
        % color for squares yet to be tagged
        squareColor;
        
        % color for squares already tagged
        taggedColor;
        
        % color for the subject's cursor
        cursorColor;
    end
    
    properties(SetAccess = protected)
        % convenience reference to dotsTheScreen
        screen;
        
        % targets object to represent squares
        squares;
        
        % targets object to represnet the cursor
        cursor;
    end
    
    methods
        % Make a new AV objecsquares.
        function self = SquareTagAVPlus(varargin)
            self = self@SquareTagAV(varargin{:});
            
            % choose some nice default colors
            nColors = 9;
            colors = puebloColors(nColors);
            shuffle = randperm(nColors);
            self.squareColor = colors(shuffle(1),:);
            self.taggedColor = colors(shuffle(2),:);
            self.cursorColor = colors(shuffle(3),:);
        end
        
        % Set up audio-visual resources as needed.
        function initialize(self)
            % a targets object to represent squares
            self.squares = dotsDrawableTargets();
            self.squares.width = 1;
            self.squares.height = 1;
            self.squares.xCenter = 0;
            self.squares.yCenter = 0;
            self.squares.colors = self.squareColor;
            self.squares.nSides = 4;
            self.squares.isVisible = false;
            
            % a targets object to represent the cursor
            self.cursor = dotsDrawableTargets();
            self.cursor.xCenter = 0;
            self.cursor.yCenter = 0;
            self.cursor.colors = self.cursorColor;
            self.cursor.nSides = 12;
            self.cursor.width = 0.5;
            self.cursor.height = 0.5;
            self.cursor.isVisible = false;
            
            % open up the drawing window
            self.screen = dotsTheScreen.theObject();
            self.screen.backgroundColor = self.backgroundColor;
            self.screen.open();
            
            % let drawable objects react to the new window, as needed
            self.squares.prepareToDrawInWindow();
            self.cursor.prepareToDrawInWindow();
        end
        
        % Clean up audio-visual resources from initialize().
        function terminate(self)
            % finish with the drawing window
            self.screen.close();
        end
        
        % Indicate start of trial.
        function doBeforeSquares(self)
            % update square positions for this trial
            nSquares = self.logic.nSquares;
            squarePos = self.logic.squarePositions;
            widths = squarePos(:,3)*self.width;
            heights = squarePos(:,4)*self.height;
            xCenters = (squarePos(:,1)-0.5)*self.width + widths/2;
            yCenters = (squarePos(:,2)-0.5)*self.height + heights/2;
            self.squares.width = widths;
            self.squares.height = heights;
            self.squares.xCenter = xCenters;
            self.squares.yCenter = yCenters;
            
            % reset square colors for the start of the trial
            %   repeat the colors to facilitate per-square coloring, below
            self.squares.colors = repmat(self.squareColor, nSquares, 1);
            
            % show squares and cursor
            self.squares.isVisible = true;
            self.cursor.isVisible = true;
            
            self.drawEverything();
        end
        
        % Indicate ready to tag next square.
        function doNextSquare(self)
            % re-color the tagged squares
            nTagged = self.logic.currentSquare-1;
            self.squares.colors(1:nTagged,:) = ...
                repmat(self.taggedColor, nTagged, 1);
            self.drawEverything();
        end
        
        % Indicate end of trial.
        function doAfterSquares(self)
            % hide squares and cursor
            self.squares.isVisible = false;
            self.cursor.isVisible = false;
            
            self.drawEverything();
        end
        
        % Update the subject's cursor.
        function updateCursor(self)
            % move the cursor to a new position
            point = self.logic.cursorLocation;
            self.cursor.xCenter = (point(1)-0.5)*self.width;
            self.cursor.yCenter = (point(2)-0.5)*self.height;
            
            self.drawEverything();
        end
        
        % utility to draw all graphics and flip screen buffers
        function drawEverything(self)
            self.squares.mayDrawNow();
            self.cursor.mayDrawNow();
            self.screen.nextFrame();
        end
    end
end
