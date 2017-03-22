classdef dotsAllSingletonObjects < handle
    % @class dotsAllSingletonObjects
    % Abstract superclass defining interface for singleton classes.
    % @details
    % All the Snow Dots classes that will act as singletons (only one can
    % exist at a time) should use the same interface.  This includes:
    %   - a static "factory" method called theObject(), which returns the
    %   current, only instance of the class, and optionally takes set()
    %   arguments.
    %   - a static gui() method, which invokes some kind of graphical
    %   interface, like a topsGroupedListGUI, for inspecting the current
    %   instance.
    %   - a static reset() method which restores the current instance to a
    %   fresh state, without deleting it (existing handles to the insance
    %   should remain valid after resetting), and optionally takes set()
    %   arguments.
    %   - a non-static, initialize() method used by the class constructor
    %   and reset() method, which restores the instance to a fresh state
    %   without deleting it.
    %   - a non-static set() method which assigns a variable number of
    %   property-value pairs to the class instance
    %   .
    % All of thses should provide useful behavior without any arguments.
    
    methods (Static, Abstract)
        % Return the current class instance from the private constructor.
        obj = theObject(varargin);
        
        % Restore a fresh state without deleting the current instance.
        reset(varargin);
        
        % Launch a grapical interface for the current instance.
        g = gui();
    end
    
    methods (Abstract)
        % Restore a fresh state without deleting the current object, used
        % by constructor and reset().
        initialize(self);
    end
    
    methods
        % Create or refresh topsGroupedList instances.
        function initializeLists(self, listNames)
            for ii = 1:length(listNames)
                list = self.(listNames{ii});
                if isobject(list) && isvalid(list)
                    list.removeAllGroups;
                else
                    list = topsGroupedList;
                end
                self.(listNames{ii}) = list;
            end
        end
        
        % Set multiple properties.
        function set(self, varargin)
            if nargin > 1
                classProps = properties(self);
                setProps = varargin(1:2:end);
                setVals = varargin(2:2:end);
                [validProps, validIndexes] = ...
                    intersect(setProps, classProps);
                for ii = 1:length(validIndexes)
                    index = validIndexes(ii);
                    self.(setProps{index}) = setVals{index};
                end
            end
        end
    end
end