classdef dotsDataLogUtilities
    % @class dotsDataLogUtilities
    % Static utility methods for topsDataLog and multiple Matlab instances.
    % @details
    % dotsDataLogUtilities provides static methods for working
    % synchronizing topsDataLog across multiple Matlab instances.  The
    % methods expect ensemble objects, which can be connected to any remote
    % Matlab instances.  They facilitate sending data from from the local
    % Matlab instance to remote Matlab instances, and for writing log data
    % to disk in a remote Matlab instance.
    %
    % @ingroup dotsUtilities
    
    methods (Static)
        % Send new topsDataLog data to a remote Matlab instance.
        % @param ensemble ensemble object connected to a remote Matlab
        % @details
        % Gets new data from topsDataLog and sends via the given @a
        % ensemble to a remote Matlab instance, to be added to that remote
        % topsDataLog.
        % @details
        % Returns a struct array of new data that was sent.
        function newData = sendNewData(ensemble)
            % get any recent data from the data log.
            newData = topsDataLog.getNewData();
            
            if ~isempty(newData)
                % define/replace a "sendNewData" call for the ensemble
                call = {@topsDataLog.logNewData, newData};
                callName = 'sendNewData';
                ensemble.addCall(call, callName);
                
                % invoke the call to transmit data to a remote data log
                ensemble.callByName(callName);
            end
        end

        % Flush data from a remote data log.
        % @param ensemble ensemble object connected to a remote Matlab
        % @details
        % Instructs a remote Matlab instance, via the given @a ensemble, to
        % flush data from the remote topsDataLog.
        function flushData(ensemble)
            % define/replace a "flushData" call for the ensemble
            call = {@topsDataLog.flushAllData};
            callName = 'flushData';
            ensemble.addCall(call, callName);
            
            % invoke the call to flush the remote data log
            ensemble.callByName(callName);
        end
        
        % Write new topsDataLog data to a remote disk.
        % @param ensemble ensemble object connected to a remote Matlab
        % @param fileWithPath name and path of the data file to write
        % @param isAutomated whether to automatically write data to disk
        % @details
        % Instructs a remote Matlab instance, via the given @a ensemble, to
        % write topsDataLog data to disk.  By default, this happens once.
        % If @a isAutomated is true, the remote counterpart of the given
        % ensemble will continuously attempt to write new data to disk,
        % whenever new data re available.
        function writeToDisk(ensemble, fileWithPath, isAutomated)
            
            if nargin < 2 || isempty(fileWithPath)
                log = topsDataLog.theDataLog();
                fileWithPath = log.fileWithPath;
            end
            
            if nargin < 3 || isempty(isAutomated)
                isAutomated = false;
            end
            
            % define/replace a "writeToDisk" call for the ensemble
            call = {@topsDataLog.writeDataFile, fileWithPath};
            callName = 'writeToDisk';
            ensemble.addCall(call, callName);
            
            % invoke the call to instruct the remote data log to write to
            % disk
            ensemble.callByName(callName);
            
            % continuously write data to disk?
            ensemble.setActiveByName(callName, isAutomated);
        end
    end
end