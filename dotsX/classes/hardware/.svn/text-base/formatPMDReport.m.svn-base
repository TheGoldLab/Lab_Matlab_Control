function [report, reportID reportType] = formatPMDReport(type, varargin)
%Get a formatted HID report to send to the 1208FS device.
%
%   type is a string describing the function of the report:
%
%   'AInSetup' means configure analog input channels:
%   formatPMDReport(''AInSetup'', channels, gains);
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
%   formatPMDReport(''AInScan'', channels, frequency ...
%       [,sampleCount] [,externalTrigger] [,externalRetrigger]);
%   channels is a vector of channels to scan (0-15)
%   frequency is the scanning frequency for all channels
%   sampleCount is number of samples to get, then stop.  Default inf.
%   externalTrigger is boolean wait for external trigger.  Default false.
%   rexternalRetrigger is boolean trigger more than once.  Default false.
%
%   'AInStop' means stop scanning analog inputs
%
%   report is a vector of type uint8 containing configuration information
%
%   reportID is a scalar identifying the function of the report
%
%   reportType is a scalar:
%       1 means "input" report
%       2 means "output" report
%       3 means "feature" report
%
% Report formats stolen without shame from Psychtoolbox Dac* functions

% Benjamin Heasly 2007 University of Pennsylvania

switch type
    
    case 'Reset'
        reportID = 65;
        report = uint8(reportID);
        reportType = 2;

    case 'AInSetup'
        if nargin < 3
            error('formatPMDReport(''AInSetup'', channels, gains);');
        end
        
        % which channels?
        ch = varargin{1};
        cTotal=length(ch);

        % what gain and range for each channel?
        g = varargin{2};

        % report metadata
        reportID = 19;
        reportType = 2;
        
        % format the report
        report = uint8(zeros(1, 2+2*cTotal));
        report(1) = reportID;
        report(2) = cTotal;
        for ii=1:length(ch)
            report(2*ii+1)=ch(ii);
            report(2*ii+2)=g(ii);
        end

    case 'AInScan'
        if nargin < 3
            error('formatPMDReport(''AInScan'', channels, frequency [,sampleCount] [,externalTrigger] [,externalRetrigger]);');
        end

        % which channels?
        ch = varargin{1};
        cTotal=length(ch);

        % what scanning frequency?
        f = varargin{2};
        fTotal = cTotal*f;

        % how many samples?
        if nargin < 4 || isempty(varargin{3})
            n = inf;
        else
            n = varargin{3};
        end
        nTotal = cTotal*n;

        % using external trigger?
        if nargin < 5 || isempty(varargin{4})
            useTrigger = false;
        else
            useTrigger = varargin{4};
        end
        useTrigger = logical(useTrigger);
        
        % reuse external trigger?
        if nargin < 6 || isempty(varargin{5})
            reuseTrigger = false;
        else
            reuseTrigger = varargin{5};
        end
        reuseTrigger = logical(reuseTrigger);
        
        % the Daq has a 10 Megahertz timer
        % prescale is exponent of how much to decrement a counter at each
        % tic (decrement = 2^prescale)
        prescale = ceil(log2(10e6/65535/fTotal));
        prescale = max(0,min(8,prescale));

        % preload is a number from which to count down before sampling
        preload = round(10e6/2^prescale/fTotal);
        preload = max(1,min(65535,preload));

        % calculate attainable sample frequency from timer parameters
        fTotalActual=10e6/2^prescale/preload;
        fActual = fTotalActual/cTotal;

        % report metadata
        reportType = 2;
        reportID = 17;
        
        % format the report
        report=uint8(zeros(1,11));
        report(1)=reportID;
        
        % read 32-bit integer into 4 report bytes
        if isfinite(nTotal)
            bits = nTotal;
            report(4) = bitand(bits, 255);
            bits = bitshift(bits, -8);
            report(5) = bitand(bits, 255);
            bits = bitshift(bits, -8);
            report(6) = bitand(bits, 255);
            bits = bitshift(bits, -8);
            report(7) = bitand(bits, 255);
        end
        report(8) = prescale;
        report(9) = bitand(preload, 255);
        report(10) = bitshift(preload,-8);
        
        % assemble last byte from various options
        queue = true;
        report(11) = ...
            isfinite(nTotal) + 4*useTrigger ...
            +16*queue + 32*reuseTrigger;
    case 'AInStop'
        reportID = 18;
        reportType = 2;
        report = uint8(reportID);

    otherwise
        disp(sprintf('unknown report type, "%s"', type))
        report = uint8([]);
        reportType = [];
        reportID = [];
end