classdef DotrisAV < handle
    % @class DotrisAV
    % Manage graphics and sound for the "Dotris" game.
    % @details
    % DotrisAV is the audio-visual "front end" of the Dotris game.
    % It manages look and feel and graphical and sound resources.
    % @details
    % DotrisAV should transform the unitless geometry of DotrisLogic
    % into viewable graphics and possibly fun sounds.  It "knows about" a
    % DotrisLogic object, from which it can do the graphics and sound.
    % It shouldn't modify the DotrisLogic object.
    % @details
    % DotrisAV doesn't know *when* do do graphics and sound behaviors.
    % It's up to some other function or class to coordinate the behaviors
    % of a DotrisAV object, a DotrisLogic object, and user input.
    %
    % @ingroup dotsDemos
    
    properties
        % the DotrisLogic object to work with
        logic;
    end
    
    methods
        % Make a new AV object.
        % @param logic DotrisLogic object to work with
        function self = DotrisAV(logic)
            if nargin >= 1
                self.logic = logic;
            end
        end
        
        % Set up audio-visual resources as needed.
        function initialize(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Clean up audio-visual resources from initialize().
        function terminate(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Update the game board.
        function doBoard(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Update the current game piece.
        function doCurrentPiece(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Update the next game piece.
        function doNextPiece(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Update the pile of pieces at the bottom.
        function doPile(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Hide the game board while paused.
        function doPause(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Show the game board after pausing.
        function doUnpause(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Update the score presentation.
        function doScore(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Update all things at once.
        function updateEverything(self)
            s = dbstack();
            disp(s(1).name)
        end
    end
end
