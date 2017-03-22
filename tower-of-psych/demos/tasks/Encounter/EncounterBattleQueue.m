classdef EncounterBattleQueue < handle
    % @class EncounterBattleQueue
    % Queue of feval()able cell arrays, for "Encounter" demo game.

    properties
        % cell array of fevalable cell arrays
        fevalables = {};
        
        % true or false, whether a new fevalable may be dispatched
        isLocked = false;
    end
    
    methods
        % Create a new queue object.
        function self = EncounterBattleQueue()
        end
        
        % Clear out all queued fevalables without invoking them.
        function flushQueue(self)
            self.fevalables = {};
        end
        
        % Add a new fevalable to the back end of the queue.
        function addFevalable(self, fevalable)
            self.fevalables{end+1} = fevalable;
        end
        
        % Invoke and discard the fevalable at the front end of the queue.
        % @details
        % If isLocked is true, does nothing.
        function dispatchNextFevalable(self)
            if ~self.isLocked && ~isempty(self.fevalables)
                feval(self.fevalables{1}{:});
                topsDataLog.logDataInGroup( ...
                    self.fevalables{1}, 'battleQueue dispatched');
                self.fevalables(1) = [];
            end
        end
    end
end