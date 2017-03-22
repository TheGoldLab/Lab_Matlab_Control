classdef topsDataFile
    % @class topsDataFile
    % Utility to organize incremental reading and writing of data.
    % @details
    % topsDataFile facilitates writing data to a single file,
    % incrementally, over time.  It keeps track of data increments
    % themeselves as well as metadata related to which increments have
    % already been written.  It also facilitates reading incremental data
    % and keeps track of which increments have already been read out.
    % @details
    % topsDataFile is suitable for sharing data (such as topsDataLog data)
    % between separate instance of Matlab running on the same machine.
    % Each Matlab instance should be able to write data increments and read
    % in increments that were written by the other.  topsDataFile attempts
    % to prevent data corruption due to poorly timed access by saving data
    % and metadata separately, and using metadata to coordinate file
    % access.
    % @deatils
    % Note that topsDataFile objects are not handle objects, and
    % topsDataFile objects themselves are not returned directly.  Instead,
    % the newHeader() methods returns a struct with fields that
    % match the properties of the topsDataFile class, and other
    % topsDataFile methods expect to work with these "header" structs.
    % This pattern faciliitates writing and reading of header meta data to
    % file.  It also makes explicit the idea that topsDataFile objects
    % represent data on the hard disk, and should not themselves contain
    % much data or maintain much internal state.
    
    properties
        % string name of the file to read from and write to, which may
        % include the file path
        fileWithPath = 'topsDataFileData.mat';
        
        % string prefix to use for identifying data increments
        incrementPrefix = 'topsDataFileIncrement';
        
        % function handle for getting the current date-and-time as a number
        dateTimeFunction = @now;
        
        % format string to use with Matlab's builtin datestr()
        datestrFormat = 'yyyymmddTHHMMSSPFFF';
        
        % array of date-and-time numbers for previously written data
        % increments
        writtenIncrements = [];
        
        % array of date-and-time numbers for previously read data
        % increments
        readIncrements = [];
        
        % any external data to be stored with the header metadata
        userData = [];
    end
    
    methods (Access = private)
        function fObj = topsDataFile()
        end
        
        % Convert a topsDataFile object to an equivalent struct.
        function fHeader = toStruct(fObj)
            warning('off', 'MATLAB:structOnObject');
            fHeader = struct(fObj);
        end
    end
    
    methods (Static)
        % Create a header struct with fields that match the properties of
        % the topsDataFile class.
        % @param varargin optional property-value pairs to assign to the
        % new header.
        % @details
        % Use this method instead of the topsDataFile constructor.
        % @details
        % Returns a header struct with fields and default values that match
        % those of the topsDataFile class.  @a varargin may contain pairs
        % of property names and values to be assigned to the new struct.
        function fHeader = newHeader(varargin)
            fObj = topsDataFile();
            for ii = 1:2:length(varargin)
                fObj.(varargin{ii}) = varargin{ii+1};
            end
            fHeader = fObj.toStruct;
        end
        
        % Read any new data increments from a topsDataFile.
        % @param fHeader a topsDataFile header struct as returned from
        % newHeader().
        % @param increments optional array of date-and-time numbers
        % identifying data increments to read or re-read from the
        % topsDataFile
        % @details
        % Uses @a fHeader to locate a topsDataFile on disk.  If the file
        % exists and contains topsDataFile header metadata, loads the
        % metadata from disk and updates @a fHeader to match.  Returns the
        % updated @a fHeader
        % @details
        % Also returns a cell array containing any data increments that
        % have not yet been read from disk.  These increments correspond to
        % values in @a fHeader.writtenIncrements that are not yet present
        % in @a fHeader.readIncrements.
        % @details
        % If @a increments is provided, attempts to read or re-read the
        % specified data increments from the topsDataFile.  Returns a cell
        % array with the same size as @a increments.  Where the specified
        % @a increments are not present in the topsDataFile, the returned
        % cell array will be empty.  Using read() in this way will not
        % affect @a fHeader.readIncrements, or subsequent calls to read().
        function [fHeader, incrementCell] = read(fHeader, increments)
            incrementCell = {};
            if exist(fHeader.fileWithPath)
                contents = who('-file', fHeader.fileWithPath);
                if any(strcmp(contents, 'fHeader'))
                    s = load(fHeader.fileWithPath, 'fHeader');
                    % match most of the metadata from the disk
                    fHeader.incrementPrefix = s.fHeader.incrementPrefix;
                    fHeader.dateTimeFunction = s.fHeader.dateTimeFunction;
                    fHeader.datestrFormat = s.fHeader.datestrFormat;
                    fHeader.writtenIncrements = s.fHeader.writtenIncrements;
                    fHeader.userData = s.fHeader.userData;
                    
                    if nargin < 2
                        % choose increments that were written
                        %   but not yet read
                        increments = setdiff( ...
                            fHeader.writtenIncrements, ...
                            fHeader.readIncrements);
                        
                        % now all increments will have been read
                        fHeader.readIncrements = ...
                            fHeader.writtenIncrements;
                    end
                    
                    % actually read increments from the file
                    nIncrements = numel(increments);
                    incrementNames = ...
                        topsDataFile.incrementNamesFromNumbers( ...
                        fHeader, increments);
                    incrementCell = cell(1,nIncrements);
                    for ii = 1:nIncrements
                        name = incrementNames(ii,:);
                        if any(strcmp(contents, name))
                            s = load(fHeader.fileWithPath, name);
                            incrementCell{ii} = s.(name);
                        end
                    end
                    
                else
                    warning('%s: "%s" has no topsDataFile metadata', ...
                        mfilename, fHeader.fileWithPath);
                end
            else
                warning('%s: "%s" does not exist()', ...
                    mfilename, fHeader.fileWithPath);
            end
        end
        
        % Write a new data increment to a topsDataFile.
        % @param fHeader a topsDataFile header struct as returned from
        % newHeader().
        % @param newIncrement any data increment to append to the
        % topsDataFile
        % @details
        % If @a newIncrement is provided, appends the @a newIncrement to
        % the topsDataFile on disk, then updates the hjeader metadata on
        % disk.
        % If a@ newIncrement is omitted, only writes header metadata
        % to disk.  If the topsDataFile doesn't already exist on disk,
        % creates the new file first.
        % @details
        % Since write() updates header metadata only after writing the new
        % increment data, concurrent read() calls, such as from a separate
        % Matlab instance, should be able to safely ignore increment data
        % that's in the process of being written.
        % @details
        % Returns @a fHeader, which may have been modified with new
        % metadata.
        function fHeader = write(fHeader, newIncrement)
            fid = fopen(fHeader.fileWithPath, 'r');
            if fid < 0
                % create the file
                save(fHeader.fileWithPath, 'fHeader');
            else
                fclose(fid);
            end
            
            if nargin > 1
                % new data increment to append
                incrementTime = feval(fHeader.dateTimeFunction);
                incrementName = topsDataFile.incrementNamesFromNumbers( ...
                    fHeader, incrementTime);
                s = struct(incrementName, {newIncrement});
                save(fHeader.fileWithPath, incrementName, '-append', ...
                    '-struct', 's', incrementName);
                fHeader.writtenIncrements(end+1) = incrementTime;
            end
            
            % update header data only after the increments were written
            %   let concurrent read() calls ignore increments as they are
            %   being written
            save(fHeader.fileWithPath, 'fHeader', '-append');
        end
        
        % Get data increment names from date-and-time numbers.
        function names = incrementNamesFromNumbers(fHeader, numbers)
            n = numel(numbers);
            dateStrings = datestr(numbers, fHeader.datestrFormat);
            prefixes = repmat(fHeader.incrementPrefix, n, 1);
            names = cat(2, prefixes, dateStrings);
        end
    end
end