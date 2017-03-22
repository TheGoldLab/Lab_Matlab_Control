classdef topsGroupedListPanel < topsPanel
    % Browse a grouped list by group and mnemonic.
    % @details
    % topsGroupedListPanel shows all of the group names for a
    % topsGroupedList, and all the mnemonic names for one group at a time.
    % The user can view and select one group and one mnemonic.  Each
    % selection updates the "current item" of a Tower of Psych GUI.
    
    properties (SetAccess = protected)
        % the uitable for group names
        groupTable;
        
        % the uitable for mnemonic names
        mnemonicTable;
        
        % uicontrol for editing the current item
        editField;
        
        % the value of the currently selected group
        currentGroup;
        
        % the value of the currently selected mnemonic
        currentMnemonic;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsGroupedListPanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        % @details
        function self = topsGroupedListPanel(varargin)
            self = self@topsPanel(varargin{:});
            self.isLocked = false;
        end
        
        % Set the current list group from a selected table cell.
        % @param table uitable object making the selection
        % @param event struct of data about the selection event
        % @details
        % Sets currentGroup and the current item for the parent figure,
        % based on the selected cell in a uitable.
        function selectGroup(self, table, event)
            % Only bother with single selections
            if size(event.Indices, 1) == 1
                % select one group
                row = event.Indices(1);
                groups = self.baseItem.groups();
                if row <= numel(groups)
                    self.currentGroup = groups{row};
                    self.populateMnemonicTable();
                    self.currentItemForGroupAndMnemonic();
                end
            end
        end
        
        % Set the current list mnemonic from a selected table cell.
        % @param table uitable object making the selection
        % @param event struct of data about the selection event
        % @details
        % Sets currentMnemonic and the current item for the parent figure,
        % based on the selected cell in a uitable.
        function selectMnemonic(self, table, event)
            % Only bother with single selections
            if size(event.Indices, 1) == 1
                % select one mnemonic
                row = event.Indices(1);
                mnemonics = ...
                    self.baseItem.getAllMnemonicsFromGroup( ...
                    self.currentGroup);
                if row <= numel(mnemonics)
                    self.currentMnemonic = mnemonics{row};
                end
                self.currentItemForGroupAndMnemonic();
            end
        end
        
        % Edit currentItem based on user-entered text.
        % @param editField uicontrol edit field which contains new text
        % @param event struct of data about the edit event
        % @details
        % Invokes eval() on the text contained in @a editField.  If eval()
        % succeeds, replaces the item selected item in groupedList, based
        % on currentGroup and currentMnemonic.  Also sets the current item
        % of the parent figure, using the new value.
        function editItem(self, editField, event)
            % get the text that the user entered
            entry = get(editField, 'String');
            
            if ~isempty(entry)
                % try to get a new item from the text
                newItem = [];
                isEvalSuccess = true;
                try
                    newItem = eval(entry);
                catch evalErr
                    disp('Error edititng item:');
                    disp(evalErr.message);
                    isEvalSuccess = false;
                end
                
                if isEvalSuccess
                    % put the new item in the grouped list
                    self.baseItem.addItemToGroupWithMnemonic( ...
                        newItem, self.currentGroup, self.currentMnemonic);
                    
                    % update the figure's current item
                    self.parentFigure.setCurrentItem(newItem);
                    
                    % prepare for fresh text entry
                    set(editField, 'String', '');
                end
            end
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            % how to split up the panel for three ui components
            yDiv = 0.1;
            xDiv = 0.5;
            
            % new table for groups
            self.groupTable = self.parentFigure.makeUITable( ...
                self.pan, ...
                @(table, event)self.selectGroup(table, event));
            set(self.groupTable, ...
                'Position', [0 yDiv xDiv 1-yDiv], ...
                'Data', {}, ...
                'ColumnName', {'group'});
            
            % new table for mnemonics
            self.mnemonicTable = self.parentFigure.makeUITable( ...
                self.pan, ...
                @(table, event)self.selectMnemonic(table, event));
            set(self.mnemonicTable, ...
                'Position', [xDiv yDiv xDiv 1-yDiv], ...
                'Data', {}, ...
                'ColumnName', {'mnemonic'})
            
            % new text field for editing the current item
            self.editField = self.parentFigure.makeEditField( ...
                self.pan, ...
                @(field, event)self.editItem(field, event));
            set(self.editField, ...
                'Position', [0 0 1 yDiv], ...
                'String', '% edit current item');
            
            % update the tree to use groupedList
            self.updateContents();
            
            % update with the first item
            self.currentItemForGroupAndMnemonic();
        end
        
        % Refresh the group table's contents
        function populateGroupTable(self)
            % get the list of groups
            groups = self.baseItem.groups;
            groupSummary = topsGUIUtilities.makeTableForCellArray( ...
                groups(:), self.parentFigure.colors);
            
            % default or preserve the group selection
            if isempty(groups)
                self.currentGroup = [];
                
            elseif isempty(self.currentGroup)
                self.currentGroup = groups{1};
                
            elseif ~self.baseItem.containsGroup(self.currentGroup);
                self.currentGroup = groups{1};
            end
            
            % set the column width from the table width
            %   which is irritating
            set(self.groupTable, 'Units', 'pixels');
            pixelPosition = get(self.groupTable, 'Position');
            columnWidth = pixelPosition(3) - 5;
            set(self.groupTable, ...
                'Units', 'normalized', ...
                'ColumnWidth', {columnWidth}, ...
                'Data', groupSummary);
        end
        
        % Refresh the mnemonic table's contents
        function populateMnemonicTable(self)
            % get the list of group mnemonics
            if isempty(self.currentGroup)
                mnemonics = {};
            else
                mnemonics = self.baseItem.getAllMnemonicsFromGroup( ...
                    self.currentGroup);
            end
            mnemonicSummary = topsGUIUtilities.makeTableForCellArray( ...
                mnemonics(:), self.parentFigure.colors);
            
            % default or preserve the mnemonic selection
            if isempty(mnemonics)
                self.currentMnemonic = [];
            elseif ~self.baseItem.containsMnemonicInGroup( ...
                    self.currentMnemonic, self.currentGroup);
                self.currentMnemonic = mnemonics{1};
            end
            
            % set the column width from the table width
            %   which is irritating
            set(self.mnemonicTable, 'Units', 'pixels');
            pixelPosition = get(self.mnemonicTable, 'Position');
            columnWidth = pixelPosition(3) - 5;
            set(self.mnemonicTable, ...
                'Units', 'normalized', ...
                'ColumnWidth', {columnWidth}, ...
                'Data', mnemonicSummary);
        end
        
        % Refresh the panel's contents.
        function updateContents(self)
            if isobject(self.baseItem)
                % update tables with groups and mnemonics
                self.populateGroupTable();
                self.populateMnemonicTable();
                self.currentItemForGroupAndMnemonic();
            end
        end
        
        % Set the GUI current item from selected group and mnemonic.
        function currentItemForGroupAndMnemonic(self)
            if isobject(self.baseItem) && ...
                    self.baseItem.containsMnemonicInGroup( ...
                    self.currentMnemonic, self.currentGroup)
                
                % get out the selected item
                item = self.baseItem.getItemFromGroupWithMnemonic( ...
                    self.currentGroup, self.currentMnemonic);
                
                % make up a name for the selected item
                if ischar(self.currentGroup)
                    groupName = topsGUIUtilities.makeSummaryForItem( ...
                        self.currentGroup, self.parentFigure.colors);
                else
                    groupName = num2str(self.currentGroup);
                end
                
                if ischar(self.currentMnemonic)
                    mnemonicName = topsGUIUtilities.makeSummaryForItem( ...
                        self.currentMnemonic, self.parentFigure.colors);
                else
                    mnemonicName = num2str(self.currentMnemonic);
                end
                name = sprintf('%s{%s}{%s}', ...
                    self.baseItem.name, groupName, mnemonicName);
                
                % report the current item to the parent figure
                %   lock to prevent infinite update loop
                self.isLocked = true;
                self.parentFigure.setCurrentItem(item, name);
                self.isLocked = false;
            end
        end
    end
end