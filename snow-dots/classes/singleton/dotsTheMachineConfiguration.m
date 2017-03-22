classdef dotsTheMachineConfiguration < dotsAllSingletonObjects
    % @class dotsTheMachineConfiguration
    % Singleton to organize machine-specific defaults.
    % @details
    % dotsTheMachineConfiguration organizes values for configuring a
    % particular computer, such as its IP address, screen dimensions, or
    % path for locating files.
    % @details
    % dotsTheMachineConfiguration starts out with a set of "factory
    % default" values which are valid but not always useful.  From there it
    % can read and write custom values stored in an .xml file.  If an .xml
    % file with a standard name is on the Matlab path,
    % dotsTheMachineConfiguration automatically loads values from that
    % file.  See dotsTheMachineConfiguration.getHostFilename()
    % for the machine-specific name to use for the standard .xml file.
    % @details
    % dotsTheMachineConfiguration.writeUserSettingsFile() opens a dialog
    % for saving custom values.  It suggests the machine-specific, standard
    % name bu default.  So this is an easy way to create an .xml file with
    % custom values.
    % @details
    % Values stored in .xml files are written out as Matlab expresssions,
    % which can be passed to Matlab's built-in eval() function.  So the
    % .xml contents are human-readable.
    % @details
    % .xml files can be edited outside of Matlab.  New groups and values
    % can be added, as long as new sections follow the structure of
    % existing sections.
    
    properties
        % topsGroupedList that contains the current settings values
        % @details
        % Settings groups are strings, such as class names.  Group
        % mnemonics are strings, such as property names.
        settings;
        
        % file name of the currently loaded settings file
        % @details
        % settingsFile may contain an absolute path along with the name of
        % a settings .xml file.  If settingsFile is empty or Matlab cannot
        % locate it with the built-in exist() function,
        % dotsTheMachineConfiguration will use default settings values.
        settingsFile;
    end
    
    properties (SetAccess = protected)
        % group name for generic defaults
        defaultGroup = 'defaults';
    end
    
    methods (Access = private)
        % Constructor is private.
        % @details
        % dotsTheMachineConfiguration is a singleton object, so its
        % constructor is not accessible.  Use
        % dotsTheMachineConfiguration.theObject() to access the current
        % instance.
        function self = dotsTheMachineConfiguration(varargin)
            self.set(varargin{:});
            self.initialize();
        end
    end
    
    methods
        % Restore dotsTheMachineConfiguration to a fresh state.
        % @details
        % Discards the current settings values and attempts to reload
        % values from one of the following sources, in order:
        %   - the current settingsFile
        %   - the default "host settings" file
        %   - the hard-coded defaults
        function initialize(self)
            self.initializeLists({'settings'});
            
            % what is the standard file name?
            hostFile = ...
                dotsTheMachineConfiguration.getHostFilename();
            if exist(self.settingsFile, 'file')
                % reload current settings
                self.settingsFromXmlFile(self.settingsFile);
                
            elseif exist(hostFile, 'file')
                % load "host settings"
                self.settingsFromXmlFile(which(hostFile));
                
            else
                % fallback on generic defaults
                self.setFactoryDefaults();
                self.settingsFile = '';
            end
        end

        % Create an xml document object that contains the current settings.
        % @details
        % Returns a new com.mathworks.xml Java document object which
        % contains the settings from settings.  Each value is converted
        % to a string using the Snow Dots primitiveToString() utility.
        function xDoc = settingsToXmlDocument(self)
            xDoc = com.mathworks.xml.XMLUtils.createDocument( ...
                'dotsMachineConfig');
            xRoot = xDoc.getDocumentElement;
            groups = self.settings.groups;
            for ii = 1:length(groups)
                groupNode = xDoc.createElement(groups{ii});
                [values, settings] = ...
                    self.settings.getAllItemsFromGroup(groups{ii});
                for jj = 1:length(settings)
                    settingNode = xDoc.createElement(settings{jj});
                    settingNode.setTextContent( ...
                        primitiveToString(values{jj}));
                    groupNode.appendChild(settingNode);
                end
                xRoot.appendChild(groupNode);
            end
        end
        
        % Read new settings from an xml document object.
        % @param xDoc a com.mathworks.xml Java document object which
        % contains settings values.
        % @details
        % Discards the current settings and populates settings with
        % values from @a xDoc.  Uses eval() to convert stored value strings
        % to Matlab variables.  @a xDoc should resemble the document
        % objects returned from settingsToXmlDocument().
        % @details
        % @a xDoc may be a partial list of settings.  Missing settings will
        % be filled in with default values from setFactoryDefaults().
        function settingsFromXmlDocument(self, xDoc)
            self.setFactoryDefaults();
            xRoot = xDoc.getDocumentElement;
            groupNode = xRoot.getFirstChild;
            while ~isempty(groupNode)
                groupName = char(groupNode.getNodeName);
                settingNode = groupNode.getFirstChild;
                while ~isempty(settingNode)
                    if settingNode.getNodeType == settingNode.ELEMENT_NODE
                        settingName = char(settingNode.getNodeName);
                        settingString = char(settingNode.getTextContent);
                        settingValue = eval(settingString);
                        self.settings.addItemToGroupWithMnemonic( ...
                            settingValue, groupName, settingName);
                    end
                    settingNode = settingNode.getNextSibling;
                end
                groupNode = groupNode.getNextSibling;
            end
        end
        
        % Write an .xml file that contains the current settings.
        % @param fileWithPath the file name, which may contain a path,
        % where to write xml data.
        % @details
        % Writes an .xml file containing the current settings, at the given
        % @a fileWithPath.  Uses settingsToXmlDocument() to covert the
        % current settings to a com.mathworks.xml Java document object,
        % then writes the document object to file.
        % @details
        % Since the resulting .xml file contains human-readable strings,
        % the settings in it can be edited from any text editor.  The only
        % constraint is that the strings produce valid variables when
        % passed to Matlab's eval() function.
        % @details
        % The static methods
        % dotsTheMachineConfiguration.readUserSettingsFile() and
        % dotsTheMachineConfiguration.writeUserSettingsFile() may be more
        % convenient to use.
        function settingsToXmlFile(self, fileWithPath)
            if ischar(fileWithPath) && ~isempty(fileWithPath)
                xDoc = self.settingsToXmlDocument;
                xmlwrite(fileWithPath, xDoc);
                self.settingsFile = fileWithPath;
            end
        end
        
        % Read an .xml file that contains new settings.
        % @param fileWithPath the file name, which may contain a path,
        % where to find xml data.
        % @details
        % Reads an .xml file containing the new settings from the given @a
        % fileWithPath.  Uses settingsFromXmlDocument() to parse the file
        % then uses Matlab's eval() to convert stored strings to Matlab
        % variable and stores them in settings.  Discards any previous
        % settings.
        % @details
        % The static methods
        % dotsTheMachineConfiguration.readUserSettingsFile() and
        % dotsTheMachineConfiguration.writeUserSettingsFile() may be more
        % convenient to use.
        function settingsFromXmlFile(self, fileWithPath)
            if ischar(fileWithPath) && ~isempty(fileWithPath)
                xDoc = xmlread(fileWithPath);
                self.settingsFromXmlDocument(xDoc);
                self.settingsFile = fileWithPath;
            end
        end
    end
    
    methods (Access = protected)
        % Restore dotsTheMachineConfiguration to its factory state.
        % @details
        % Discards the current settings values and loads the hard-coded
        % factory defaults.
        function setFactoryDefaults(self)
            self.settings.removeAllGroups();
            
            group = self.defaultGroup;
            self.settings.addItemToGroupWithMnemonic( ...
                true, group, 'imagesPath');
            self.settings.addItemToGroupWithMnemonic( ...
                '~', group, 'soundsPath');
            self.settings.addItemToGroupWithMnemonic( ...
                '~', group, 'tasksPath');
            self.settings.addItemToGroupWithMnemonic( ...
                '~', group, 'dataPath');
            self.settings.addItemToGroupWithMnemonic( ...
                @mglGetSecs, group, 'clockFunction');
            self.settings.addItemToGroupWithMnemonic( ...
                'dotsDOut1208FS', group, 'dOutClassName');
            
            group = 'dotsTheScreen';
            self.settings.addItemToGroupWithMnemonic( ...
                0, group, 'displayIndex');
            self.settings.addItemToGroupWithMnemonic( ...
                1, group, 'width');
            self.settings.addItemToGroupWithMnemonic( ...
                1, group, 'height');
            self.settings.addItemToGroupWithMnemonic( ...
                2, group, 'distance');
            self.settings.addItemToGroupWithMnemonic( ...
                [], group, 'bitDepth');
            self.settings.addItemToGroupWithMnemonic( ...
                1, group, 'multisample');
            self.settings.addItemToGroupWithMnemonic( ...
                [0 0 0], group, 'backgroundColor');
            self.settings.addItemToGroupWithMnemonic( ...
                [1 1 1], group, 'foregroundColor');
            
            group = 'dotsTheMessenger';
            self.settings.addItemToGroupWithMnemonic( ...
                'dotsSocketPnet', group, 'socketClassName');
            self.settings.addItemToGroupWithMnemonic( ...
                0, group, 'receiveTimeout');
            self.settings.addItemToGroupWithMnemonic( ...
                1, group, 'ackTimeout');
            self.settings.addItemToGroupWithMnemonic( ...
                10, group, 'sendRetries');
            self.settings.addItemToGroupWithMnemonic( ...
                '127.0.0.1', group, 'defaultClientIP');
            self.settings.addItemToGroupWithMnemonic( ...
                '127.0.0.1', group, 'defaultServerIP');
            self.settings.addItemToGroupWithMnemonic( ...
                49200, group, 'defaultClientPort');
            self.settings.addItemToGroupWithMnemonic( ...
                49201, group, 'defaultServerPort');
        end
    end
    
    methods (Static)
        % Access the current instance.
        function obj = theObject(varargin)
            persistent self
            if isempty(self) || ~isvalid(self)
                constructor = str2func(mfilename);
                self = feval(constructor, varargin{:});
            else
                self.set(varargin{:});
            end
            obj = self;
        end
        
        % Restore the current instance to a fresh state.
        function reset(varargin)
            factory = str2func([mfilename, '.theObject']);
            self = feval(factory, varargin{:});
            self.initialize();
        end
        
        % Launch a graphical interface to view and set settings.
        function g = gui()
            self = dotsTheMachineConfiguration.theObject();
            
            % make the generic GroupedList gui
            g = self.settings.gui();
            
            % give it a title
            set(g.fig, 'Name', mfilename());
            
            % add a few buttons to it
            g.addButton('save', {@saveSettings, false, g});
            g.addButton('save as', {@saveSettings, true, g});
            g.addButton('load', {@refreshSettings, g});
            g.addButton('reset', {@resetSettings, g});
            
            function saveSettings(obj, event, useDialog, g)
                self = dotsTheMachineConfiguration.theObject();
                if useDialog || isempty(self.settingsFile)
                    dotsTheMachineConfiguration.writeUserSettingsFile();
                else
                    dotsTheMachineConfiguration.writeUserSettingsFile( ...
                        self.settingsFile);
                end
                g.refresh();
            end
            
            function refreshSettings(obj, event, g)
                dotsTheMachineConfiguration.readUserSettingsFile();
                g.refresh();
            end
            
            function resetSettings(obj, event, g)
                dotsTheMachineConfiguration.reset();
                g.refresh();
            end
        end
        
        % Get the standard settings file name for this host.
        % @details
        % Returns the standard file name for an .xml settings file on this
        % host, suitable for automatic loading.
        function hostFile = getHostFilename()
            if isunix()
                [stat,h] = unix('hostname -s');
            else
                h = 'windows';
            end
            hostFile = sprintf('dots_%s_MachineConfig.xml', deblank(h));
        end
        
        % Get the value of a default setting by name.
        % @param name string name of a default setting
        % @details
        % Returns the default value with the given @a name, or [] if there
        % is no default with that @a name.
        function value = getDefaultValue(name)
            self = dotsTheMachineConfiguration.theObject();
            
            group = self.defaultGroup;
            if self.settings.containsMnemonicInGroup(name, group);
                value = self.settings.getItemFromGroupWithMnemonic( ...
                    group, name);
            else
                value = [];
            end
        end
        
        % Set the value of a default setting by name.
        % @param name string name of a default setting
        % @param value new value to store under @a name
        % @details
        % Stores a new default @a value under the given @a name, or creates
        % a new default with the given @a name.
        function setDefaultValue(name, value)
            self = dotsTheMachineConfiguration.theObject();
            
            self.settings.addItemToGroupWithMnemonic( ...
                value, self.defaultGroup, name);
        end
        
        % Get all the default settings associated with a class.
        % @param className class name or object to get defaults for
        % @details
        % @a className must be a string class name, or an object, in which
        % case the object's class name is determined with the built-in
        % class() function.  Returns a struct containing all of the default
        % settings associated with the given @a className.  Struct fields
        % correspond to class properties.  If there are no default values
        % associates with @a className, returns [].
        function values = getClassDefaults(className)
            self = dotsTheMachineConfiguration.theObject();
            
            % use given class or object class?
            if isobject(className)
                group = class(className);
            else
                group = className;
            end
            
            % any defaults for this class?
            if self.settings.containsGroup(group);
                [items, mnemonics] = ...
                    self.settings.getAllItemsFromGroup(self, group);
                values = cell2struct(items, mnemonics);
                
            else
                values = [];
            end
        end
        
        % Set all the default settings associated with a class.
        % @param className class name or object to get defaults for
        % @param values struct of defaults to associate with @a className
        % @details
        % @a className must be a string class name, or an object, in which
        % case the object's class name is determined with the built-in
        % class() function.  @a values must be a struct containing default
        % settings to associate with @a className.  The fields of @a values
        % must correspond to class properties.
        function setClassDefaults(className, values)
            self = dotsTheMachineConfiguration.theObject();
            
            if isobject(className)
                group = class(className);
            else
                group = className;
            end
            
            % store each default value under the given class
            items = struct2cell(values);
            mnemonics = fieldnames(values);
            for ii = 1:numel(items)
                self.settings.addItemToGroupWithMnemonic( ...
                    items{ii}, group, mnemonics{ii});
            end
        end
        
        % Assign class defaults to the given object.
        % @param object an object to receive default values
        % @param className optional, class to impose on @a object
        % @details
        % @a object must be an object to receive default property values.
        % By default, uses class(@a object) to determine which group of
        % default values to assign to @a object.  If @a className is the
        % string name of a class, applies this group of defaults instead.
        % @details
        % If there are no default values associates with @a object or @a
        % className, does nothing.  Returns the updated @a object.
        function applyClassDefaults(object, className)
            self = dotsTheMachineConfiguration.theObject();
            
            % use given class or object class?
            if nargin >= 2 && ~isempty(className) && ischar(className)
                group = className;
            else
                group = class(object);
            end
            
            % any defaults for this class?
            if self.settings.containsGroup(group);
                [items, mnemonics] = ...
                    self.settings.getAllItemsFromGroup(group);
                objProps = properties(object);
                for ii = 1:numel(mnemonics)
                    prop = mnemonics{ii};
                    if any(strcmp(objProps, prop))
                        object.(prop) = items{ii};
                    end
                end
            end
        end
        
        % Read an .xml file that contains new settings.
        % @param fileWithPath the file name, which may contain a path,
        % where to find xml data.
        % @details
        % If @a fileWithPath is missing, opens a dialog for chosing a
        % suitable file.
        function readUserSettingsFile(fileWithPath)
            self = dotsTheMachineConfiguration.theObject();
            
            if nargin < 1 || isempty(fileWithPath) || ~ischar(fileWithPath)
                if exist(self.settingsFile, 'file')
                    [p,f,e] = fileparts(which(self.settingsFile));
                    if isempty(p)
                        p = pwd;
                    end
                    suggestion = fullfile(p, self.settingsFile);
                else
                    suggestion = fullfile(pwd, '*');
                end
                
                [f, p] = uigetfile( ...
                    {'*.xml'}, ...
                    'Load dots settings from which .xml file?', ...
                    suggestion, ...
                    'MultiSelect', 'off');
                
                if ischar(f)
                    fileWithPath = fullfile(p, f);
                else
                    return;
                end
            end
            self.settingsFromXmlFile(fileWithPath)
        end
        
        % Write an .xml file that contains the current settings.
        % @param fileWithPath the file name, which may contain a path,
        % where to write xml data.
        % @details
        % If @a fileWithPath is missing, opens a dialog for chosing a
        % suitable file.
        function writeUserSettingsFile(fileWithPath)
            self = dotsTheMachineConfiguration.theObject();
            
            if nargin < 1 || isempty(fileWithPath) || ~ischar(fileWithPath)
                if exist(self.settingsFile, 'file')
                    [p,f,e] = fileparts(which(self.settingsFile));
                    if isempty(p)
                        p = pwd;
                    end
                    suggestion = fullfile(p, self.settingsFile);
                else
                    hf = self.getHostFilename;
                    suggestion = fullfile(pwd, hf);
                end
                
                [f, p] = uiputfile( ...
                    {'*.xml'}, ...
                    'Save dots settings to which .xml file?', ...
                    suggestion);
                
                if ischar(f)
                    fileWithPath = fullfile(p, f);
                else
                    return;
                end
            end
            self.settingsToXmlFile(fileWithPath)
        end
    end
end