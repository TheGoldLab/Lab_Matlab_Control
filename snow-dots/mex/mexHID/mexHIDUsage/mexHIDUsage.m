classdef mexHIDUsage < handle
    % @class mexHIDUsage
    % Look up names and values for working with Human Interface Devices.
    % @details
    % HID is a general-purpose specification for how to communicate with
    % Himan Interface Devices.  Part of the HID specification provides
    % numeric "usage" and "type" values that devices can report about
    % themselves to an operating system or program (like Matlab and
    % mexHID()).  These values are not obvious, for example 2 might mean
    % "Input_Button" or "Simulation", and 6 might mean "Keyboard".
    % @details
    % mexHIDUsage() attempts to make these meanings clearer.  It provides
    % static methods that map the numeric usage values to human-readable
    % string names.  There are a few different types of mapping:
    %   - nameForPageNumber() and numberForPageName() address usage
    %   "pages".  A usage page is group of related usage values.
    %   "Generic_Desktop" and "Simulation" are examples of usage page
    %   names.
    %   - nameForUsageNumberOnPage() and numberForUsageNameOnPage() address
    %   individual usage values, within the scope of a single usage page.
    %   "Joystick" and "KeyboardLeftShift" are examples of individual
    %   usages from different pages.
    %   - nameForElementTypeNumber() and numberForElementTypeName() address
    %   type values (which are different from usage values) that describe
    %   parts of a device.  "Input_Button" and "Output" are examples of
    %   element types.
    %   .
    % @details
    % The mexHIDUsage.gui() method opens a figure which summarizes all of
    % the HID usage pages and individual usages by name and number.
    % @details
    % The mexHID() function, which actually interacts with HID devices
    % requires numeric usage, page, and type values inorder to do things
    % like find a device or device elements suitable for a given task.
    % mexHIDUsage should make finding the correct values less mysterious.
    % @details
    % During development, I (Ben Heasly) used the HID Usages contained in
    % IOHIDUsageTables.h, which is part of the OS X UIKit framework, to
    % build lookuptables.  I also copied by hand the element type enum from
    % IOHIDKeys.h.  Users should not need to worry about this, since they
    % can use the tables saved for Matlab in the mexHIDUsageMat file.
    
    properties (SetAccess = protected)
        % containers.Map of HID usage page number -> name
        pageNumberToName;
        
        % containers.Map of HID usage page name -> number
        pageNameToNumber;
        
        % Many containers.Map of HID usage number -> name, one for each
        % usage page.  Contained in a containers.Map with page number keys.
        usageNumbersToNames;
        
        % Many containers.Map of HID usage name -> number, one for each
        % usage page.  Contained in a containers.Map with page number keys.
        usageNamesToNumbers;
        
        % containers.Map of HID element type name -> number
        elementTypeNameToNumber;
        
        % containers.Map of HID element type number -> name
        elementTypeNumberToName;
        
        % Filename with path to .mat file containing mexHIDUsage data.
        mexHIDUsageMat = 'mexHIDUsage.mat';
        
        % Regular expression to get a page declaration out of the topmost
        % enum.  The tokens are:
        %   - the page name
        %   - the page number in hex
        %   .
        pageEnum = 'kHIDPage_(\w+)\s=\s0x(\w+)';
        
        % Regular expression to get the enum for a particular usage page.
        % The token is:
        %   - the page number in hex
        %   .
        pageUsageEnumFinder = 'Page\s\(0x(\w+)\)\s\*\/';
        
        % Regular expression to get a usage declaration out of an enum.
        % The tokens are:
        %   - Apple's abbreviated usage page name
        %   - the usage name
        %   - the usage number in hex
        %   .
        usageEnum = 'kHIDUsage_([a-zA-Z]+)_(\w+)\s=\s0x(\w+)';
        
        % Regular expression to get a usage declaration out of an enum when
        % there is no Apple abbreviation.  The tokens are:
        %   - the usage name
        %   - the usage number in hex
        %   .
        usageEnumNoAbr = 'kHIDUsage_(\w+)\s=\s0x(\w+)';
    end
    
    methods (Access = private)
        % Constructor is private.
        % @details
        % Use mexHIDUsage.theObject to access the current instance.
        function self = mexHIDUsage()
            self.initialize();
        end
    end
    
    methods (Static)
        % Access the current instance.
        function obj = theObject()
            persistent self
            if isempty(self) || ~isvalid(self)
                constructor = str2func(mfilename);
                self = feval(constructor);
            end
            obj = self;
        end
        
        % Reload page, usage, and type data.
        function reset()
            self = mexHIDUsage.theObject();
            self.initialize();
        end
        
        % Open a figure which summarizes usages and pages by name and
        % number.
        function fig = gui()
            self = mexHIDUsage.theObject();
            
            % dump everything into a uitable
            data = cell(0,4);
            pageNumbers = self.allPageNumbers;
            row = 1;
            for ii = 1:length(pageNumbers)
                % a header for the usage page
                pageNum = pageNumbers{ii};
                pageName = mexHIDUsage.nameForPageNumber(pageNum);
                data(row, 1:2) = {pageNum, pageName};
                
                % a bunch of usages on the page
                usages = self.usageNumbersToNames(pageNum);
                nUsages = usages.length;
                data(row+(1:nUsages),3) = usages.keys;
                data(row+(1:nUsages),4) = usages.values;
                
                row = row + nUsages + 1;
            end
            
            fig = figure;
            uitable('Parent', fig, ...
                'Units', 'normalized', ...
                'Position', [.05 .05 .9 .9], ...
                'ColumnEditable', false, ...
                'ColumnWidth', {50 150 50 200}, ...
                'ColumnName', {'', 'UsagePage', '', 'Usage'}, ...
                'RowName', [], ...
                'Data', data);
        end
        
        % Get a readable name for a usage page.
        function pageName = nameForPageNumber(pageNum)
            self = mexHIDUsage.theObject;
            pageName = '';
            if self.pageNumberToName.isKey(pageNum)
                pageName = self.pageNumberToName(pageNum);
            end
        end
        
        % Summarize the possible usage page names.
        function pageNames = allPageNames
            self = mexHIDUsage.theObject;
            pageNames = self.pageNameToNumber.keys;
        end
        
        % Get the number of a named usage page.
        function pageNum = numberForPageName(pageName)
            self = mexHIDUsage.theObject;
            pageNum = [];
            if self.pageNameToNumber.isKey(pageName)
                pageNum = self.pageNameToNumber(pageName);
            end
        end
        
        % Summarize the possible usage page numbers.
        function pageNumbers = allPageNumbers
            self = mexHIDUsage.theObject;
            pageNumbers = self.pageNumberToName.keys;
        end
        
        % Get a readable name for an individual usage on a usage page.
        function usageName = nameForUsageNumberOnPage(usageNum, pageNum)
            self = mexHIDUsage.theObject;
            usageName = '';
            if self.usageNumbersToNames.isKey(pageNum)
                numToName = self.usageNumbersToNames(pageNum);
                if numToName.isKey(usageNum)
                    usageName = numToName(usageNum);
                end
            end
        end
        
        % Summarize the possible usage names on a usage page.
        function usageNames = allUsageNamesOnPage(pageNum)
            self = mexHIDUsage.theObject;
            usageNames = {};
            if self.usageNamesToNumbers.isKey(pageNum)
                nameToNum = self.usageNamesToNumbers(pageNum);
                usageNames = nameToNum.keys;
            end
        end
        
        % Get the number for a named usage, on a usage page.
        function usageNum = numberForUsageNameOnPage(usageName, pageNum)
            self = mexHIDUsage.theObject;
            usageNum = [];
            if self.usageNamesToNumbers.isKey(pageNum)
                nameToNum = self.usageNamesToNumbers(pageNum);
                if nameToNum.isKey(usageName)
                    usageNum = nameToNum(usageName);
                end
            end
        end
        
        % Summarize the possible usage numbers on a usage page.
        function usageNums = allUsageNumbersOnPage(pageNum)
            self = mexHIDUsage.theObject;
            usageNums = {};
            if self.usageNumbersToNames.isKey(pageNum)
                numToName = self.usageNumbersToNames(pageNum);
                usageNums = numToName.keys;
            end
        end
        
        % Get a readable name for an element type number.
        function typeName = nameForElementTypeNumber(typeNum)
            self = mexHIDUsage.theObject;
            typeName = '';
            if self.elementTypeNumberToName.isKey(typeNum)
                typeName = self.elementTypeNumberToName(typeNum);
            end
        end
        
        % Summarize the possible element type names.
        function typeNames = allElementTypeNames
            self = mexHIDUsage.theObject;
            typeNames = self.elementTypeNameToNumber.keys;
        end
        
        % Get the number for the named element type.
        function typeNum = numberForElementTypeName(typeName)
            self = mexHIDUsage.theObject;
            typeNum = [];
            if self.elementTypeNameToNumber.isKey(typeName)
                typeNum = self.elementTypeNameToNumber(typeName);
            end
        end
        
        % Summarize the possible element type numbers.
        function typeNums = allElementTypeNumbers
            self = mexHIDUsage.theObject;
            typeNums = self.elementTypeNumberToName.keys;
        end
    end
    
    methods
        % Reload page, usage, and type data.
        function initialize(self)
            tables = load(self.mexHIDUsageMat);
            self.pageNumberToName = tables.pageNumberToName;
            self.pageNameToNumber = tables.pageNameToNumber;
            self.usageNumbersToNames = tables.usageNumbersToNames;
            self.usageNamesToNumbers = tables.usageNamesToNumbers;
            
            self.buildElementTypeTables;
        end
        
        % Reload hard-coded element type names and numbers.
        function buildElementTypeTables(self)
            % copied by hand from IOHIDKeys.h
            elementTypeEnum = { ...
                'Input_Misc', 1; ...
                'Input_Button', 2; ...
                'Input_Axis', 3; ...
                'Input_ScanCodes', 4; ...
                'Input_LessThan', 5; ...
                'Output', 129; ...
                'Feature', 257; ...
                'Collection', 513};
            self.elementTypeNameToNumber = containers.Map( ...
                elementTypeEnum(:,1), elementTypeEnum(:,2), 'uniformValues', true);
            self.elementTypeNumberToName = containers.Map( ...
                elementTypeEnum(:,2), elementTypeEnum(:,1), 'uniformValues', true);
        end
        
        % Rescan OS X UIKit headers for page and usage names and numbers.
        function buildUsageTables(self, IOHIDUsageHeader)
            tables.pageNumberToName = containers.Map(-1, 'a', 'uniformValues', true);
            tables.pageNumberToName.remove(-1);
            
            tables.pageNameToNumber = containers.Map('a', -1, 'uniformValues', true);
            tables.pageNameToNumber.remove('a');
            
            tables.usageNumbersToNames = containers.Map(-1, 'a', 'uniformValues', false);
            tables.usageNumbersToNames.remove(-1);
            
            tables.usageNamesToNumbers = containers.Map(-1, 'a', 'uniformValues', false);
            tables.usageNamesToNumbers.remove(-1);
            
            fid = fopen(IOHIDUsageHeader, 'r');
            try
                currentPage = -1;
                while true
                    line = fgetl(fid);
                    if ~ischar(line)
                        break
                    end
                    
                    % find a usage page declaration
                    tokens = regexp(line, self.pageEnum, 'tokens');
                    if ~isempty(tokens)
                        pageName = tokens{1}{1};
                        pageNum = hex2dec(tokens{1}{2});
                        disp(sprintf('Page %d: %s', pageNum, pageName))
                        
                        % cross reference the page name and number
                        tables.pageNumberToName(pageNum) = pageName;
                        tables.pageNameToNumber(pageName) = pageNum;
                        
                        % new Maps for usages on this page
                        numToName = containers.Map(-1, 'a', 'uniformValues', true);
                        numToName.remove(-1);
                        tables.usageNumbersToNames(pageNum) = numToName;
                        
                        nameToNum = containers.Map('a', -1, 'uniformValues', true);
                        nameToNum.remove('a');
                        tables.usageNamesToNumbers(pageNum) = nameToNum;
                        continue
                    end
                    
                    % find an enum of usages for a page
                    tokens = regexp(line, self.pageUsageEnumFinder, 'tokens');
                    if ~isempty(tokens)
                        % set the page to be filled with usages, below
                        currentPage = hex2dec(tokens{1}{1});
                        disp(sprintf('Page %d:', currentPage))
                        continue
                    end
                    
                    % find a usage declaration
                    tokens = regexp(line, self.usageEnum, 'tokens');
                    if ~isempty(tokens)
                        usageAbr = tokens{1}{1};
                        usageName = tokens{1}{2};
                        usageNum = hex2dec(tokens{1}{3});
                        disp(sprintf(' Usage %d: %s (%s)', usageNum, usageName, usageAbr))
                        
                        % cross reference the usage name and number
                        %   for the current page, found above
                        if tables.usageNumbersToNames.isKey(currentPage)
                            numToName = tables.usageNumbersToNames(currentPage);
                            numToName(usageNum) = usageName;
                            
                            nameToNum = tables.usageNamesToNumbers(currentPage);
                            nameToNum(usageName) = usageNum;
                        end
                        continue
                    end
                    
                    % find a usage declaration
                    tokens = regexp(line, self.usageEnumNoAbr, 'tokens');
                    if ~isempty(tokens)
                        tokens{1}{:}
                        usageName = tokens{1}{1};
                        usageNum = hex2dec(tokens{1}{2});
                        disp(sprintf(' Usage %d: %s', usageNum, usageName))
                        
                        % cross reference the usage name and number
                        %   for the current page, found above
                        if tables.usageNumbersToNames.isKey(currentPage)
                            numToName = tables.usageNumbersToNames(currentPage);
                            numToName(usageNum) = usageName;
                            
                            nameToNum = tables.usageNamesToNumbers(currentPage);
                            nameToNum(usageName) = usageNum;
                        end
                        continue
                    end
                    
                    
                end
            catch erxor
                fclose(fid);
                rethrow(erxor)
            end
            
            fclose(fid);
            save(self.mexHIDUsageMat, '-struct', 'tables');
            self.initialize;
        end
    end
end