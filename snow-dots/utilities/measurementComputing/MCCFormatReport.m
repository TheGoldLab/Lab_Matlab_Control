function report = MCCFormatReport(mcc, type, varargin)
%Get a formatted report to send to the 1208FS device.
%
%   type is a string describing the function of the report:
%
%   'AInSetup' means configure analog input channels:
%   MCCFormatReport(''AInSetup'', channels, gains);
%   channels is a vector of channels to scan (0-15)
%   gains is a vector specifying gain and input range for each channel
%	low precision, big range
%       0 -> 1x +-20V
%       1 -> 2x +-10V
%       2 -> 4x +-5V
%       3 -> 5x +-4V
%       4 -> 8x +-2.5V
%       5 -> 10x +-2V
%       6 -> 16x +-1.25V
%       7 -> 20x +-1V
%	high precision, small range
%
%   'AInScan' means start scanning analog inputs:
%   MCCFormatReport(''AInScan'', channels, frequency ...
%       [,sampleCount] [,externalTrigger] [,externalRetrigger]);
%   channels is a vector of channels to scan (0-15)
%   frequency is the scanning frequency for all channels
%   sampleCount is number of samples to get, then stop.  Default inf.
%   externalTrigger is boolean wait for external trigger.  Default false.
%   rexternalRetrigger is boolean trigger more than once.  Default false.
%
%   'AInStop' means stop scanning analog inputs
%
%   report.bytes is a vector of type uint8 containing configuration
%   information
%
%   report.ID is a scalar identifying the function of the report
%
%   report.type is a scalar:
%       1 means "input" report
%       2 means "output" report
%       3 means "feature" report
%
%   report.other is a struct of additional data, such as actual attainable
%   sample frequency, which may differ from a given frequency.
%
% This file is modified from the "dotsx" project for use with these
% "MCCSandbox" functions.  In the future Snow Dots should have its own
% utilities for formatting reports for the MCC 1208FS device and other
% devices.
%
% Benjamin Heasly 2007 University of Pennsylvania
% Benjamin Heasly 2010 University of Washington/Howard Hughes Medical
% Institute
% Report formats stolen without shame from Psychtoolbox Daq* functions.


