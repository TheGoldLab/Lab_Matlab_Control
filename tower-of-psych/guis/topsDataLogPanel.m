classdef topsDataLogPanel < topsPanel
    % Browse the Tower of Psych data log.
    % @details
    % topsDataLogPanel shows an overview of data stored in topsDataLog.  It
    % has a "raster" plot which plots data groups vs. timestamps.  Users
    % can select indivitual points in the raster plot to set the "current
    % item" of a Tower of Psych GUI.  The user can also select which groups
    % to plot and the time range of the plot.
    
    properties (SetAccess = protected)
        % logical selector for which groups to plot in the raster
        groupIsPlotted;
        
        % min and max of time range to plot in the raster
        timeRange = [0 1];
        
        % axes for raster data summary
        rasterAxes;

        % cursor line for selections in rasterAxes
        rasterCursor;
        
        % the uitable for group names
        groupTable;
        
        % button for plotting full data time range
        fullRangeButton;
        
        % text edit field for for plotting a custom data time range
        chooseRangeField;
        
        % button for selecting all data groups
        allGroupsButton;
        
        % button for selecting no data groups
        noGroupsButton;
        
        % text edit field for for selecting groups by regular expression
        chooseGroupsField;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsDataLogPanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        % @details
        function self = topsDataLogPanel(varargin)
            self = self@topsPanel(varargin{:});
            self.isLocked = false;
        end
        
        % Set the GUI current item group from a clicked-on graphics object.
        % @param object graphics object that was clicked
        % @param event struct of data about the selection event
        % @details
        % Sets the current item for the parent figure, based on the
        % a data point or axes that was clicked on.
        function selectItem(self, object, event)
            if object == self.rasterAxes
                % clicked on the axes background
                self.parentFigure.setCurrentItem(...
                    self.baseItem, self.baseItemName);
                set(self.rasterCursor, 'Visible', 'off');
                
            else
                % clicked on a data point
                
                % which group does this line represent?
                group = get(object, 'UserData');
                
                % around what time did the user click?
                clickPoint = get(self.rasterAxes, 'CurrentPoint');
                clickTime = clickPoint(1,1);
                lineTimes = get(object, 'XData');
                lineRows = get(object, 'YData');
                [nearest, nearestIndex] = min(abs(lineTimes-clickTime));
                time = lineTimes(nearestIndex);
                
                if self.baseItem.containsMnemonicInGroup(time, group);
                    item = self.baseItem.getItemFromGroupWithMnemonic( ...
                        group, time);
                    name = sprintf('%s at %.4f', group, time);
                    self.parentFigure.setCurrentItem(item, name);
                    
                    % move the data cursor to this data item
                    set(self.rasterCursor, ...
                        'XData', time, ...
                        'YData', lineRows(1), ...
                        'Visible', 'on');
                end
            end
        end
        
        % Set which data groups are selected from uitable checkboxes.
        % @param table uitable object editing checkboxes
        % @param event struct of data about the edit event
        % @details
        % Updates which data groups are selected, when a user clicks a
        % uitable checkbox.
        function editGroupIsPlotted(self, table, event)
            % only look in the first table column
            column = event.Indices(2);
            if column == 1
                % which table row was edited, to what?
                row = event.Indices(1);
                isPlotted = event.NewData;
                if ~isempty(isPlotted)
                    self.groupIsPlotted(row) = isPlotted;
                    self.setGroupIsPlotted(self.groupIsPlotted);
                end
            end
        end
        
        % Select all groups to plot in the raster.
        % @param isPlotted logical selector or string specifying groups
        % @details
        % Sets which groups will be plotted in the raster axes based on the
        % given @a isPlotted.  @a isPlotted may be the string 'all', in
        % which case all groups will be ploted in the axes, or the string
        % 'none', in which case no groups will be plotted.  @a isPlotted
        % may also be a logical array with one element per data groups, in
        % which case the groups that correspond to true elements of @a
        % isPlotted will be plotted.
        % @details
        % If @a isPlotted is not a well-formed string or logical selector,
        % the groupIsPlotted remains unchanged
        function setGroupIsPlotted(self, isPlotted)
            groups = self.baseItem.groups;
            
            if ischar(isPlotted)
                % choose all or none
                switch isPlotted
                    case 'all'
                        isPlotted = true(size(self.baseItem.groups));
                        
                    case 'none'
                        isPlotted = false(size(self.baseItem.groups));
                        
                    otherwise
                        % nonsense string
                        return;
                end
                
            elseif islogical(isPlotted)
                % validate the logical selector
                if numel(groups) ~= numel(isPlotted)
                    % nonsense selector
                    return;
                end
            else
                % nonsense
                return
            end
            
            % apply the new selector
            self.groupIsPlotted = isPlotted;
            self.populateGroupTable();
            self.plotRaster();
        end
        
        % Choose groups to plot in the raster that match an expression.
        % @param expression string regular expression to match group names
        % @details
        % Adds data groups that match the given @a expresssion to the
        % groups that are ploted in the raster.
        function setMatchingGroupIsPlotted(self, expression)
            [matches, isMatch] = ...
                self.baseItem.getGroupNamesMatchingExpression(expression);
            self.setGroupIsPlotted(isMatch);
        end
        
        % Set the time range for the raster plot.
        % @param range numeric array or string specifying the time range
        % @details
        % Sets timeRange based on the given @a range.  If @a range is
        % numeric, sets timeRange to the min and max of @a range.  If @a
        % range is the string 'all', uses the entire range of data from the
        % data log.  If @a range is another  string, attempts to create a
        % numeric array by passing @a range to the built-in eval().
        % @details
        % If @a range is not a well-formed array or string, or doesn't
        % contain distinct min and max, timeRange is unchanged.  If @a
        % range may contain -inf or inf, in which case the timeRange will
        % include the earliest or latest data item from the data log.
        function setTimeRange(self, range)
            numRange = [];
            if ischar(range)
                if strcmp(range, 'all')
                    % choose the full range
                    numRange = [-inf inf];
                else
                    % try to use a custom range
                    try
                        numRange = eval(range);
                    catch evalErr
                        disp('Error setting time range:');
                        disp(evalErr.message);
                        return;
                    end
                end
            elseif isnumeric(range)
                % use the given numeric range
                numRange = range;
                
            else
                % nonsense range
                return;
            end
            
            % do inf or nan substitutions
            rangeMin = min(numRange);
            if ~isfinite(rangeMin)
                rangeMin = self.baseItem.earliestTime();
            end
            
            rangeMax = max(numRange);
            if ~isfinite(rangeMax)
                rangeMax = self.baseItem.latestTime();
            end
            
            % check for distinct min and max
            if rangeMin < rangeMax
                % go with the new range
                self.timeRange = [rangeMin, rangeMax];
                set(self.chooseRangeField, ...
                    'String', sprintf('[%.0f, %.0f]', rangeMin, rangeMax));
                self.plotRaster();
            end
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            % how to split up the panel real estate
            yDiv = 0.4;
            xDiv = 0.3;
            
            % how big to make buttons and text fields
            w = xDiv/2;
            h = yDiv/5;
            
            % axes for data raster overview
            padding = [0.01 0.01 -0.02 -0.06];
            self.rasterAxes = self.parentFigure.makeAxes(self.pan);
            set(self.rasterAxes, ...
                'Position', [0 yDiv 1 1-yDiv] + padding, ...
                'YTick', [], ...
                'Box', 'on', ...
                'XGrid', 'on', ...
                'XAxisLocation', 'top', ...
                'HitTest', 'on', ...
                'ButtonDownFcn', @(ax, event)self.selectItem(ax, event));
            
            % table for groups
            self.groupTable = self.parentFigure.makeUITable( ...
                self.pan, ...
                [], ...
                @(table, event)self.editGroupIsPlotted(table, event));
            set(self.groupTable, ...
                'Position', [xDiv 0 1-xDiv yDiv], ...
                'ColumnName', {'plot', 'group'}, ...
                'ColumnEditable', [true, false], ...
                'Data', {true, 'cheese'});
            
            % button to select no groups
            padding = [1 1 -2 -2]*0.005;
            self.noGroupsButton = self.parentFigure.makeButton( ...
                self.pan, ...
                @(button, event)self.setGroupIsPlotted('none'));
            set(self.noGroupsButton, ...
                'String', 'plot none', ...
                'Position', [0 yDiv-h w, h] + padding);
            
            % button to select all groups
            self.allGroupsButton = self.parentFigure.makeButton( ...
                self.pan, ...
                @(button, event)self.setGroupIsPlotted('all'));
            set(self.allGroupsButton, ...
                'String', 'plot all', ...
                'Position', [w yDiv-h w, h] + padding);
            
            % field to select groups by regular expression matching
            self.chooseGroupsField = self.parentFigure.makeEditField( ...
                self.pan, ...
                @(field, event)self.setMatchingGroupIsPlotted( ...
                get(field, 'String')));
            set(self.chooseGroupsField, ...
                'String', 'plot matching groups', ...
                'Position', [0 yDiv-2*h xDiv h] + padding);
            
            % button for plotting all data times
            self.fullRangeButton = self.parentFigure.makeButton( ...
                self.pan, ...
                @(button, event)self.setTimeRange('all'));
            set(self.fullRangeButton, ...
                'String', 'full range', ...
                'Position', [0 h xDiv, h] + padding);
            
            % field for choosing a custom time range
            self.chooseRangeField = self.parentFigure.makeEditField( ...
                self.pan, ...
                @(field, event)self.setTimeRange(get(field, 'String')));
            set(self.chooseRangeField, ...
                'String', 'time range', ...
                'Position', [0 0 xDiv h] + padding);
            
            % go get the data log
            log = topsDataLog.theDataLog();
            if isempty(log.name)
                name = class(log);
            else
                name = log.name;
            end
            self.setBaseItem(log, name);
            
            % update the groups and raster plot
            self.updateContents();
        end
        
        % Refresh the panel's contents.
        function updateContents(self)
            % repopulate table with group names and selections
            self.setGroupIsPlotted('all');
            self.populateGroupTable();
            
            % summarize all the data in the raster plot
            self.setTimeRange('all');
            self.plotRaster();
        end
        
        % Refresh the group table's contents
        function populateGroupTable(self)
            % summarize the list of groups
            groups = self.baseItem.groups;
            groupSummary = topsGUIUtilities.makeTableForCellArray( ...
                groups(:), self.parentFigure.colors);
            
            % combine with which groups are plotted
            tableData = ...
                cat(2, num2cell(self.groupIsPlotted(:)), groupSummary);
            
            % set the column width from the table width
            %   which is irritating
            set(self.groupTable, 'Units', 'pixels');
            pixelPosition = get(self.groupTable, 'Position');
            columnWidth = [0.1 0.9]*pixelPosition(3) - 2;
            set(self.groupTable, ...
                'Units', 'normalized', ...
                'ColumnWidth', num2cell(columnWidth), ...
                'Data', tableData);
        end
        
        % Summarize logged data as groups vs timestamp.
        function plotRaster(self)
            % clear out old plot objets
            oldPlot = get(self.rasterAxes, 'Children');
            delete(oldPlot(ishandle(oldPlot)));
            
            % adjust axest to accomodate groups and time range
            %   use a hack to avoid exponential x-tick-lable notation
            groups = self.baseItem.groups;
            plotGroups = groups(self.groupIsPlotted);
            nGroups = numel(plotGroups);
            set(self.rasterAxes, ...
                'YLim', [0, 2*nGroups+1], ...
                'XTickMode', 'auto', ...
                'XTickLabelMode', 'auto', ...
                'XLim', self.timeRange);
            ticks = get(self.rasterAxes, 'XTick');
            set(self.rasterAxes, 'XTickLabel', ticks);
            
            % make a new cursor line for selections in rasterAxes
            self.rasterCursor = line(0, 0, ...
                'Parent', self.rasterAxes, ...
                'Color', self.parentFigure.midgroundColor, ...
                'LineStyle', 'none', ...
                'Marker', '.', ...
                'MarkerSize', 25, ...
                'HitTest', 'off', ...
                'Visible', 'off');
            
            % make a new label and irregular series for each group
            for ii = 1:nGroups
                plotRow = 2*(nGroups-ii+1);
                
                group = plotGroups{ii};
                groupColor = topsGUIUtilities.getColorForString( ...
                    group, self.parentFigure.colors);
                paddedGroup = [' ' group];
                text(self.timeRange(1), plotRow, paddedGroup, ...
                    'Parent', self.rasterAxes, ...
                    'Color', groupColor, ...
                    'FontSize', self.parentFigure.fontSize, ...
                    'HitTest', 'off');
                
                groupData = ...
                    self.baseItem.getAllItemsFromGroupAsStruct(group);
                times = [groupData.mnemonic];
                rows = (plotRow-1)*ones(size(times));
                cb = @(obj,event)self.selectItem(obj, event);
                line(times, rows, ...
                    'Parent', self.rasterAxes, ...
                    'Color', groupColor, ...
                    'LineStyle', 'none', ...
                    'Marker', '.', ...
                    'MarkerSize', 15, ...
                    'HitTest', 'on', ...
                    'UserData', group, ...
                    'ButtonDownFcn', cb);
            end
        end
    end
end