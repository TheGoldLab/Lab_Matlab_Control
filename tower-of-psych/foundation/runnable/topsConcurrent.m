classdef topsConcurrent < topsRunnable
    % @class topsConcurrent
    % Superclass for flow-control classes that may operate concurrently.
    % @details
    % The topsConcurrent superclass provides a common interface for Tower
    % of Psych classes that manage flow control, and may work concurrently
    % with one another.
    % @details
    % In addition to being able to run(), topsConcurrent objects can also
    % runBriefly(), which means to carry out a small part of their normal
    % run() behavior, and then return as soon as possible.  runBriefly()
    % behaviors can be interleaved to acheive concurrent operation of
    % multiple topsConcurrent objects within a single Matlab instance.
    % @details
    % Multiple topsConcurrent objects can be aggregated within a single
    % topsConcurrentComposite object.  This makes allows the aggregated
    % objects to be treated like a single topsRunnable object.

    properties
        % string used for topsDataLog entry just before runBriefly()
        runBrieflyString = 'runBriefly';
    end
    
    methods
        % Constuct with name optional.
        % @param name optional name for this object
        % @details
        % If @a name is provided, assigns @a name to this object.
        function self = topsConcurrent(varargin)
            self = self@topsRunnable(varargin{:});
        end

        % Do flow control.
        % @param duration how long in seconds to keep running
        % @details
        % topsConcurrent redefines the run() method of topsRunnable.  It
        % uses start(), finish(), and repeated calls to runBriefly() to
        % accomplish run() behaviors.  By default, run() takes over
        % flow-control from the caller until isRunning becomes false.  If
        % @a duration is provided, runs until isRunning becomes false, or
        % @a duration elapses, then sets isRunning to false.
        function run(self, duration)
            if nargin < 2
                duration = inf;
            end
            endTime = duration + topsClock();
            
            self.start();
            while self.isRunning && (topsClock() < endTime)
                self.runBriefly();
            end
            self.isRunning = false;
            self.finish();
        end
        
        % Do a little flow control and return as soon as possible.
        % @details
        % Subclasses should redefine runBriefly() to do specific run()
        % behaviors, a little at a time, and return as soon as possible.
        function runBriefly(self)
            self.isRunning = false;
        end
    end
end