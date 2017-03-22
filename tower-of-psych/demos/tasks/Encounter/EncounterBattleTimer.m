classdef EncounterBattleTimer < handle
    % @class EncounterBattleTimer
    % Timer class to help schedule events in the "Encounter" demo game.
    
    properties
        % when the next event should occur in units of clockFunction
        nextFire = inf;
        
        % interval between scheculed events in units of clockFunction
        repeatInterval = inf;
        
        % fevalable cell array to invoke when the timer fires
        callback = {};
        
        % function that returns the current time as a number
        clockFunction = @topsClock;
    end
    
    methods
        % Create a new timer object.
        function self = EncounterBattleTimer()
        end
        
        % Load the timer to fire later and invoke a callback, once.
        function loadForTimeWithCallback(self, time, callback)
            self.nextFire = time;
            self.callback = callback;
        end
        
        % Load the timer to fire later and invoke a callback, repeatedly.
        function loadForRepeatIntervalWithCallback( ...
                self, interval, callback)
            self.repeatInterval = interval;
            self.callback = callback;
        end
        
        % Start firing repeated callbacks.
        function beginRepetitions(self)
            nowTime = feval(self.clockFunction);
            self.nextFire = nowTime + self.repeatInterval;
        end
        
        % Update and possibly fire a callback.
        function didFire = tick(self)
            nowTime = feval(self.clockFunction);
            didFire = nowTime >= self.nextFire;
            
            if didFire
                feval(self.callback{:});
                topsDataLog.logDataInGroup( ...
                    self.callback, 'battleTimer fired');
                self.nextFire = nowTime + self.repeatInterval;
            end
        end
    end
end