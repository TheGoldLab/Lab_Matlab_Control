classdef dotsTheScreenType < handle
    % class dotsTheScreenType
    %
    % Class for defining the interface of the screen object
    %   helper functions in dotsThScreen

    properties (Abstract)
    end
    
    methods (Abstract, Access=protected)

        % Methods to define in concrete classes
        initializeForScreen(self);
        displayNumber = getDisplayNumberForScreen(self);
        openWindowForScreen(self)
        closeWindowForScreen(self)
        frameInfo = nextFrameForScreen(self, doClear)
        frameInfo = blankForScreen(self)
    end
    
    methods
        
        % Set multiple properties, when valid.
        function set(self, varargin)
            if nargin > 1
                classProps = properties(self);
                setProps   = varargin(1:2:end);
                setVals    = varargin(2:2:end);
                [~, validIndexes] = ...
                    intersect(setProps, classProps);
                for ii = 1:length(validIndexes)
                    self.(setProps{validIndexes(ii)}) = ...
                        setVals{validIndexes(ii)};
                end
            end
        end
    end
end
