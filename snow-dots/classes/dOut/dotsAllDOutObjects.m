classdef dotsAllDOutObjects < handle
    % @class dotsAllDOutObjects
    % An abstract interface for doing digital outputs.
    % @details
    % dotsAllDOutObjects defines a standard interface for working with
    % digital outputs from Snow Dots.  Subclasses of dotsAllDOutObjects
    % are expected to implement this set of methods and accomplish
    % particular ouput behaviors. Implementations may be wrappers around
    % mex function calls, for example.
    % @details
    % The purpose of the dotsAllDOutObjects interface is to allow Snow
    % Dots to do digital outputs on any Matlab platform that has digital
    % output capabilities, independent of the underlying hardware or
    % drivers.  To facilitate platform independence, dotsAllDOutObjects
    % requries only a few behaviors to be implemented, and does not require
    % implementation of the full feature set for any one device.
    % @details
    % Note that dotsAllDOutObjects specifies no way to receive input data.
    % It only expects implementations to send an output and hope that it is
    % received by a connected system.  With many hardware configurations
    % this will work fine.  Other configurations may require some
    % back-and-forth communication in order to ensure that the connected
    % system is ready to receive a signal, or that the signal was received
    % successfully.  It is up to a particular dotsAllDOutObjects
    % implementation/implementer to decide whether and when this is
    % necessary and to implement this kind of behavior from one of the
    % dotsAllDOutObjects interface methods.
    % @deatils
    % As of the November2010 revision of Snow Dots, only one
    % hardware configuration has been implemented and tested:
    % dotsDOut1208FS to send digital signals through the 1208FS USB decvice
    % by Measurement Computing, connected to the Plexon MAP data collection
    % system.  For the sendStrobedWord method implemention, it turnes out
    % that dotsDOut1208FS can send a strobed word at the fastest once per
    % 8ms, and it leaves its strobe bit high for 1-2ms.  The Plexon MAP
    % system operates on a faster timescale: it can receive a strobed word
    % input once per 125 ?sec. Therefore, dotsDOut1208FS does no
    % back-and-forth communication when sending an output.  It does not
    % monitor any "busy" signal or similar.
    % @deatils
    % Any Snow Dots script or tasks that wants to send digital signals
    % to external systems should create an instance of a dotsAllDOutObjects
    % subclass that is appropriate for the local machine.  The
    % machine-appropriate class should be specified in
    % dotsTheMachineConfiguration, as the default "dOutClassName".  This
    % value can be accessed through dotsTheMachineConfiguration.  For
    % example:
    % @code
    % name = dotsTheMachineConfiguration.getDefaultValue('dOutClassName')
    % myDOutObject = feval(name);
    % @endcode
    methods (Abstract)
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
        timestamp = sendStrobedWord(self, word, port);
        
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
        timestamp = sendTTLPulse(self, channel);
        
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
        timestamp = sendTTLSignal(self, channel, signal, frequency);
        
        % Release resources.
        % @details
        % Must release any resources, close any ports, etc. that were
        % acquired during construction, and set isAvailable to false.
        % @details
        % Must return a non-negative scalar to indicate successful release,
        % or a negative scalar to indicate an error.
        status = close(self);
    end
    
    properties
        % true or false, whether the object is ready to use.
        % @details
        % Subclass constructors should set isAvailable depending on whether
        % the object and any hardware are connected, initialized, and ready
        % for use.
        % @details
        % Subclass close() methods should set isAvailable to false.
        isAvailable = false;
    end
end