switch type
    
    case 'Reset'
        report.ID = 65;
        report.bytes = uint8(report.ID);
        report.type = 2;
        
    case 'AInSetup'
        % which channels?
        ch = varargin{1};
        cTotal=length(ch);
        
        % what gain and range for each channel?
        g = varargin{2};
        
        % report metadata
        report.ID = 19;
        report.type = 2;
        
        % set gain "0" for single-ended channels
        isDiff = ch < 8;
        g(~isDiff) = 0;
        
        % format the report
        report.bytes = uint8(zeros(1, 2+2*cTotal));
        report.bytes(1) = report.ID;
        report.bytes(2) = cTotal;
        for ii=1:cTotal
            report.bytes(2*ii+1)=ch(ii);
            report.bytes(2*ii+2)=g(ii);
        end
        
        % report gain "1" for single-ended channels
        g(~isDiff) = 1;
        
        % differential channels interpreted as int16
        % single-ended channels masked to 10 bits, shifted +1
        byteMasks = 255*ones(mcc.bytesPerSample, cTotal);
        byteMasks(:,~isDiff) = repmat([255; 63], 1, sum(~isDiff));
        
        byteShifts = zeros(mcc.bytesPerSample, cTotal);
        byteShifts(:,isDiff) = repmat([0; 8], 1, sum(isDiff));
        byteShifts(:,~isDiff) = repmat([1; 9], 1, sum(~isDiff));
        
        % magic knowledge of how to convert samples to ints and volts
        channelGain = [1 2 4 5 8 10 16 20];
        intToVoltScale = 20/mcc.sampleIntMagnitude;
        
        % how to scale each gain to volts
        voltScale(1+ch) = intToVoltScale./channelGain(g+1);
        report.other.voltScale = voltScale;
        report.other.voltMax = mcc.sampleIntMagnitude*voltScale;
        report.other.voltMin = -mcc.sampleIntMagnitude*voltScale;
        report.other.byteMasks(:,1+ch) = byteMasks;
        report.other.byteShifts(:,1+ch) = byteShifts;
        
    case 'AInScan'
        % which channels?
        ch = varargin{1};
        cTotal=length(ch);
        
        % what scanning frequency?
        f = varargin{2};
        fTotal = cTotal*f;
        
        % how many samples?
        if nargin < 5 || isempty(varargin{3})
            n = inf;
        else
            n = varargin{3};
        end
        nTotal = cTotal*n;
        
        % using external trigger?
        if nargin < 6 || isempty(varargin{4})
            useTrigger = false;
        else
            useTrigger = varargin{4};
        end
        useTrigger = logical(useTrigger);
        
        % reuse external trigger?
        if nargin < 7 || isempty(varargin{5})
            reuseTrigger = false;
        else
            reuseTrigger = varargin{5};
        end
        reuseTrigger = logical(reuseTrigger);
        
        % the Daq has a 10 Megahertz timer
        % prescale is exponent of how much to decrement a counter at each
        % tic (decrement = 2^-prescale)
        prescale = ceil(log2(10e6/65535/fTotal));
        prescale = max(0,min(8,prescale));
        
        % preload is a number from which to count down before sampling
        preload = round(10e6/2^prescale/fTotal)-1;
        preload = max(0,min(65535,preload));
        
        % calculate attainable sample frequency from timer parameters
        fTotalActual=10e6/2^prescale/preload;
        fActual = fTotalActual/cTotal;
        
        % report metadata
        report.type = 2;
        report.ID = 17;
        
        % format the report
        report.bytes=uint8(zeros(1,11));
        report.bytes(1)=report.ID;
        
        % read 32-bit integer into 4 report bytes
        if isfinite(nTotal)
            bits = nTotal;
            report.bytes(4) = bitand(bits, 255);
            bits = bitshift(bits, -8);
            report.bytes(5) = bitand(bits, 255);
            bits = bitshift(bits, -8);
            report.bytes(6) = bitand(bits, 255);
            bits = bitshift(bits, -8);
            report.bytes(7) = bitand(bits, 255);
        end
        report.bytes(8) = prescale;
        report.bytes(9) = bitand(preload, 255);
        report.bytes(10) = bitshift(preload,-8);
        
        % assemble last byte from various options
        queue = true;
        report.bytes(11) = ...
            isfinite(nTotal) + 4*useTrigger ...
            +16*queue + 32*reuseTrigger;
        
        report.other.nChans = cTotal;
        report.other.totalFrequency = fTotal;
        report.other.totalSamples = nTotal;
        report.other.attainedFrequency = fActual;
        report.other.attainedTotalFrequency = fTotalActual;
        report.other.attainedSampleInterval = 1/fTotalActual;
        
    case 'AInStop'
        report.ID = 18;
        report.type = 2;
        report.bytes = uint8(report.ID);
        
    case 'AOut'
        channel = varargin{1};
        value = varargin{2};
        littleByte = mod(value, 256);
        bigByte = floor(value/256);
        
        report.ID = 20;
        report.type = 2;
        report.bytes = uint8([report.ID, channel, littleByte, bigByte]);
        
    case 'AOutScan'
        
        
    case 'DOut'
        channel = varargin{1};
        value = varargin{2};
        byte = mod(value, 256);
        
        report.ID = 4;
        report.type = 2;
        report.bytes = uint8([report.ID, channel, byte]);
        
    case 'DSetup'
        channel = varargin{1};
        IO = varargin{2};
        isInput = strcmp(IO, 'input');
        
        report.ID = 1;
        report.type = 2;
        report.bytes = uint8([report.ID, channel, isInput]);
        
    otherwise
        disp(sprintf('unknown report type, "%s"', type))
        report.bytes = uint8([]);
        report.type = [];
        report.ID = [];
end