classdef topsFigure < handle
    % The top-level container for Tower of Psych GUIs.
    % @details
    % topsFigure manages a Matlab figure window for use by Tower od Psych
    % Graphical User Interfaces (GUIs).  Each topsFigure can contain one or
    % more content panels which show custom plots and data, and a few
    % buttons.
    % @details
    % topsFigure also defines a standard "look and feel" for GUIs, by
    % choosing things like how to lay out GUI components and what colors
    % they should be.
    % @details
    % With the help of its content panels, topsFigure keeps track of a
    % "current item".  This may be any Matlab variable, such as a Tower of
    % Psych object or a piece of data, which was most recently viewed or
    % used through the GUI.  The various content panels can work together
    % by all using the same "current item".  topsFigure provides buttons
    % for sending the current item to the Command Window workspace and for
    % viewing the current item in more detail.
    
    properties (SetAccess = protected)
        % GUI name to display in the figure title bar
        name = 'Tower of Psych';
        
        % the color to use for backgrounds
        backgroundColor = [0.98 0.98 0.96];
        
        % the color to use for midgrounds or secondary text
        midgroundColor = [0.3 0.2 0.1];
        
        % the color to use for foregrounds or primary text
        foregroundColor = [0 0 0];
        
        % color map to use for alternate foreground colors
        colors = puebloColors(9);
        
        % default font typeface to use for text
        fontName = 'Helvetica';
        
        % default font size to use for text
        fontSize = 12;
        
        % the Matlab figure window
        fig;
        
        % how to divide the figure area between button and main panels
        figureDiv = [8 92];
        
        % the figure area reserved for content panels
        mainPanel;
        
        % the figure area reserved for buttons
        buttonPanel;
        
        % array of button graphics handles
        buttons = [];
        
        % the "current item" in use in the GUI
        currentItem;
        
        % name to give the "current item"
        currentItemName;
    end
    
    methods
        % Open an new topsGUIUtilities.
        % @param name optional name to give the figure.
        % @param varargin optional property-value pairs to set
        % @details
        % Opens a new topsFigure and initializes components.  If @a name is
        % provided, displays @a name in the title bar.  If @a varargin is
        % provided, it should contain property-value pairs to set before
        % initialization.
        function self = topsFigure(name, varargin)
            % use given name
            if nargin >= 1
                self.setName(name);
            end
            
            % set immutable properties before initialization
            if nargin >= 3
                for ii = 1:2:numel(varargin);
                    prop = varargin{ii};
                    val = varargin{ii+1};
                    self.(prop) = val;
                end
            end
            
            % initialize using given properties
            self.initialize();
        end
        
        % Close the Matlab figure and clear handle and graphics objects.
        function delete(self)
            if ishandle(self.fig)
                delete(self.fig);
            end
        end
        
        % Add a button to the button panel.
        % @param name string to display on the button
        % @param pressFunction callback for button presses
        % @details
        % Creates a new button with the given @a name and @a pressFunction
        % behavior.  Places the button in the buttonPanel for this figure
        % and automatically rearranges all the buttons.
        function addButton(self, name, pressFunction)
            button = self.makeButton(self.buttonPanel);
            set(button, ...
                'String', name, ...
                'Callback', pressFunction);
            self.buttons(end+1) = button;
            self.repositionButtons();
        end
        
        % Make a Matlab figure with a certain look and feel.
        function fig = makeFigure(self)
            fig = figure( ...
                'Color', self.backgroundColor, ...
                'Colormap', self.colors, ...
                'MenuBar', 'none', ...
                'Name', self.name, ...
                'NumberTitle', 'off', ...
                'ResizeFcn', [], ...
                'ToolBar', 'none', ...
                'WindowKeyPressFcn', {}, ...
                'WindowKeyReleaseFcn', {}, ...
                'WindowScrollWheelFcn', {});
        end
        
        % Make a Matlab uipanel with a certain look and feel.
        % @param parent figure or uipanel to hold the new uipanel
        % @details
        % Returns a new uipanel which is a child of the given @a parent, or
        % mainPanel if @a parent is omitted.  At first, the uipanel is not
        % visible.
        function panel = makeUIPanel(self, parent)
            if nargin < 2
                parent = self.mainPanel;
            end
            
            panel = uipanel( ...
                'BorderType', 'line', ...
                'BorderWidth', 1, ...
                'FontName', self.fontName, ...
                'FontSize', self.fontSize, ...
                'BackgroundColor', self.backgroundColor, ...
                'ForegroundColor', self.foregroundColor, ...
                'HighlightColor', self.midgroundColor, ...
                'ShadowColor', self.backgroundColor, ...
                'Title', '', ...
                'TitlePosition', 'lefttop', ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'Parent', parent, ...
                'SelectionHighlight', 'off', ...
                'Visible', 'off');
        end
        
        % Make a Matlab axes with a certain look and feel.
        % @param parent figure or uipanel to hold the new uipanel
        % @details
        % Returns a new axes handle which is a child of the given @a
        % parent, or mainPanel if @a parent is omitted.
        function ax = makeAxes(self, parent)
            if nargin < 2
                parent = self.mainPanel;
            end
            
            ax = axes( ...
                'Parent', parent, ...
                'Color', self.backgroundColor, ...
                'FontName', self.fontName, ...
                'FontSize', self.fontSize, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'Box', 'on', ...
                'XGrid', 'off', ...
                'YGrid', 'off', ...
                'XLim', [0 1], ...
                'YLim', [0 1], ...
                'SelectionHighlight', 'off');
        end
        
        % Make a uitable with a certain look and feel.
        % @param parent figure or uipanel to hold the new uitable
        % @param selectFunction callback for selected table cell
        % @param editFunction callback for edited table cell
        % @details
        % Returns a new uitable which is a child of the given @a parent, or
        % mainPanel if @a parent is omitted.
        % @details
        % @a selectFunction determines what happens when the user selects a
        % cell in the table.  @a selectFunction should expect the uitable
        % object as the first input a struct of selection event data as the
        % second input.
        % @details
        % @a editFunction determines what happens when the user edits a
        % cell in the table.  @a editFunction should expect the uitable
        % object as the first input a struct of edit event data as the
        % second input.
        function table = makeUITable( ...
                self, parent, selectFunction, editFunction)
            if nargin < 2
                parent = self.mainPanel;
            end
            
            if nargin < 3 || isempty(selectFunction)
                selectFunction = [];
            end
            
            if nargin < 4 || isempty(editFunction)
                editFunction = [];
            end
            
            table = uitable( ...
                'BackgroundColor', self.backgroundColor, ...
                'ForegroundColor', self.foregroundColor, ...
                'ColumnFormat', {}, ...
                'ColumnEditable', false, ...
                'ColumnName', {}, ...
                'ColumnWidth', 'auto', ...
                'RowName', {}, ...
                'RowStriping', 'off', ...
                'CellSelectionCallback', selectFunction, ...
                'CellEditCallback', editFunction, ...
                'FontName', self.fontName, ...
                'FontSize', self.fontSize, ...
                'RearrangeableColumns', 'off', ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'SelectionHighlight', 'off', ...
                'Parent', parent);
        end
        
        % Make a uitree with a certain look and feel.
        % @param parent figure or uipanel to hold the new uitree
        % @param rootNode uitreenode which is the topmost tree node
        % @param expandFunction callback for expanding tree nodes
        % @param selectFunction callback for selected tree node
        % @details
        % Makes a new uitree object which can present data in a
        % heirarchical fashion.  The uitree is wrapped in a container which
        % can scroll as needed.  The container is a child of the given @a
        % parent, or mainPanel if @a parent is omitted.
        % @details
        % @a rootNode represents the top of the heirarchical presentation.
        % It must be a uitreenode.
        % @details
        % @a expandFunction determines what data are presented beneath each
        % tree node, when each node is expanded.  @a expandFunction must
        % expect a uitreenode object as the first input and a value
        % associated with that node as the second input.  @a expandFunction
        % must return one output, which is an array of new uitreenode
        % objects to add under the expanded node, or else [].
        % @details
        % @a selectFunction determines what happens when the user selects a
        % node.  @a selectFunction should expect a uitreenode object as the
        % first input and a value associated with that node as the second
        % input.
        function [tree, container] = makeUITree( ...
                self, parent, rootNode, expandFunction, selectFunction)
            if nargin < 2 || isempty(parent)
                parent = self.mainPanel;
            end
            
            if nargin < 3 || isempty(rootNode)
                rootNode = uitreenode('v0', 'root', 'root', [], false);
            end
            
            % create a tree widget and its container
            [tree, container] = uitree('v0', self.fig, ...
                'Root', rootNode, ...
                'ExpandFcn', expandFunction, ...
                'SelectionChangeFcn', selectFunction);
            
            % set appearance of the Matlab handle container
            set(container, ...
                'Parent', parent, ...
                'BackgroundColor', self.backgroundColor, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'SelectionHighlight', 'off');
            
            % set appearance of the undelying Java tree and container
            jContainer = tree.getScrollPane();
            jTree = tree.getTree();
            
            % use borderless tree and container
            jTree.setBorder([]);
            jContainer.setBorder([]);
            
            % set the tree font, which takes a little Java work
            java.lang.System.setProperty( ...
                'awt.useSystemAAFontSettings', 'on');
            property = ...
                com.jidesoft.swing.JideSwingUtilities.AA_TEXT_PROPERTY_KEY;
            jTree.putClientProperty(property, true);
            jFont = java.awt.Font( ...
                self.fontName, java.awt.Font.PLAIN, self.fontSize);
            jTree.setFont(jFont);
            
            % set the widget and container colors
            c = self.backgroundColor;
            jColor = java.awt.Color(c(1), c(2), c(3));
            jTree.setBackground(jColor);
            jRenderer = jTree.getCellRenderer();
            jRenderer.setBackgroundNonSelectionColor(jColor);
            jContainer.setBackground(jColor);
            
            c = self.foregroundColor;
            jColor = java.awt.Color(c(1), c(2), c(3));
            jTree.setForeground(jColor);
            jContainer.setForeground(jColor);
            
        end
        
        % Make a uicontrol text edit field with a certain look and feel.
        % @param parent figure or uipanel to hold the text field.
        % @param editFunction callback to handle edited text
        % @details
        % Returns a new uicontrol edit text field which is a child of the
        % given @a parent, or mainPanel if @a parent is omitted.
        % @details
        % @a editFunction determines what happens when the user finishes
        % editing text.  @a editFunction should expect a uicontrol object
        % as the first input and a struct of event data as the second
        % input.
        function e = makeEditField(self, parent, editFunction)
            if nargin < 2 || isempty(parent)
                parent = self.mainPanel;
            end
            
            if nargin < 3 || isempty(editFunction)
                editFunction = [];
            end
            
            e = uicontrol( ...
                'Style', 'edit', ...
                'Min', 0, ...
                'Max', 0.1, ...
                'BackgroundColor', self.backgroundColor, ...
                'Callback', editFunction, ...
                'FontName', self.fontName, ...
                'FontSize', self.fontSize, ...
                'ForegroundColor', self.foregroundColor, ...
                'HorizontalAlignment', 'left', ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'Parent', parent, ...
                'SelectionHighlight', 'off');
        end
        
        % Make a uicontrol button with a certain look and feel.
        % @param parent figure or uipanel to hold the new button.
        % @param pressFunction callback for pressed button
        % @details
        % Returns a new uicontrol pushbutton which is a child of the given
        % @a parent, or mainPanel if @a parent is omitted.
        % @details
        % @a pressFunction determines what happens when the user presses
        % the button.  @a pressFunction should expect a uicontrol object as
        % the first input and a struct of event data as the second input.
        function b = makeButton(self, parent, pressFunction)
            if nargin < 2 || isempty(parent)
                parent = self.mainPanel;
            end
            
            if nargin < 3 || isempty(pressFunction)
                pressFunction = [];
            end
            
            b = uicontrol( ...
                'Style', 'pushbutton', ...
                'Max', 100, ...
                'Min', 1, ...
                'BackgroundColor', self.backgroundColor, ...
                'Callback', pressFunction, ...
                'FontName', self.fontName, ...
                'FontSize', self.fontSize, ...
                'ForegroundColor', self.foregroundColor, ...
                'HorizontalAlignment', 'center', ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'Parent', parent, ...
                'SelectionHighlight', 'off');
        end
        
        % Make a widget capable of displaying HTML content.
        % @param parent figure or uipanel to hold the new widget
        % @details
        % Makes a new HTML widget which is a child of the given @a
        % parent, or mainPanel if @a parent is omitted.  The widget
        % is wrapped in a container which can scroll as needed.  Both a
        % Matlab graphics handle and a Java object are returned, for both
        % the widget and the container.  The four outputs are returned
        % following order:
        %   - widget handle
        %   - container handle
        %   - widget Java object
        %   - container Java object.
        %   .
        function [widget, container, jWidget, jContainer] = ...
                makeHTMLWidget(self, parent)
            if nargin < 2
                parent = self.mainPanel;
            end
            
            % create a Java Swing widget capable of showing HTML content
            %   put the widget in a scrollable Swing container
            jWidget = javax.swing.JEditorPane('text/html', '');
            jWidget.setEditable(false);
            jContainer = javax.swing.JScrollPane(jWidget);
            
            % use borderless widget and container
            jWidget.setBorder([]);
            jContainer.setBorder([]);
            
            % set the widget font, which takes a little Java work
            java.lang.System.setProperty( ...
                'awt.useSystemAAFontSettings', 'on');
            jWidget.putClientProperty( ...
                javax.swing.JEditorPane.HONOR_DISPLAY_PROPERTIES, true);
            property = ...
                com.jidesoft.swing.JideSwingUtilities.AA_TEXT_PROPERTY_KEY;
            jWidget.putClientProperty(property, true);
            jFont = java.awt.Font( ...
                self.fontName, java.awt.Font.PLAIN, self.fontSize);
            jWidget.setFont(jFont);
            
            % set the widget and container colors
            c = self.backgroundColor;
            jColor = java.awt.Color(c(1), c(2), c(3));
            jWidget.setBackground(jColor);
            jContainer.setBackground(jColor);
            
            c = self.foregroundColor;
            jColor = java.awt.Color(c(1), c(2), c(3));
            jWidget.setForeground(jColor);
            jContainer.setForeground(jColor);
            
            % display the widget and container through the given parent
            %   javacomponent() is an undocumented built-in function
            %   see http://undocumentedmatlab.com/blog/javacomponent/
            [widget, container] = javacomponent(jContainer, [], parent);
            set(container, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1]);
        end
        
        % Choose the name to display in the figure title bar.
        % @param name string name of the figure
        % @details
        % Assigns @a name to this object and updates the Matlab figure
        % window.
        function setName(self, name)
            self.name = name;
            set(self.fig, 'Name', name);
        end
        
        % Choose the current item and tell panels to update.
        % @param currentItem the new current item
        % @param currentItemName name to use for the current item
        % @details
        % Assigns @a currentItem and @a currentItemName to this figure and
        % any panels.  @a currentItemName is optional.  If omitted, @a
        % currentItemName defaults to its present value.
        function setCurrentItem(self, currentItem, currentItemName)
            self.currentItem = currentItem;
            
            if nargin >= 3
                self.currentItemName = currentItemName;
            end
            
            panels = self.getPanels();
            for ii = 1:numel(panels)
                panels{ii}.setCurrentItem( ...
                    self.currentItem, self.currentItemName);
            end
            
            self.refresh();
        end
        
        % Choose the content panels to use in this GUI.
        % @param panels 2D cell array of topsPanel objects
        % @param yDiv array specifying how to arrange panels vertically
        % @param xDiv array specifying how to arrange panels horizontally
        % @details
        % Assigns the given @a panels to work with this topsFigure to make
        % a GUI.  @a panels should be a 2D cell array, where the rows and
        % columns indicate how the panels should be layed out graphically.
        % The first row and first column correspond to the bottom left
        % corner of the main panel.  Where @a panels contains empty
        % elements, the main panel is left blank.  If @a panels contains
        % duplicate adjacent elements, the duplicated panel is stretched to
        % fill more than one row or column.
        % @details
        % By default, the main panel is divided evenly into rows and
        % columns.  @a xDiv and @a yDiv may specify uneven divisions.
        % @a xDiv should have one element for each column of @a panels, and
        % @a yDiv should have one element for each row.  The elemets of @a
        % xDiv or @a yDiv specify the relative width or height of each
        % column or row, respectively.
        % @details
        % Sets the Position of each panel's uipanel for the given layout,
        % and makes each panel Visible.
        function usePanels(self, panels, yDiv, xDiv)
            % use the given panels
            self.setPanels(panels);
            
            % choose the row divisions
            nRows = size(panels, 1);
            if nargin < 3
                yDiv = ones(1, nRows) ./ nRows;
            else
                yDiv = yDiv ./ sum(yDiv);
            end
            y = [0 cumsum(yDiv)];
            
            % choose the column divisions
            nCols = size(panels, 2);
            if nargin < 4
                xDiv = ones(1, nCols) ./ nCols;
            else
                xDiv = xDiv ./ sum(xDiv);
            end
            x = [0 cumsum(xDiv)];
            
            % keep track of handles of uipanels already positioned
            alreadyPositioned = [];
            for ii = 1:nRows
                for jj = 1:nCols
                    % where is this grid cell?
                    cellPosition = [x(jj) y(ii) xDiv(jj) yDiv(ii)];
                    
                    % what is this topsPanel's uipanel handle?
                    panel = panels{ii,jj};
                    h = panel.pan;
                    
                    % position each uipanel
                    if ishandle(h)
                        if any(alreadyPositioned == h)
                            % stretch to fill additional grid cells
                            panelPosition = get(h, 'Position');
                            mergedPosition = ...
                                topsGUIUtilities.mergePositions( ...
                                cellPosition, panelPosition);
                            set(h, 'Position', mergedPosition);
                            
                        else
                            % place the panel in a new grid cell
                            alreadyPositioned(end+1) = h;
                            set(h, ...
                                'Units', 'normalized', ...
                                'Position', cellPosition);
                        end
                    end
                end
            end
            
            % now that they're positioned, make all uipanels visible
            set(alreadyPositioned, 'Visible', 'on');
        end
        
        % Tell each content panel to refresh its contents.
        % @details
        % Refreshes the appearance of this figure.  By default, also
        % invokes refresh() on child topsPanels.
        function refresh(self)
            % refresh each panel
            panels = self.getPanels();
            for ii = 1:numel(panels)
                panels{ii}.refresh();
            end
            
            % any self behaviors?
        end
        
        % Try to open the current item as a file.
        function currentItemOpenAsFile(self)
            
            % does the current item indicate a file name?
            item = self.currentItem;
            mName = '';
            if isa(item, 'function_handle')
                % open a funciton's m-file
                mName = func2str(item);
                
            elseif ischar(item)
                % open up any file
                mName = item;
            end
            
            % does the file exist?
            if ~isempty(mName) && exist(mName, 'file')
                message = sprintf('Opening file "%s"', mName);
                disp(message);
                open(mName);
                
            else
                message = sprintf('Cannot open file "%s"', mName);
                disp(message);
            end
        end
        
        % View details of the current item.
        function fig = currentItemOpenGUI(self)
            if ismethod(self.currentItem, 'gui')
                % open a class-specific GUI
                fig = self.currentItem.gui();
                
            else
                % open the generic GUI
                fig = topsGUIUtilities.openBasicGUI( ...
                    self.currentItem, self.currentItemName);
            end
        end
        
        % Send the current item to the Command Window workspace.
        function currentItemToWorkspace(self)
            itemName = self.currentItemName;
            if ~isempty(itemName)
                if isvarname(itemName)
                    workspaceName = itemName;
                else
                    itemName = topsGUIUtilities.htmlStripTags( ...
                        itemName, true);
                    itemName = ...
                        topsGUIUtilities.underscoreInsteadOfNonwords( ...
                        itemName);
                    existingNames = evalin('base', 'who()');
                    workspaceName = genvarname(itemName, existingNames);
                end
                assignin('base', workspaceName, self.currentItem);
                message = sprintf('Sent "%s" to workspace', workspaceName);
                disp(message);
                evalin('base', sprintf('disp(%s)', workspaceName));
            end
        end
        
        % Store references to content panels in the Matlab figure.
        % @param panels cell array of topsPanel objects
        % @details
        % Sets the given @a panels to the UserData property of this
        % topsFigures's fig.  @a panels can be retrieved with getPanels();
        function setPanels(self, panels)
            if ishandle(self.fig)
                set(self.fig, 'UserData', panels);
            end
        end
        
        % Retrieve references to content panels from the Matlab figure.
        % @details
        % Returns a cell array of topsPanel objects that was stored in
        % UserData property of this topsFigures's fig, via setPanels().
        function panels = getPanels(self)
            panels = {};
            if ishandle(self.fig)
                panels = get(self.fig, 'UserData');
                if isempty(panels)
                    panels = {};
                end
            end
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            % clear old components
            if ishandle(self.fig)
                self.setPanels({});
                delete(self.fig);
            end
            self.fig = [];
            self.mainPanel = [];
            self.buttonPanel = [];
            self.buttons = [];
            
            % make a new figure with two panels
            self.fig = self.makeFigure();
            fd = self.figureDiv ./ sum(self.figureDiv);
            self.mainPanel = self.makeUIPanel(self.fig);
            self.buttonPanel = self.makeUIPanel(self.fig);
            set(self.mainPanel, ...
                'Position', [0 fd(1) 1 fd(2)], ...
                'Visible', 'on');
            set(self.buttonPanel, ...
                'Position', [0 0 1 fd(1)], ...
                'Visible', 'on');
            
            % populate the button panel with buttons
            self.addButton('refresh', ...
                @(obj,event)self.refresh());
            self.addButton('open as file', ...
                @(obj,event)self.currentItemOpenAsFile());
            self.addButton('open in gui', ...
                @(obj,event)self.currentItemOpenGUI());
            self.addButton('to workspace', ...
                @(obj,event)self.currentItemToWorkspace());
        end
        
        % Organize buttons in the button panel with even spacing.
        function repositionButtons(self)
            nButtons = numel(self.buttons);
            fullSize = [0 0 1 1];
            for ii = 1:nButtons
                buttonPosition = subposition(fullSize, 1, nButtons, 1, ii);
                set(self.buttons(ii), ...
                    'Units', 'normalized', ...
                    'Position', buttonPosition);
            end
        end
    end
end