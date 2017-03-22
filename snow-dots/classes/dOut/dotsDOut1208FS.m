classdef dotsDOut1208FS < dotsAllDOutObjects
    % @class dotsDOut1208FS
    % Implement digital outputs using mexHID() and the 1208FS USB device.
    % @details
    % dotsDOut1208FS is an implementation of the dotsAllDOutObjects
    % interface for doing digital outputs.  It uses the mexHID() mex
    % function to locate and control the "1208FS" USB device from
    % Measurement Computing.  dotsAllDOutObjects uses only a few features
    % of the 1208FS:
    %   - 15-bit output words, plus one strobe bit, use up both of the
    %   digital ports, A and B.
    %   - TTL pulses and signals may use either analog output port, 0 or 1,
    %   one at atime.
    %   .
    % The description of each interface method contains specific
    % information about which device function and pins it expects to use.
    % @details
    % Since timing is a key part of the dotsAllDOutObjects interface, some
    % general timng considerations for mexHID() and the
    % 1208FS follow.  The description of each interface method contains
    % additional, specific timing considerations.
    % @details
    % <b>mexHID() timing</b>
    % @details
    % mexHID() exposes to Matlab the USB and HID functionality of its host
    % operating system (so far only OS X).  Thus it allows Matlab to
    % exchange data with USB "Human Interface Devices", including the
    % 1208FS.  USB data exchanges are called "transactions", which take
    % place during USB "frames", which are regular chunks of time.  So for
    % mexHID(), timing considerations have the flavor of "During which
    % frame was that command sent?" and "What time did that frame occurr?".
    % mexHID() makes this kind of information available.
    % @details
    % In particular, for each transaction that it initiates, mexHID()
    % returns a pre- and post-transaction frame number, each with its own
    % timetsamp.  The pre-post interval indicates how many frames (usually
    % 2) or seconds it took to carry out a transaction.  Large intervals
    % might indicate a problem.  The post-transaction timestamps tend to
    % align with the discrete USB frame edges.
    % @details
    % For the 1208FS device, each USB frame is 1ms long, and this is the
    % timing precision available for controlling the device and accounting
    % for its behavior (but not for its onboard behavior, see below).
    % @details
    % As an aside, note that learning when a transaction happened is not
    % the same as controlling when it will happen.  Such control is not
    % available from mexHID(), nor is it natural to implement in Matlab.
    % But in many cases, as long as the timing information is accurate, it
    % doesn't matter whether it's "past tense" or "future tense".
    % @details
    % <b>1208FS onboard behavior</b>
    % mexHID() can exchange data and commands with the HID front-end
    % of the 1208FS device.  The device also has an onboard microcontroller
    % and memory with which it can do significant behaviors which are
    % beyond the scope of the HID protocol and normal "human interfaces".
    % @details
    % dotsDOut1208FS uses these onboard behaviors to send TTL signals and
    % pulses with deterministic timing: it sends a sequence of
    % voltage samples to be buffered in the device's memory and tells the
    % microprocessor to output the samples at a regular frequency.  Since
    % the onboard microprocessor is removed from Matlab and its
    % multitasking host opertating system, dotsDOut1208FS expects the
    % samples to be output with deterministic timing.
    % @details
    % Thus, the timestamps returned from dotsDOut1208FS are estimates to
    % the nearest 1ms of when an onboard behavior was initiated.
    % dotsDOut1208FS leaves detailed control of ongoing behaviors up to the
    % device's microprocessor.
    % @details
    % From tests, it appears that the 1208FS could buffer 512 unique
    % voltage samples after whcih it would overwrite older samples.  Thus,
    % dotsDOut1208FS will only attempt to output TTL signals that are this
    % long or shorter.  The span of time over which the device outputs the
    % samples depends on the specified sample frequency, which may range
    % from about 0.5Hz through 10,000Hz.  Note that 10,000Hz is well beyond
    % the realm of 1ms USB frames!
    
    properties
        % USB vendor ID for the 1208FS device
        vendorID = 2523;
        
        % USB product ID for the 1208FS device
        productID = 130;
        
        % valid output channels for TTL pulses and signals
        channels = [0 1];
        
        % valid output ports for strobed words
        ports = 0;
        
        % HID report ID for digital port setup
        dPortConfigID = 1;
        
        % HID report ID for digital port output
        dPortOutID = 4;
        
        % width of TTL pulse in seconds
        pulseWidth = .001;
        
        % TTL signal containing a single pulse
        pulseSignal = [true false];
        
        % HID report ID to start analog output scans
        signalStartID = 21;
        
        % HID element cookie for analog output status
        signalStatusCookie = 8;
        
        % "still running" status returned from 1208FS device
        signalStatusRunning = 0;
        
        % "all done" status returned from 1208FS device
        signalStatusDone = 2;
        
        % HID report ID to stop analog output scans
        signalStopID = 22;
        
        % HID report ID to sending analog output samples
        signalSamplesID = 0;
        
        % number of analog output samples to send per report
        signalSamplesPerReport = 32;
        
        % max number of samples that the 1208FS can buffer
        signalMaxSamples = 512;
        
        % number of reports the 1208FS may buffer before initiating scan
        signalPrescanReports = 7;
        
        % clock frequency used by the 1208FS microcontroller
        clockFrequency = 10e6;
        
        % maximum counter size used by the 1208FS microcontroller
        clockMaxPreload = 65535;
        
        % maximum clock scale exponent used by the 1208FS microcontroller
        clockMaxPrescale = 8;
    end
    
    properties (SetAccess = protected)
        % mexHID() device IDs for all the 1208FS sub-devices
        deviceIDs;
        
        % mexHID() device ID for the primary 1208FS device
        primaryID;
        
        % mexHID() device ID for the output 1208FS device
        outputID;
    end
    
    methods
        % Open and configure the 1208FS device with mexHID().
        % @param properties optional struct of HID device properties for
        % locating a particular 1208FS device
        % @details
        % Initializes mexHID() if necessary and locates the 1208FS deivce
        % using by VendorID, ProductID, and any additional @a properties
        % specified (e.g. SerialNumber).  Opens the four sub-devices of the
        % 1208FS and determines which is the primary front-end (primaryID)
        % and which is the analog output scan device (outputID).
        % @details
        % Configures both digital output ports, A and B, for doing outputs.
        % Stops any analog output scan that might be in progress, and sets
        % intial low (0V nominal) values to both analog output channels.
        function self = dotsDOut1208FS(properties)
            % combine default matching criteria with additional properties
            matching.VendorID = self.vendorID;
            matching.ProductID = self.productID;
            if nargin && isstruct(properties)
                fn = fieldnames(properties);
                for ii = 1:numel(fn)
                    p = fn{ii};
                    matching.(p) = properties.(p);
                end
            end
            
            % locate the 1208FS device
            if ~mexHID('isInitialized')
                mexHID('initialize');
            end
            self.deviceIDs = mexHID('openAllMatchingDevices', matching);
            if all(self.deviceIDs < 0)
                disp('no device matched')
                self.isAvailable = false;
                return;
            else
                self.isAvailable = true;
            end
            
            % locate sub-devices with different functions
            nDevices = numel(self.deviceIDs);
            deviceProps = mexHID('getDeviceProperties', self.deviceIDs);
            for ii = 1:nDevices
                if deviceProps(ii).MaxFeatureReportSize > 0
                    self.primaryID = self.deviceIDs(ii);
                else
                    if deviceProps(ii).MaxOutputReportSize > 0
                        self.outputID = self.deviceIDs(ii);
                    end
                end
            end
            
            % make sure the device is stopped, to start with
            stop = self.formatSignalStop;
            mexHID('writeDeviceReport', self.primaryID, stop);
            
            % confiugure both digital ports A and B to do output
            dOutA = self.formatDigitalConfig(0, 0);
            mexHID('writeDeviceReport', self.primaryID, dOutA);
            dOutB = self.formatDigitalConfig(1, 0);
            mexHID('writeDeviceReport', self.primaryID, dOutB);
            
            % set all analog outputs to low
            signal = false;
            frequency = ceil(1/self.pulseWidth);
            for cc = self.channels
                self.writeSignalSamples(cc, signal, frequency);
                self.waitForRunningSignal;
            end
        end
        
        % Send a 15-bit strobed word spanning digial ports A and B.
        % @param word unsigned integer representing a word or code to send
        % @param port ignored, always uses ports A and B
        % @details
        % Uses both digital output ports of the 1208FS, A and B, to send a
        % 15-bit strobed word.  Sets the 8 lowest bits of @a word to port
        % A.  Sets the next 7 bits of @a word to port B.  Ignores any
        % higher bits of @a word.  Uses the 8th bit of port B as a strobe
        % bit.
        % @details
        % Makes four mexHID() transactions to write the bits of @a word to
        % the digital ports and flash the strobe bit.
        %   -# writes the low 8 bits to port A
        %   -# writes the high 7 bits to port B, with strobe bit clear
        %   -# writes the high 7 bits to port B, with strobe bit set
        %   -# writes the high 7 bits to port B, with strobe bit clear
        %   .
        % The four transactions makes sure that all @a word bits are in
        % place before the strobe bit is set, and that the strobe bit is
        % cleared before continuing.  Thus, the strobe bit may remain set
        % for as long as it takes to complete a transaction.  From tests,
        % it appears this takes about 2ms.
        % @details
        % Returns the mexHID() pre-transaction timestamp from the 3rd
        % transaction, when the strobe bit was set.
        % @details
        % Here are the word bits, digital port bits, and phisical device
        % pins that dotsDOut1208FS expects to match:
        % <table border="0" cellpadding="3" cellspacing="2"
        %   frame="void" rules="all">
        % <tr>
        %   <td>word bit</td><td>0</td><td>1</td><td>2</td><td>3</td>
        %   <td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td>
        %   <td>10</td><td>11</td><td>12</td><td>13</td>
        %   <td>14</td><td>(strobe)</td>
        % </tr>
        % <tr>
        %   <td>port bit</td><td>A0</td><td>A1</td><td>A2</td><td>A3</td>
        %   <td>A4</td><td>A5</td><td>A6</td><td>A7</td><td>B0</td>
        %   <td>B1</td><td>B2</td><td>B3</td><td>B4</td><td>B5</td>
        %   <td>B6</td><td>B7</td>
        % </tr>
        % <tr><td>pin</td><td>21</td><td>22</td><td>23</td><td>24</td>
        %   <td>25</td><td>26</td><td>27</td><td>28</td><td>33</td>
        %   <td>34</td><td>35</td><td>36</td><td>37</td><td>38</td>
        %   <td>39</td><td>40</td>
        % </tr>
        % </table>
        function timestamp = sendStrobedWord(self, word, port)
            if ~self.isAvailable
                timestamp = -1;
                return
            end
            
            littleByte = mod(floor(word), 2^8);
            bigByte = mod(bitshift(word, -8), 2^7);
            
            report(1) = self.formatDigitalOutput(0, littleByte);
            report(2) = self.formatDigitalOutput(1, bigByte);
            report(3) = self.formatDigitalOutput(1, bigByte + 2^7);
            report(4) = self.formatDigitalOutput(1, bigByte);
            n = numel(report);
            
            [status, timing] = mexHID('writeDeviceReport', ...
                self.primaryID, report);
            
            if status < 0
                timestamp = -1;
            else
                % pre-transaction time for strobe high
                timestamp = timing(3,3);
            end
        end
        
        % Send a TTL pulse, using a short TTL signal.
        % @param channel 0 or 1, from which analog output to send the TTL
        % pulse
        % @details
        % Uses sendTTLSignal() to send a single TTL pulse.  The signal is
        % specified in the pulseSignal property and should contain a single
        % region of true, followed by false.  This assumes that @a channel
        % begins at a low value and will transition to high and back to low
        % during the pulse.
        % @details
        % The pulseWidth property specifies the duration of each sample in
        % pulseSignal: output sample frequency is equal to 1/pulseWidth.
        % @details
        % Returns the timestamp returned from sendTTLSignal().  As long as
        % pulseSignal begins with a true value, the timestamp will be an
        % estimate of when @a channel transitioned to a high value. See
        % sendTTLSignal() for timing details and other details.
        function timestamp = sendTTLPulse(self, channel)
            frequency = ceil(1/self.pulseWidth);
            timestamp = self.sendTTLSignal( ...
                channel, self.pulseSignal, frequency);
        end
        
        % Send a TTL signal using an analog output scan.
        % @param channel 0 or 1, from which analog output to send @a signal
        % @param signal logical array specifying a sequence of TTL values
        % to output from @a channel, with true->high and false->low
        % @param frequency frequency in Hz at which to move through
        % elements of @a signal
        % @details
        % Outputs the given TTL @a signal, at the given sample @a
        % frequency, from the given analog output @a channel, under control
        % of the 1208FS device's onboard microprocessor.  If @a signal is
        % too long to fit in the device's onboard memory, returns
        % immediately with a negative error code.  From tests, it appears
        % that the onboard memory holds 512 samples.
        % @details
        % Before outputting a new TTL signal, blocks until the 1208FS
        % deivce reports that the previous signal is all done.  Otherwise,
        % the previous signal would be truncated.  The device reports the
        % status of the previous signal as a HID element value which
        % mexHID() can read.
        % @details
        % Once ready, makes 1 mexHID() transaction to configure the given
        % @a channel to ouput n samples at the given @a frequency, where n
        % is the number of elements in @a signal.  Then makes m additional
        % transactions to write @a signal data to the 1208fs device's
        % onboard memory.  Since each transaction contains 32 samples, m is
        % equal to n/32, rounded up.
        % @details
        % From tests, it appears that the 1208FS begins outputting
        % @a signal upon receipt of one of the m @a signal data
        % transactions.  There are two apparent patterns:
        %   -# when the number of transacitons m is 7 or fewer, the
        %   device outputs samples upon receipt of last transaction.
        %   -# when the number of transacitons m is 8 or more, the
        %   device outputs samples upon receipt of 8th transaction.
        %   .
        % Returns the mexHID() pre-transaction timestamp from either the
        % last or the 8th transaction, as above.  From tests, it appears
        % that this pre-transaction timestamp preceeds signal onset by
        % about 3.5ms when the scan @a frequency is 1000Hz and about 1.5ms
        % when the scan @a frequency is 10,000Hz.  The size of the
        % preceeding interval did not seem to depend on the length of @a
        % signal.  Further testing would be warranted.
        % @details
        % Here are the channels, "signal name"s and phisical device pins
        % that dotsDOut1208FS expects to match:
        % <table border="0" cellpadding="3" cellspacing="2"
        %   frame="void" rules="all">
        % <tr>
        %   <td>@a channel</td><td>0</td><td>1</td>
        % </tr>
        % <tr>
        %   <td>name</td><td>D/A OUT 0</td><td>D/A OUT 1</td>
        % </tr>
        % <tr>
        %   <td>pin</td><td>13</td><td>14</td>
        % </tr>
        % </table>
        function timestamp = sendTTLSignal( ...
                self, channel, signal, frequency)
            if ~self.isAvailable
                timestamp = -1;
                return
            end
            
            nSamples = numel(signal);
            if nSamples > self.signalMaxSamples
                warning('TTL signal is too long: %d > %d max samples', ...
                    nSamples, self.signalMaxSamples);
                timestamp = -2;
                return;
            end
            
            % block while a previous signal is still being output
            self.waitForRunningSignal;
            
            % send the new signal
            [status, timing] = self.writeSignalSamples( ...
                channel, signal, frequency);
                        
            if status < 0
                timestamp = -3;
            else
                nReports = size(timing, 1);
                if nReports > self.signalPrescanReports
                    goReport = self.signalPrescanReports + 1;
                else
                    goReport = nReports;
                end
                % pre-transaction time for report that triggered actual
                % scan.  This appears to preceed the actual scan by a few
                % ms.
                timestamp = timing(goReport,3);
            end
        end
        
        % Release the mexHID() device.
        % @details
        % Stops any analog output scan that might be in progress, and
        % releases all four sub-devices of the 1208FS.
        % @details
        % Does not attempt to terminate mexHID().
        function status = close(self)
            if self.isAvailable
                stop = self.formatSignalStop;
                mexHID('writeDeviceReport', self.primaryID, stop);
            end
            self.isAvailable = false;
            status = mexHID('closeDevice', self.deviceIDs);
        end
    end
    
    methods (Access = protected)
        % Format a HID report to configure an analog output scan.
        function report = formatSignalConfig( ...
                self, channel, signal, frequency)
            report.type = 2;
            report.ID = self.signalStartID;
            
            report.bytes=uint8(zeros(1,11));
            report.bytes(1) = report.ID;
            report.bytes(2) = channel;
            report.bytes(3) = channel;
            
            n = uint32(numel(signal));
            report.bytes(4) = mod(n, 2^8);
            report.bytes(5) = mod(bitshift(n,-8), 2^8);
            report.bytes(6) = mod(bitshift(n,-16), 2^8);
            report.bytes(7) = mod(bitshift(n,-24), 2^8);
            
            prescale = ceil(log2( ...
                self.clockFrequency/(self.clockMaxPreload*frequency)));
            prescale = max(0, min(self.clockMaxPrescale, prescale));
            preload = round(self.clockFrequency/(2^prescale*frequency))-1;
            preload = max(0, min(self.clockMaxPreload,preload));
            report.bytes(8) = prescale;
            report.bytes(9) = mod(preload, 2^8);
            report.bytes(10) = mod(bitshift(preload,-8), 2^8);
            
            isFinite = true;
            isTriggered = false;
            report.bytes(11) = isFinite + 2*isTriggered;
        end
        
        % Format a HID report to end an analog output scan.
        function report = formatSignalStop(self)
            report.type = 2;
            report.ID = self.signalStopID;
            report.bytes = uint8(report.ID);
        end
        
        % Format a HID report to send analog out sample byte data.
        function report = formatSignalData(self, signal)
            type = 2;
            ID = self.signalSamplesID;
            nReports = ceil(numel(signal)/self.signalSamplesPerReport);
            bytes = ...
                zeros(2*self.signalSamplesPerReport, nReports, 'uint8');
            bytes(find(signal)*2) = 255;
            bytes(find(signal)*2-1) = 255;
            byteCell = num2cell(bytes, 1);
            report = struct( ...
                'type', type, ...
                'ID', ID, ...
                'bytes', byteCell);
        end
        
        % Format a HID report to configure digital port direction.
        function report = formatDigitalConfig(self, port, isInput)
            report.type = 2;
            report.ID = self.dPortConfigID;
            report.bytes = uint8([report.ID, port, isInput]);
        end
        
        % Format a HID report to send digital port byte
        function report = formatDigitalOutput(self, port, byte)
            report.type = 2;
            report.ID = self.dPortOutID;
            report.bytes = uint8([report.ID, port, byte]);
        end
        
        % Block as long as the device reports "still running".
        function signalStatus = waitForRunningSignal(self)
            signalStatus = self.signalStatusRunning;
            while signalStatus == self.signalStatusRunning
                signalData = mexHID('readElementValues', ...
                    self.primaryID, self.signalStatusCookie);
                signalStatus = signalData(2);
            end
        end
        
        % Write configuration and samples to analog output scan.
        function [status, timing] = writeSignalSamples( ...
                self, channel, signal, frequency)
            % generate HID reports
            config = self.formatSignalConfig( ...
                channel, signal, frequency);
            samples = self.formatSignalData(signal);
            nReports = numel(samples);
            
            timing = zeros(nReports,5);
            
            % write reports to the device
            [status, configTiming] = mexHID('writeDeviceReport', ...
                self.primaryID, config);
            
            [status, timing] = mexHID('writeDeviceReport', ...
                self.outputID, samples);
        end
    end
end