classdef dotsWritableDOutLabJack < dotsWritableDOut
   
   % @class dotsWritableDOutLabJack
   % Implement digital outputs using the LabJack device and its libraries.
   %  
   % Created 6/10/19 by jig from example code sent by Ryan Archer
   
   properties
      
      % Using labjack class properties
      pulsePort = 0;
      
      % TTL pulse width
      pulsewidth = 10;  % milliseconds
      
      % For debugging
      verboseMode = false;
   end
   
   properties (SetAccess = protected)
      
      % The labJack object
      daq;      
   end
   
   methods
      
      % Arguments are ultimately passed to openDevice
      function self = dotsWritableDOutLabJack(varargin)
         self = self@dotsWritableDOut();
         
         % Initialize the labJack
         self.daq = labJack(); 
         
         % 'verbose',true will include labjack.m text output
         if self.verboseMode
            self.verbose = true;
         end
      end
      
      % Send a TTL pulse.
      %
      % Returns the timestamp returned from sendTTLSignal().  As long as
      % pulseSignal begins with a true value, the timestamp will be an
      % estimate of when @a channel transitioned to a high value. See
      % sendTTLSignal() for timing details and other details.
      function timestamp = sendTTLPulse(self, pulsePort)
         
         % Check arg
         if nargin >= 2 && ~isempty(pulsePort)
            self.pulsePort = pulsePort;
         end
         
         % Getting timestamp for pulse onset.
         timestamp = mglGetSecs; 
        
         % Send the pulse
         self.daq.timedTTL(self.pulsePort, self.pulsewidth);
      end
   end
end
