classdef (Sealed) topsDataLog < topsGroupedList
    % @class topsDataLog
    % One central place to log data on the fly.
    % topsDataLog makes it easy to log data as you go.  It's a "singleton"
    % class, which means that only one can exist at a time, and you never
    % have to create one yourself.  You just call topsDataLog methods from
    % any code that needs to use the log.
    % @details
    % topsDataLog is a subclass of topsGroupedList, which means it
    % has all the organization and capabilities of topsGroupedList, plus
    % more.
    % @details
    % Thus, you must log each piece of data in a "group" of related
    % data.  The group might correspond to a recuurring event, such as
    % 'trial start'. You don't have to supply a "mnemonic" for each piece
    % of data because topsDataLog uses timestamps to identify pieces of
    % data in each group.
    % @details
    % In your experiment code, you can add to the log as many times as you
    % like.  If you're not sure whether some piece of data will turn out to
    % be important, you can go ahead and log it anyway.  You don't have to
    % worry about the log filling up, how to allcate space for more data,
    % or even how the data are ultimately stored.  That's the log's job.
    % @details
    % Other topsFoundataion classes will also add data to the log, to help
    % you keep track of details that aren't specific to your experiment.
    % For example, topsRunnable objects make log entries as they start and
    % finish running.
    % @details
    % With your log entries and the entries made automatically by
    % topsFoundataion classes, it should be straightforward to look at the
    % log after an experiment and get a sense of what happened and when.
    % The log's gui() method should make this even easier.  You can use it
    % to launch topsDataLogGUI, which plots a raster of all logged data
    % over time, with data groups as rows.
    
    properties
        % any function that returns the current time as a number
        clockFunction = @topsClock;
        
        % true or false, whether to print info as data are logged
        printLogging = false;
        
        % string name of a file to read from and write to, which may
        % include the file path
        fileWithPath = '';
    end
    
    properties (SetAccess = protected)
        % the time of the first logged data, as reported by clockFunction
        earliestTime;
        
        % the time of the last logged data, as reported by clockFunction
        latestTime;
        
        % the most recent time when the log was flushed
        % @details
        % flushAllData() sets lastFlushTime to the current time, as
        % reported by clockFunction.
        lastFlushTime;
        
        % topsDataFile metadata struct for writing to disk incrementally
        fHeader;
        
        % time of the most recent writeIncrementToFile()
        lastWriteTime;
        
        % time of the most recent getNewData()
        lastNewDataTime;
    end
    
    methods (Access = private)
        % Constructor is private.
        % @details
        % Use topsDataLog.theDataLog to access the current instance of
        % topsDataLog.
        function self = topsDataLog()
            self.earliestTime = nan;
            self.latestTime = nan;
            self.lastFlushTime = nan;
            self.lastWriteTime = -inf;
            self.lastNewDataTime = -inf;
            self.name = 'The Data Log';
            
            % choose data file name, trigger the set.fileWithPath method
            self.fileWithPath = 'topsDataLog.mat';
        end
    end
    
    methods (Access = protected)
        % Write a data increment and other data to file and do accounting.
        function writeIncrementToFile(self)
            if isempty(self.fHeader)
                disp(sprintf('%s: no topsDataFile header!'))
                return;
            end
            
            % no new data to write
            if self.lastWriteTime >= self.latestTime;
                return;
            end
            
            % get new data
            newRange = [self.lastWriteTime, inf];
            newData = topsDataLog.getSortedDataStruct(newRange);
            
            % do header accounting for new data
            if isfinite(self.latestTime)
                self.lastWriteTime = self.latestTime;
            end
            self.fHeader.userData.clockFunction = self.clockFunction;
            self.fHeader.userData.earliestTime = self.earliestTime;
            self.fHeader.userData.latestTime = self.latestTime;
            self.fHeader.userData.lastFlushTime = self.lastFlushTime;
            self.fHeader.userData.lastWriteTime = self.lastWriteTime;
            
            % write new data to disk
            if isempty(newData)
                self.fHeader = topsDataFile.write(self.fHeader);
            else
                self.fHeader = topsDataFile.write(self.fHeader, newData);
            end
            disp(sprintf('%s: wrote %s', mfilename, self.fileWithPath))
        end
        
        % Read a data increment and other data from file.
        function dataStruct = readIncrementFromFile(self)
            if isempty(self.fHeader)
                disp(sprintf('%s: no topsDataFile header!'))
                return;
            end
            
            [self.fHeader, newData] = topsDataFile.read(self.fHeader);
            if isempty(newData)
                dataStruct = struct([]);
            else
                dataStruct = cat(2, newData{:});
                self.populateWithDataStruct(dataStruct);
            end
            
            self.clockFunction = self.fHeader.userData.clockFunction;
            self.earliestTime = self.fHeader.userData.earliestTime;
            self.latestTime = self.fHeader.userData.latestTime;
            self.lastFlushTime = self.fHeader.userData.lastFlushTime;
            self.lastWriteTime = self.fHeader.userData.lastWriteTime;
            
            disp(sprintf('%s: read %s', mfilename, self.fileWithPath))
        end
        
        % Read an old-style data from file.
        function dataStruct = readOldLogStructFromFile(self)
            data = load(self.fileWithPath);
            if isstruct(data) && isfield(data, 'logStruct');
                topsDataLog.flushAllData;
                self.populateWithDataStruct(data.logStruct);
                self.clockFunction = data.clockFunction;
                self.earliestTime = data.earliestTime;
                self.latestTime = data.latestTime;
                
                disp(sprintf('%s: read %s', mfilename, self.fileWithPath))
            end
        end
        
        % Populate the log groupedList with struct data.
        function populateWithDataStruct(self, dataStruct)
            for ii = 1:numel(dataStruct)
                self.addItemToGroupWithMnemonic( ...
                    dataStruct(ii).item, ...
                    dataStruct(ii).group, ...
                    dataStruct(ii).mnemonic);
            end
        end
    end
    
    methods
        % Update the topsDataFile metadata to reflect a new fileWithPath.
        function set.fileWithPath(self, fileWithPath)
            if ~strcmp(fileWithPath, self.fileWithPath)
                self.fHeader = topsDataFile.newHeader( ...
                    'fileWithPath', fileWithPath);
                self.lastWriteTime = -inf;
            end
            self.fileWithPath = fileWithPath;
        end
    end
    
    methods (Static)
        % Access the current data log "singleton"
        % @details
        % Returns the current instance of topsDataLog.  Use this method
        % instad of a class constructor.  This method will create a new
        % data log the first time it's called, and return the same data log
        % subsequently.
        % @details
        % For most log operations, you don't need this method.  You can
        % just use the static methods below and they will access the
        % current data log for you.
        % @details
        % For a few operations it makes sense to get at the log itself,
        % using this method.  For example, you might wish to change the
        % log's clockFunction, to use some custom timer.  In that case you would
        % get the log using this method, and set the value of log.clockFunction
        % just like you would set the value of any object property.
        function log = theDataLog()
            persistent theLog
            if isempty(theLog) || ~isvalid(theLog)
                theLog = topsDataLog;
            end
            log = theLog;
        end
        
        % Open a GUI to view object details.
        % @details
        % Opens a new GUI with components suitable for viewing objects of
        % this class.  Returns a topsFigure object which contains the GUI.
        function fig = gui()
            self = topsDataLog.theDataLog();
            fig = topsFigure(self.name);
            logPan = topsDataLogPanel(fig);
            infoPan = topsInfoPanel(fig);
            fig.usePanels({infoPan; logPan}, [2 8]);
        end
        
        % Toggle verbose printouts for data logging.
        % @param isVerbose whether to print as data are logged
        % @details
        % If @a isVerbose is true, topsDataLog will print a message to the
        % Command Window whenever data is added to the log.  If @a
        % isVerbose is false or omitted, topsDataLog will print nothing.
        function setVerbose(isVerbose)
            if nargin < 1
                isVerbose = false;
            end
            self = topsDataLog.theDataLog();
            self.printLogging = isVerbose;
        end
        
        % Clear out all data from the log.
        % @details
        % You can't create new instances of topsDataLog, but you can
        % always clear out the existing instance.  You probably should do
        % this before starting an experiment.
        % @details
        % Removes all data from all groups, then removes the groups
        % themselves.  Sets earliestTime and latestTime to nan.
        function flushAllData()
            self = topsDataLog.theDataLog();
            for g = self.groups
                self.removeGroup(g{1});
            end
            self.earliestTime = nan;
            self.latestTime = nan;
            self.lastFlushTime = feval(self.clockFunction);
            self.lastNewDataTime = -inf;
        end
        
        % Add some data to the log.
        % @param data a value or object to store in the log (but not an
        % object of the handle type).
        % @param group a string for grouping related data, such as the name
        % of a recurring event.
        % @param timestamp optional time marker to use for @a data, instead
        % of the current time.
        % @details
        % If @a data is a handle object, converts it to a struct.  This is
        % because Matlab does a bad job of dealing with large numbers of
        % handles to the same object, and a worse job of writing and
        % reading them to disk.  Better to keep the data log out of that
        % mess.
        % @details
        % Adds @a data to @a group, under the given @a timestamp, in the
        % current instance of topsDataLog.  If @a timestamp is omitted,
        % uses the current time reported by clockFunction.
        % @details
        % Updates earliestTime and latestTime to account for the the time
        % of this log entry.
        % @details
        % Since topsDataLog is a subclass of topsGroupedList, logging data
        % is a lot like adding items to a list. @a group is treated just
        % like the groups in topsGroupedList.  The data log uses a
        % @a timestamp as the mnemonic for each data item.
        function logDataInGroup(data, group, timestamp)
            self = topsDataLog.theDataLog();
            
            if nargin < 3 || isempty(timestamp) || ~isnumeric(timestamp)
                timestamp = feval(self.clockFunction);
            end
            
            if isa(data, 'handle')
                warning('%s converting handle object %s to struct', ...
                    mfilename, class(data));
                data = struct(data);
            end
            self.addItemToGroupWithMnemonic(data, group, timestamp);
            
            if self.printLogging
                disp(sprintf('topsDataLog: %s', group))
            end
            
            self.earliestTime = min(self.earliestTime, timestamp);
            self.latestTime = max(self.latestTime, timestamp);
        end
        
        % Get all data from the log.
        % @param timeRange optional time limits for data, of the form
        % [laterThan asLateAs]
        % @details
        % Gets all data items from the current instance of topsDataLog, as
        % a struct array, using getAllItemsFromGroupAsStruct().  Sorts the
        % struct array by the time values stored in its mnemonics field.
        function logStruct = getSortedDataStruct(timeRange)
            self = topsDataLog.theDataLog();
            if nargin < 1
                timeRange = [-inf inf];
            end
            
            % grow a struct array, group by group
            logStruct = self.getAllItemsFromGroupAsStruct('');
            for g = self.groups
                groupStruct = self.getAllItemsFromGroupAsStruct(g{1});
                if ~isempty(groupStruct)
                    groupTimes = [groupStruct.mnemonic];
                    isInRange = groupTimes > timeRange(1) ...
                        & groupTimes <= timeRange(2);
                    if any(isInRange)
                        logStruct = ...
                            cat(2, logStruct, groupStruct(isInRange));
                    end
                end
            end
            
            % sorting from scratch may be too slow
            %   may be able to improve since keys
            %   from each group should be already sorted--merge k lists
            [a, order] = sort([logStruct.mnemonic]);
            logStruct = logStruct(order);
        end
        
        % Get new data, recently added to the log.
        % @details
        % Gets recent data items from the current instance of topsDataLog,
        % as a struct array.  "Recent" means data added to the log since
        % the last time getNewData() was called.  Updates lastNewDataTime
        % with the current time.
        function logStruct = getNewData()
            self = topsDataLog.theDataLog();
            
            if self.lastNewDataTime < self.latestTime;
                % get new data
                newRange = [self.lastNewDataTime, inf];
                logStruct = topsDataLog.getSortedDataStruct(newRange);
                self.lastNewDataTime = self.latestTime;
                
            else
                % no new data to get
                logStruct = [];
                return;
            end
        end
        
        % Log data from a data struct, if it's new.
        % @param dataStruct struct data, as from getSortedDataStruct()
        % @details
        % Adds adds data from the given @a dataStruct to the data log, but
        % only if the new data are newer than lastNewDataTime.  Returns a
        % logical selector with the same size as @a dataStruct, which is
        % true where items were found to be new and added to the log.
        function isNew = logNewData(logStruct)
            self = topsDataLog.theDataLog();
            
            % which items are new?
            isNew = [logStruct.mnemonic] > self.lastNewDataTime;
            
            % log the new items, if any
            self.populateWithDataStruct(logStruct(isNew));
        end
        
        % Write logged data to a file.
        % @param fileWithPath optional .mat filename, which may include a
        % path, in which to save logged data.
        % @details
        % Converts recently logged data to a standard Matlab struct using
        % topsDataLog.getSortedDataStruct() and writes the struct to disk,
        % via the topsDataFile class.
        % @details
        % writeDataFile() behaves differently depending on @a fileWithPath
        % and the fileWithPath property of the current topsDataLog
        % instance:
        %   - If @a fileWithPath is provided, assigns @a fileWithPath to
        %   the fileWithPath property of the current topsDataLog instance
        %   and writes data to the given @a fileWithPath.
        %   - If @a fileWithPath is omitted, but the current topsDataLog
        %   instance has a non-empty fileWithPath property, writes data
        %   according to the fileWithPath property.
        %   - If @a fileWithPath is omitted, and the current topsDataLog
        %   instance has an empty fileWithPath property, opens a dialog for
        %   chosing a a file.  If a file is chosen, writes data to the
        %   chosen file and saves the chosen file to the fileWithPath
        %   property.
        %   .
        function writeDataFile(fileWithPath)
            self = topsDataLog.theDataLog();
            
            if nargin > 0 && ~isempty(fileWithPath) && ischar(fileWithPath)
                self.fileWithPath = fileWithPath;
                
            elseif isempty(self.fileWithPath)
                suggestion = fullfile(pwd, '*');
                [f, p] = uiputfile( ...
                    {'*.mat'}, ...
                    'Save data log to which .mat file?', ...
                    suggestion);
                if ischar(f)
                    self.fileWithPath = fullfile(p, f);
                end
            end
            
            if ~isempty(self.fileWithPath)
                self.writeIncrementToFile();
            end
        end
        
        
        % Read previously logged data from a file.
        % @param fileWithPath optional .mat filename, which may include a
        % path, from which to read logged data.
        % @details
        % Reads any previously unread data from disk, via the topsDataFile
        % class.  Populates the current instance of topsDataLog with any
        % new data.  May also return the new data, in a struct of the same
        % form as topsDataLog.getSortedDataStruct().
        % @details
        % readDataFile() behaves differently depending on @a fileWithPath
        % and the fileWithPath property of the current topsDataLog
        % instance:
        %   - If @a fileWithPath is provided, assigns @a fileWithPath to
        %   the fileWithPath property of the current topsDataLog instance
        %   and reads data from the given @a fileWithPath.
        %   - If @a fileWithPath is omitted, but the current topsDataLog
        %   instance has a non-empty fileWithPath property, reads data
        %   according to the fileWithPath property.
        %   - If @a fileWithPath is omitted, and the current topsDataLog
        %   instance has an empty fileWithPath property, opens a dialog for
        %   chosing a a file.  If a file is chosen, reads data from the
        %   chosen file and saves the chosen file to the fileWithPath
        %   property.
        %   .
        function dataStruct = readDataFile(fileWithPath)
            self = topsDataLog.theDataLog();
            dataStruct = struct([]);
            
            if nargin > 0 && ~isempty(fileWithPath) && ischar(fileWithPath)
                self.fileWithPath = fileWithPath;
                
            elseif isempty(self.fileWithPath)
                suggestion = fullfile(pwd, '*');
                [f, p] = uigetfile( ...
                    {'*.mat'}, ...
                    'Load data log from which .mat file?', ...
                    suggestion, ...
                    'MultiSelect', 'off');
                if ischar(f)
                    self.fileWithPath = fullfile(p, f);
                end
            end
            
            if ~isempty(self.fileWithPath)
                % check for old-style of data file
                %   from before topsDataFile and incremental writing
                vars = who('-file', self.fileWithPath);
                if any(strcmp(vars, 'logStruct'))
                    dataStruct = self.readOldLogStructFromFile();
                else
                    dataStruct = self.readIncrementFromFile();
                end
            end
        end
    end
end
