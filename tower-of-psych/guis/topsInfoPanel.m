classdef topsInfoPanel < topsPanel
    % Summarize the current item, like disp() on the command line.
    % @details
    % topsInfoPanel shows a summary of the "current item" of a Tower of
    % Psych GUI.  The summary comes from the built-in disp() command,
    % captured as a string.  Data of type char are highlighted according to
    % their spelling.
    
    properties (SetAccess = protected)
        % handle for an HTML display panel
        infoWidget;
        
        % handle for an HTML display panel container
        infoContainer;
        
        % HTML display panel java object
        jWidget;
        
        % HTML display container java object
        jContainer;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsInfoPanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        function self = topsInfoPanel(varargin)
            self = self@topsPanel(varargin{:});
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            [self.infoWidget, self.infoContainer, ...
                self.jWidget, self.jContainer] = ...
                self.parentFigure.makeHTMLWidget(self.pan);
        end
        
        % Refresh the panel's contents.
        function updateContents(self)
            % display a summary of the current item
            headerText = topsGUIUtilities.makeTitleForItem( ...
                self.currentItem, ...
                self.currentItemName, ...
                self.parentFigure.midgroundColor);
            
            infoText = topsGUIUtilities.makeSummaryForItem( ...
                self.currentItem, self.parentFigure.colors);
            
            summary = sprintf('<HTML>%s\n%s</HTML>', ...
                headerText, infoText);
            summary = topsGUIUtilities.htmlBreakAtLines(summary);
            self.jWidget.setText(summary);
        end
    end
end