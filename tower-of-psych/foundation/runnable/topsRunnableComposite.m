classdef topsRunnableComposite < topsRunnable
    % @class topsRunnableComposite
    % Superclass for objects that run just by running other objects.
    % @details
    % The topsRunnableComposite superclass provides a common interface for
    % runnable objects that compose other runnable objects, and refer to
    % these as "children".  topsRunnableComposite objects run() by
    % combining the run() behaviors of their children.  They may do this in
    % any way.

    properties
        % cell array of topsRunnable (or subclass) objects
        children = {};
    end
    
    methods
        % Constuct with name optional.
        % @param name optional name for this object
        % @details
        % If @a name is provided, assigns @a name to this object.
        function self = topsRunnableComposite(varargin)
            self = self@topsRunnable(varargin{:});            
        end

        % Open a GUI to view object details.
        % @details
        % Opens a new GUI with components suitable for viewing objects of
        % this class.  Returns a topsFigure object which contains the GUI.
        function fig = gui(self)
            fig = topsFigure(self.name);
            treePan = topsRunnablesPanel(fig);
            infoPan = topsInfoPanel(fig);
            fig.usePanels({treePan, infoPan});
            treePan.setBaseItem(self, self.name);
                        
            % add a "run" button to the figure
            fig.addButton('run', @(button, event)self.run());

        end

        % Add a child beneath this object.
        % @param child a topsRunnable to add beneath this object.
        % @details
        % Appends @a child to the children array of this object.
        function addChild(self, child)
            self.children = topsFoundation.cellAdd(self.children, child);
        end
        
        % Remove a child beneath this object.
        % @param child a topsRunnable to remove fmor beneath this object.
        % @details
        % Removes all instances of @a child from the children array of this
        % object.
        function removeChild(self, child)
            self.children = ...
                topsFoundation.cellRemoveItem(self.children, child);
        end
    end
end