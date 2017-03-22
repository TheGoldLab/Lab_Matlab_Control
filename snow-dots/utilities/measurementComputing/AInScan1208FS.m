classdef AInScan1208FS < handle
    % @class AInScan1208FS
    % Implement analog input scans with mexHID() and the 1208FS USB device.
    % @details
    % Note that AInScan1208FS requires MCCFormatReport.m and the mexHID()
    % mex-function for USB communictaion.
    % @details
    % AInScan1208FS uses the mexHID() mex function to locate and control
    % the "1208FS" USB device from Measurement Computing.  AInScan1208FS
    % uses a subset of features of the 1208FS:
    %   - 12-bit continuous sampling from up to 4 differential inputs
    %   - 11-bit continuous sampling from up to 8 single-ended inputs
    %   - 0-50kHz sample rate (shared among inputs)
    %   - configurable precision and range for differential inputs
    %   .
    % @details
    % Timing is a key part of interpreting input scan results.  For
    % AInScan1208FS, good timing depends on mexHID(), the function that
    % provides USB support, as well as the 1208FS device itself.  Here are
    % some general timing considerations for mexHID() and the 1208FS.
    % @details
    % <b>mexHID() timing</b>
    % @details
    % mexHID() exposes to Matlab the USB and HID functionality of its host
    % operating system (so far only OS X).  Thus it allows Matlab to
    % exchange data with USB "Human Interface Devices", including the
    % 1208FS.  USB data exchanges are called "transactions", which take
    % place during USB "frames", which are regular chunks of time.  So for
    % USB devices, timing considerations have the flavor of "During which
    % frame was that command sent?" and "What time did that frame occur?".
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
    % for its interactions with the operating system (but not for its
    % onboard behavior, see below).
    % @details
    % As an aside, note that learning when a transaction happened is not
    % the same as controlling when it will happen.  Such control is not
    % available from mexHID(), nor is it natural to implement in Matlab.
    % But in many cases, as long as the timing information is accurate, it
    % doesn't matter whether it's "past tense" or "future tense".
    % @details
    % <b>1208FS HID and onboard behaviors</b>
    % HID is a protocol for working with some types of USB device.
    % mexHID() can exchange data and commands with the HID front-end of the
    % 1208FS device.  These exchanges are limited by 1ms USB frames.  The
    % device also has an onboard microcontroller and memory which enable
    % significant behaviors which are beyond the scope of the HID protocol
    % and normal "human interfaces".
    % @details
    % AInScan1208FS uses these onboard behaviors to scan analog inputs with
    % deterministic timing: it sets values in the device's memory which
    % control input channel selection and gain, scan frequency, duration,
    % starting, and stopping.  Scanned voltage samples are buffered in the
    % device's memory.  Since the onboard microprocessor is removed from
    % Matlab and its multitasking host opertating system, AInScan1208FS
    % expects the samples to be taken with deterministic timing.  Also,
    % since the internal workings of the device are distinct from its HID
    % interface, it may scan at frequencies which are well beyond the reach
    % of 1ms USB frames.  That's why it can support 50kHz sample rates.
    % @details
    % <b>Timing reconstruction</b>
    % Once buffered on the device, samples can be transferred to Matlab in
    % batches.  Note that the time when each batch of samples was
    % transferred to Matlab is quite distinct from the time when each
    % sample was stored onboard the 1208FS.  Thus, AInScan1208FS must
    % reconstruct sample timing after each batch has been transferred,
    % based on channel and scan configuration.
    % @details
    % Here are a few considerations for interpreting the sample times that
    % AInScan1208FS reports from getScanWaveform():
    %   - Each scan produces a sequence of samples.  The @e sample times
    %   within a sequence have granularity as small as 1/50kHz and come
    %   from the 1208FS device's onboard microprocessor clock.
    %   - AInScan1208FS must estimate the @e start time of each scan using
    %   USB frames.  Thus, @e start times have 1ms granularity and come
    %   from the host's CPU clock.
    %   - AInScan1208FS reports reconstructed sample times with respect to
    %   the host's CPU clock: it adds the scan @e start time to the
    %   sequence of @e sample times.
    %   - Thus, reconstructed sample times may be considered internally
    %   consistent, but must be treated with ~1ms uncertainty when compared
    %   to external event times.
    %   .
    %
    % @ingroup dotsUtilities
    properties
        % USB vendor ID for the 1208FS device
        vendorID = 2523;
        
        % USB product ID for the 1208FS device
        productID = 130;
        
        % differential(0-7) or single-ended(8:15) input channels to scan
        channels = [8,9];
        
        % precision-and-range selection for differential channels
        gains = [0 7];
        
        % input sample frequency (0-50000Hz), same for each channel
        frequency = 10000;
        
        % number of samples to gather in a scan, total among all channels
        nSamples = inf;
        
        % whether an external trigger will initiate the first scan
        externalTrigger = false;
        
        % whether an external trigger will initiate multiple scans
        externalRetrigger = false;
        
        % sample bytes the OS can hold between transfers to Matlab
        queueDepth = 1000;
        
        % seconds to wait for some new data during waitForData()
        waitTimeout = 0.1;
        
        % clock frequency used by the 1208FS microcontroller
        clockFrequency = 10e6;
        
        % maximum counter size used by the 1208FS microcontroller
        clockMaxPreload = 65535;
        
        % maximum clock scale exponent used by the 1208FS microcontroller
        clockMaxPrescale = 8;
        
        % HID element cookies for input sample values
        sampleValueCookies = 3:64;
        
        % HID element cookie for input sample counting
        sampleCountCookies = 65;
        
        % number of bytes in an input sample
        bytesPerSample = 2;
        
        % number of samples in an input batch transfer
        samplesPerReport = 31;
    end
    
    
    properties(SetAccess = protected)
        % whether the 1208FS was found and configured
        isAvailable;
        
        % mexHID() device IDs for all the 1208FS sub-devices
        deviceIDs;
        
        % mexHID() device ID for the primary 1208FS device
        primaryID;
        
        % mexHID() device ID for the 1208FS helper devices
        helperID;
        
        % number of 1208FS helper devices
        nHelpers;
        
        % struct of HID report and metadata for device configuration
        scanConfigReport;
        
        % HID report ID to start analog input scans
        scanStartReport;
        
        % HID report ID to stop analog input scans
        scanStopReport;
        
        % HID element cookies for all input data
        allInputCookies;
        
        % place values for signed input bytes
        sampleIntMagnitude;
        
        % place values for unsigned input bytes
        sampleUIntMagnitude;
        
        % array size of input batch transfers
        sampleBytesPerReport;
        
        % USB frame time for the 0th input sample
        zeroTime;
        
        % containers.Map of new, unprocessed sample data
        transferredData;
        
        % Matlab-side cache of raw HID report data
        baseElementCache;
    end
    
    
    methods
        % Open and configure the 1208FS device with mexHID().
        % @param properties optional struct of HID device properties for
        % locating a particular 1208FS device
        % @details
        % Initializes mexHID() if necessary and locates the 1208FS deivce
        % using VendorID, ProductID, and any additional @a properties
        % specified (e.g. SerialNumber).  Opens the four sub-devices of the
        % 1208FS and determines which is the primary front-end (primaryID)
        % and which is the analog output scan device (outputID).
        function self = AInScan1208FS(properties)
            
            % do some byte-level accounting to use during sample
            % reconstruction
            self.allInputCookies = ...
                [self.sampleValueCookies, self.sampleCountCookies];
            self.sampleIntMagnitude = 2^(8*self.bytesPerSample-1);
            self.sampleUIntMagnitude = 2^(8*self.bytesPerSample);
            self.sampleBytesPerReport = ...
                self.samplesPerReport*self.bytesPerSample;
            
            % prepare the HID reports for communicating with the 1208FS
            self.buildHIDReports();
            
            % get a place to store raw HID data
            self.transferredData = ...
                containers.Map(0,0, 'uniformValues', false);
            self.transferredData.remove(self.transferredData.keys);
            
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
            self.primaryID = [];
            self.helperID = [];
            self.nHelpers = 0;
            for ii = 1:nDevices
                if deviceProps(ii).MaxFeatureReportSize > 0
                    self.primaryID = self.deviceIDs(ii);
                else
                    self.nHelpers = self.nHelpers + 1;
                    self.helperID(self.nHelpers) = self.deviceIDs(ii);
                end
            end
            
            % make a queue for input elements on each helper device
            context.transferredData = self.transferredData;
            for ii = 1:self.nHelpers
                context.cacheRow = ii;
                context.deviceID = self.helperID(ii);
                callback = {@AInScan1208FS.mexHIDQueueCallback, context};
                mexHID('openQueue', ...
                    self.helperID(ii), self.allInputCookies, ...
                    callback, self.queueDepth);
            end
        end
        
        % Release the mexHID() devices.
        % @details
        % Stops any analog input scan that might be in progress, and
        % releases all four sub-devices of the 1208FS.
        % @details
        % Does not attempt to terminate mexHID().
        function status = close(self)
            if self.isAvailable
                mexHID('writeDeviceReport', ...
                    self.primaryID, self.scanStopReport);
            end
            self.isAvailable = false;
            status = mexHID('closeDevice', self.deviceIDs);
        end
        
        % Configure the 1208FS for a new scan.
        % @details
        % Configures the 1208FS device to do a new scan with the current
        % values of channels, gains, frequency, nSamples,
        % externalTrigger, and externalRetrigger.  Also clears old data
        % from transferredData and baseElementCache.
        % @details
        % Once prepared, initiate the scan with startScan() and stop it, if
        % necessary, with stopScan().  Get scan data in a useable form with
        % getScanWaveform().
        % @details
        % Returns a positive timestamp for when the "prepare" command was
        % acknowleged by the device, as measured with the host CPU clock.
        % This timestamp corresponds to a USB frame and has 1ms
        % granularity.  Returns a negative value if there was an error.
        function timestamp = prepareToScan(self)
            if ~self.isAvailable
                timestamp = -1;
                return;
            end
            
            % build reports in mexHID format, from current properties
            self.buildHIDReports();
            
            % previous scan may not be running now
            self.stopScan();
            
            % configure scan with current channels and gains
            [status, configTiming] = mexHID('writeDeviceReport', ...
                self.primaryID, self.scanConfigReport);
            if status < 0
                timestamp = status;
                return
            else
                % column 5 is mexHID's post-transaction time
                timestamp = configTiming(1,5);
            end
            
            % Read HID element values cached by the OS into Matlab
            %   essentially one complete report per helper device
            %   don't care about timestamps here
            self.baseElementCache = ...
                zeros(self.nHelpers, max(self.allInputCookies));
            for ii = 1:self.nHelpers
                rowData = mexHID('readElementValues', ...
                    self.helperID(ii), self.allInputCookies);
                cookies = rowData(:,1);
                values = rowData(:,2);
                self.baseElementCache(ii, cookies) = values;
            end
            
            % clear old data
            self.transferredData.remove(self.transferredData.keys);
        end
        
        % Initiate a prepared scan.
        % @details
        % Commands the 1208FS device to initiate a continuous scan with the
        % current values of channels, gains, frequency, nSamples,
        % externalTrigger, and externalRetrigger.
        % @details
        % Configire the scan beforehand, with prepareToScan.  Stop it, if
        % necessary, with stopScan().  Get scan data in a useable form with
        % getScanWaveform().
        % @details
        % If the scan might go on for a long time, call mexHID('check')
        % periodocally during the scan.  This may prevent new data from
        % overwriting older data in operating system buffers.
        % @details
        % Returns a positive timestamp for when the "start" command was
        % acknowleged by the device, as measured with the host's CPU clock.
        % This timestamp corresponds to a USB frame and has 1ms
        % granularity.  The first sample recorded during the scan is
        % interpreted to occur at this same time.  Returns a negative
        % value if there was an error.
        function timestamp = startScan(self)
            if ~self.isAvailable
                timestamp = -1;
                return;
            end
            
            status = mexHID('startQueue', self.helperID);
            if status < 0
                timestamp = status;
                return
            end
            
            [status, startScanTiming] = mexHID('writeDeviceReport', ...
                self.primaryID, self.scanStartReport);
            if status < 0
                timestamp = status;
                return
            end
            
            % column 5 is mexHID post-transatction time
            timestamp = startScanTiming(1,5);
            self.zeroTime = timestamp;
        end
        
        % Terminate an ongoing scan.
        % @details
        % Commands the 1208FS device to terminate any ongoing scan.  Get
        % scan data in a useable form with getScanWaveform().
        % @details
        % Returns a positive timestamp for when the "stop" command was
        % acknowleged by the device, as measured with the host CPU clock.
        % This timestamp corresponds to a USB frame and has 1ms
        % granularity.  Returns a negative value if there was an error.
        function timestamp = stopScan(self)
            if ~self.isAvailable
                timestamp = -1;
                return;
            end
            
            [status, stopTiming] = mexHID('writeDeviceReport', ...
                self.primaryID, self.scanStopReport);
            if status < 0
                timestamp = status;
                return
            else
                % column 5 is mexHID's post-transaction time
                timestamp = stopTiming(1,5);
            end
            
            % transfer the last of the queued values to Matlab
            isTransferring = self.waitForData();
            while(isTransferring)
                isTransferring = self.waitForData();
            end
            mexHID('stopQueue', self.helperID);
        end
        
        % Process data from a previous scan.
        % @details
        % Reads buffered data from a previous scan and reconstructs sample
        % byte values and timing for use in Matlab.  Reconstruction may be
        % a slow operation.
        % @details
        % Returns sampled waveforms in several parallel arrays.  The number
        % of elements in each array may be equal to nSamples, if a
        % finite scan was completed.  Otherwise, the nubmer of elements
        % depends on how long the scan has been running and the sample
        % frequency, and "garbage" samples may appear near the end of the
        % waveforms.
        % @details
        % The iith element of each array contains a different type of
        % information about the iith sample:
        %   - c(ii): the input channel where the iith sample was collected
        %   - v(ii): the iith sample value, in volts
        %   - t(ii): estimated CPU time when the iith sample was collected
        %   - u(ii): the "raw" unsigned integer value of the iith sample
        %   .
        % The arrays are returned in the order [c, v, t, u].
        function [c, v, t, u] = getScanWaveform(self)
            if ~self.isAvailable
                c = [];
                v = [];
                t = [];
                u = [];
                return;
            end
            
            % get transferred data into a useable form
            [c, v, t, u] = self.waveformsFromTransfers();
            
            % avoid trailing "garbage" samples if possible
            if isfinite(self.nSamples) && numel(c) > self.nSamples
                isRequested = 1:self.nSamples;
                c = c(isRequested);
                v = v(isRequested);
                t = t(isRequested);
                u = u(isRequested);
            end
            
            % cut out data that appear to be garbage
            if numel(c) > 0
                isGarbage = isnan(c) | isnan(t) | t < t(1);
                c = c(~isGarbage);
                v = v(~isGarbage);
                t = t(~isGarbage);
                u = u(~isGarbage);
            end
        end
        
        % Wait for new data to arrive, or timeout.
        % @details
        % Blocks until new data are transferred from the OS to Matlab,
        % or until waitTimeout elapses.  waitForData() does not wait for
        % @e all available data to be transferred, only for @e some new
        % data.
        % @details
        % Returns up to three outputs.  The first output is logical,
        % whether or not any new data arrived.  The second is a timestamp
        % from when waitForData() started waiting.  The third is a
        % timestamp from when waitForData() finished waiting.  The
        % timestamps correspond to USB frame times.
        function [gotNewData, startTime, finishTime] = waitForData(self)
            % mexHID('check') allows the operating system to invoke
            % mexHIDQueueCallback(), below, which appends to
            % self.transferredData.  mexHID('check') also returns a
            % timestamp from a USB frame.
            startTransferCount = self.transferredData.length();
            startTime = mexHID('check');
            finishTransferCount = self.transferredData.length();
            finishTime = startTime;
            timeoutTime = startTime + self.waitTimeout;
            while startTransferCount == finishTransferCount ...
                    && finishTime < timeoutTime
                finishTime = mexHID('check');
                finishTransferCount = self.transferredData.length();
            end
            gotNewData = startTransferCount < finishTransferCount;
        end
        
        % Plot waveforms as data arrive.
        % @param ax optional axes to plot into
        % @details
        % Plots a live view of data during a scan.  If @a ax is provided,
        % plots data into @ax.  Otherwise, opens a new figure and plots
        % into new axes.
        % @details
        % The plot contains timestamp and voltage data obtained with
        % getScanWaveform().  Since getScanWaveform() must run each time
        % the plot is updated, preview() might be unsuitable for gathering
        % data in time-sensitive situations.
        % @details
        % preview() invokes prepareToScan(), startScan(), and stopScan().
        % It discards data from any previous scan, but data gathered
        % during the preview() scan will remain afterwards.
        % @details
        % If nSamples is finite, preview() attempts to return as soon as
        % nSamples have been transferred to Matlab.  Otherwise, preview()
        % blocks while the plot axes and parent figure remin open, or until
        % the figure records a "q" button press.
        function preview(self, ax)
            if nargin < 2
                % new figure and axes
                f = figure();
                ax = axes('Parent', f);
            else
                % get figure of given axes
                f = ax;
                while ~strcmp(get(f, 'Type'), 'figure')
                    f = get(f, 'Parent');
                end
            end
            
            % set up to plot a line for each channel
            axTitle = sprintf('live %s preview ("q" to stop)', mfilename);
            title(ax, axTitle);
            xlabel(ax, 'timestamp (s)');
            ylabel(ax, 'sample (V)');
            lineColors = lines(16);
            chanLine = zeros(size(self.channels));
            for ii = 1:length(self.channels)
                chanNumber = 1+self.channels(ii);
                chanColor = lineColors(chanNumber,:);
                chanLine(ii) = line(nan, nan, ...
                    'Parent', ax, ...
                    'LineStyle', 'none', ...
                    'Marker', '.', ...
                    'Color', chanColor);
            end
            
            % start scanning and plot results as they arrive
            self.prepareToScan();
            self.startScan();
            n = 0;
            doContinue = true;
            while doContinue
                % wait for some data to plot
                if self.waitForData()
                    [c, v, t, u] = self.getScanWaveform();
                    n = numel(c);
                    for ii = 1:length(self.channels)
                        chanSelector = c == self.channels(ii);
                        if any(chanSelector)
                            set(chanLine(ii), ...
                                'XData', t(chanSelector), ...
                                'YData', v(chanSelector));
                        end
                    end
                end
                
                % plot the latest data
                drawnow();
                doContinue = ishandle(ax) ...
                    && ishandle(f) ...
                    && ~strcmp(get(f, 'CurrentCharacter'), 'q') ...
                    && n < self.nSamples;
            end
            self.stopScan();
        end
    end
    
    
    methods (Access = protected)
        % Remake the config, start, and stop output reports.
        function buildHIDReports(self)
            self.scanConfigReport = MCCFormatReport(self, 'AInSetup', ...
                self.channels, self.gains);
            
            self.scanStartReport = MCCFormatReport(self, 'AInScan', ...
                self.channels, self.frequency, self.nSamples, ...
                self.externalTrigger, self.externalRetrigger);
            
            self.scanStopReport = MCCFormatReport(self, 'AInStop');
        end
        
        % Reconstruct the samples in a given cache of element byte data.
        function [c, v, t, u, n] = channelsFromCache(self, cache)
            % count the report numbers in the given cache
            reportNumber = cache(self.sampleCountCookies);
            firstSampleNumber = reportNumber*self.samplesPerReport;
            n = firstSampleNumber + (0:(self.samplesPerReport-1));
            nChans = numel(self.channels);
            c = self.channels(1 + mod(n, nChans));
            
            % get detailed device config data
            deviceConfig = self.scanConfigReport.other;
            
            % extract report byte data from the given cache
            %   put bytes in rows by place value
            bytes = cache(self.sampleValueCookies);
            byteMasks = deviceConfig.byteMasks(:,1+c);
            byteShifts = deviceConfig.byteShifts(:,1+c);
            maskedBytes = bitand(bytes, byteMasks(1:end));
            shiftedBytes = bitshift(maskedBytes, byteShifts(1:end));
            sortedBytes = reshape(shiftedBytes, ...
                self.bytesPerSample, self.samplesPerReport);
            
            % interpret extracted bytes as unsigned integers
            u = sum(sortedBytes, 1);
            
            % interpret extracted bytes as two's complement signed integers
            %   and convert signed vales to volts
            signedVales = u - ...
                self.sampleUIntMagnitude * (u >= self.sampleIntMagnitude);
            v = signedVales .* deviceConfig.voltScale(1+c);
            
            % let the first sample fall on the "scan start" time
            %   and subsequent samples fall in regular succession
            deviceConfig = self.scanStartReport.other;
            scanInterval = deviceConfig.attainedSampleInterval*nChans;
            t = self.zeroTime + n*scanInterval;
        end
        
        % Reconstruct all the samples in all the transferred data.
        function [c, v, t, u] = waveformsFromTransfers(self)
            
            % account for all data transfers
            % use transfer timestamps to "index" report serial numbers
            groupedTransfers = self.transferredData.values;
            transfers = cat(1, groupedTransfers{:});
            if isempty(transfers)
                nTimestamps = 0;
            else
                timestamps = unique(transfers(:,3));
                nTimestamps = numel(timestamps);
            end
            
            % allocate space for waveforms
            nElements = nTimestamps*self.samplesPerReport;
            c = nan(1, nElements);
            v = nan(1, nElements);
            t = nan(1, nElements);
            u = nan(1, nElements);
            
            if nElements == 0
                return
            end
            
            % constants for tracking report numbers, below
            startTime = self.zeroTime;
            reportInterval = self.samplesPerReport / self.frequency;
            overflowInterval = 256*reportInterval;
            overflowHalf = overflowInterval/2;
            
            % start with the cached values from prepareToScan()
            %   the cache contains a separate row for each helper device
            %   update the cache for successive transfers from each helper
            runningCache = self.baseElementCache;
            for ii = 1:nTimestamps
                % update the cache for the next transfer
                %   don't assume transfers is sorted
                %   and keep track of which helper device sent the transfer
                isThisTimestamp = transfers(:,3) == timestamps(ii);
                cacheCols = transfers(isThisTimestamp,1);
                cacheRows = transfers(isThisTimestamp,4);
                cacheIndexes = cacheRows + (cacheCols-1)*self.nHelpers;
                runningCache(cacheIndexes) = transfers(isThisTimestamp,2);
                
                % report number may overflow its single-byte data type
                % estimate a more-significant-byte from transfer timestamp
                %   report number and timestamp -> time of 0th report
                %   so how many 0th reports should have passed by?
                %   or, to avoid rounding errors, how many 128th reports?
                %   both numbers correspond to the more-significant-byte
                numberLSB = ...
                    runningCache(cacheRows(1), self.sampleCountCookies);
                timeOfZeroth = timestamps(ii) - (numberLSB*reportInterval);
                timeOf128th = timeOfZeroth + overflowHalf;
                numberMSB = floor((timeOf128th-startTime)/overflowInterval);
                numberFixed = numberLSB + 256*numberMSB;
                
                %disp(sprintf('%d + 265*%d = %d', ...
                %    numberLSB, numberMSB, numberFixed))
                
                % relace cached report number with the fixed number
                runningCache(cacheRows(1), self.sampleCountCookies) = ...
                    numberFixed;
                
                % reconstruct samples from this updated cache
                [cNext, vNext, tNext, uNext, nNext] = ...
                    self.channelsFromCache(runningCache(cacheRows(1),:));
                c(nNext+1) = cNext;
                v(nNext+1) = vNext;
                t(nNext+1) = tNext;
                u(nNext+1) = uNext;
            end
        end
    end
    
    methods (Static)
        % Transfer buffered sample data and keep track of helper devices.
        function mexHIDQueueCallback(context, newData)
            dataTime = max(newData(:,3));
            newData(:,4) = context.cacheRow;
            context.transferredData(dataTime) = newData;
        end
    end
end