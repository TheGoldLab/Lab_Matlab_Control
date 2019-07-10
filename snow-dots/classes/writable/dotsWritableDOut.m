classdef dotsWritableDOut < dotsWritable
    %> @class dotsWritableDOut
    %> Superclass for objects that write data as digital output.
    %> @details
    %> The dotsWritable superclass provides a uniform way to write digital data,
    %> such as TTL pulses.
    
    properties
        
        % for sendTTL pulses
        defaultPauseBetweenPulses = 0.1;
    end
    
    methods
        
        % Constructor takes no arguments.
        function self = dotsWritableDOut()
            self = self@dotsWritable();
        end
        
        % Send a strobed digital word.
        % @param word unsigned integer representing a word or code to send
        % @param port optional 0-based id indicating from which physical
        % port to send @a word
        % @details
        % Must set the bits of the digital output indicated by @port to
        % match @a word, then set a strobe bit to indicate to an external
        % system that @a word is ready for reading, then clear the strobe
        % bit.
        % @details
        % If @a word is too large to fit within the bits of @a port, must
        % set as many least-significant bits as possible, and must not clip
        % or round @a word.  For example, if @a word is a 16-bit integer
        % and @a port has only 8 bits, must set @a word modulo 2^8, instead
        % of clipping or rounding @a word to 2^8-1.
        % @details
        % If @a port is omitted, or of there is only one physical output
        % port, should treat @a port as 0.
        % @details
        % Must return a positive timestamp, based on the local host's
        % clock, that is the best estimate of when the strobe bit was set,
        % or a negative scalar to indicate an error.
        function timestamp = sendStrobedWord(self, word, port)
        end
        
        % Send a single TTL pulse.
        % @param channel optional 0-based id indicating from which physical
        % channel to send the TTL pulse.
        % @details
        % Must send a standard transistor-transistor-logic(TTL) pulse on
        % the given @a channel.
        % @details
        % A TTL pulse should begin with @a channel already at a low value,
        % within 0.0-0.8V of ground. The @a channel should transition to a
        % high value, within 2.2-5V above ground, for a duration long
        % enough to be detected by an external system.  Then @a channel
        % should transition back to a low value.
        % @details
        % If @a channel is omitted, or of there is only one physical output
        % channel, should treat @a channel as 0.
        % @details
        % Must return a positive timestamp, based on the local host's
        % clock, that is the best estimate of when @a channel transitioned
        % to its high value, or a negative scalar to indicate an error.
        function timestamp = sendTTLPulse(self)
        end
        
        % Send multiple TTL pulses
        % Timestamps are estimates of onset times of first and last pulses.
        function [firstTimestamp, lastTimestamp] = sendTTLPulses(self, ...
                numPulses, pauseBetweenPulses, channel)
            
            % Parse arguments
            if nargin < 2 || isempty(numPulses)
                numPulses = 1;
            end
            
            if nargin < 3 || isempty(pauseBetweenPulses)
                pauseBetweenPulses = self.defaultPauseBetweenPulses;
            end
            
            if nargin < 4
                channel = []; % use default
            end
            
            % Get time of first pulse
            firstTimestamp = self.sendTTLPulse(channel);
            
            % get the remaining pulses and save the finish time
            lastTimestamp = firstTimestamp;
            for pp = 1:numPulses-1
                pause(pauseBetweenPulses);
                lastTimestamp = self.sendTTLPulse(channel);
            end
        end
        
        % Send a TTL signal or waveform.
        % @param channel optional 0-based id indicating from which physical
        % channel to send the TTL signal.
        % @param signal logical array specifying a sequence of TTL values
        % to output from @a channel, with true->high and false->low.
        % @param frequency frequency in Hz at which to move through
        % elements of @a signal.
        % @details
        % Must output standard transistor-transistor-logic(TTL) voltages on
        % the given @a channel, according to the given @a signal and @a
        % frequency.  Once output begins, must make every attempt to output
        % all of @a signal withoug timing jitter, for example by buffering
        % @a signal in external hardware.
        % @details
        % Must output each element of @a signal, one at a time, with true
        % elements corresponding to logic high and false elements
        % corresponding to logic low.  Each logic value should persist on
        % @a channel for the 1/@a frequency seconds.  Consecutive high or
        % low otuputs should be continuous, without gaps, so that @a signal
        % may specify a sequence of logic pulses, or a square logic
        % wavform.
        % @details
        % May or may not block in order to complete and/or verify output.
        % If @a signal is too long or @a frequency is unattainable for the
        % given @a channel, should return immediately and return a negative
        % status value.
        % @details
        % If @a channel is omitted, or of there is only one physical output
        % channel, should treat @a channel as 0.
        % @details
        % Must return a positive timestamp, based on the local host's
        % clock, that is the best estimate of when @a the first element of
        % @a signal was output, or a negative scalar to indicate an error.
        function timestamp = sendTTLSignal(self, channel, signal, frequency)
        end
    end
    
    methods (Static)
        
        % get default Dout device
        function dout = getDefault()
            dout = feval( ...
                dotsTheMachineConfiguration.getDefaultValue('dOutClassName'));
        end
    end
end