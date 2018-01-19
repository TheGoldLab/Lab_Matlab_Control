classdef opticalSerial < handle    
    % optiCAL handle class for communicating
    %   with the optiCAL photometer using the 
    %   MATLAB "serial" command.
    %
    %   Assumes the optiCAL device is connected to
    %   the computer using a USB-serial converter;
    %   e.g., KEYSPAN USA-19HS
    %
    %   OptiCAL communicates via a standard RS-232 serial
    %   port, using the protocol: 9600 baud rate, no parity, and
    %   1 stop bit
    %
    % /dev/tty.USA19H62P1.1

    properties (SetAccess = private)
        
        % the serial port object
        serialObject = [];
        
        % the serial port name
        portName = '/dev/tty.USA19H62P1.1';
        
        % Acknowledge byte
        ack = uint8(6);
        
        % Baud rate for serial
        baudRate = 9600;
        
        % Data bits for serial
        dataBits = 8;
        
        % Stop bits for serial
        stopBits = 1;
        
        % Timeout for serial queries, in ms
        timeout = 5;
                
        % Product type
        % Not used
        productType = 0;
        
        % Optical Serial Number
        % Not used
        opticalSN = 0;
        
        % Firmware version
        % Not used
        firmwareVersion = 0;

        % Reference Voltage (V_ref) in uV
        % Used to compute Luminance/Voltage
        vRef = 0;
        
        % Zero error in ADC counts
        % Used to compute Luminance/Voltage
        zCount = 0;
        
        % Feedback resistor in ohms
        % Used to compute Luminance/Voltage
        rFeed = 0;
        
        % Votage gain resistor in ohms
        % Used to compute Luminance/Voltage
        rGain = 0;
        
        % Probe Serial Number
        % ASCII 16 characters
        % Not used
        probeSN = '';
        
        % Probe calibration in fA/cd/m^2
        % Used to compute Luminance/Voltage
        kCal = 0;
        
        % mode = 'current' or 'voltage'
        mode = '';
        
        % useful variables for luminance calculation
        lcDenom;
        lcScale;
        
        % most recent values
        values = [];

    end
    
    methods
        
        % Get the optiCAL object
        %   open and initialize
        function OP = opticalSerial(portName)
            
            if nargin >= 1 && ~isempty(portName)
                OP.portName = portName;
            end
            
            % open the port
            OP.serialObject = serial(...
                OP.portName, ...
                'BaudRate', OP.baudRate, ...
                'DataBits', OP.dataBits, ...
                'StopBits', OP.stopBits, ...
                'Timeout',  OP.timeout);

            % open the port
            fopen(OP.serialObject);

            % Calibrate
            %
            % send command and wait a few seconds
            %   for ACK return value
            fprintf(OP.serialObject, '%s', 'C');
            tic
            ret = 0;
            while toc < 5 && ret ~= OP.ack
                ret = fread(OP.serialObject, 1, 'uint8');
            end
            if ret ~= OP.ack
                disp('Calibration NOT successful')
            end

            % Read info from device
            out = zeros(2,16,'uint8');

            % product type (2 bytes)
            for bb = 1:2
                fprintf(OP.serialObject, '%s', char(128+bb-1));
                out(:,bb) = fread(OP.serialObject, 2, 'uint8');
            end
            OP.productType = typecast(out(1,1:2), 'uint16');

            % serial number (4 bytes)
            for bb = 1:4
                fprintf(OP.serialObject, '%s', char(128+bb+1));
                out(:,bb) = fread(OP.serialObject, 2, 'uint8');
            end
            OP.opticalSN = typecast(out(1,1:4), 'uint32');

            % firmware version number*100 (2 bytes)
            for bb = 1:2
                fprintf(OP.serialObject, '%s', char(128+bb+5));
                out(:,bb) = fread(OP.serialObject, 2, 'uint8');
            end
            OP.firmwareVersion = double(typecast(out(1,1:2), 'uint16'))./100.;

            % VREF = Reference voltage (4 bytes)
            for bb = 1:4
                fprintf(OP.serialObject, '%s', char(128+bb+15));
                out(:,bb) = fread(OP.serialObject, 2, 'uint8');
            end
            OP.vRef = typecast(out(1,1:4), 'uint32');
            
            % ZCOUNT = zero error (4 bytes)
            for bb = 1:4
                fprintf(OP.serialObject, '%s', char(128+bb+31));
                out(:,bb) = fread(OP.serialObject, 2, 'uint8');
            end
            OP.zCount = typecast(out(1,1:4), 'uint32');

            % RFEED = feedback resistor (4 bytes)
            for bb = 1:4
                fprintf(OP.serialObject, '%s', char(128+bb+47));
                out(:,bb) = fread(OP.serialObject, 2, 'uint8');
            end
            OP.rFeed = typecast(out(1,1:4), 'uint32');

            % RGAIN = voltage gain resistor (4 bytes)
            for bb = 1:4
                fprintf(OP.serialObject, '%s', char(128+bb+63));
                out(:,bb) = fread(OP.serialObject, 2, 'uint8');
            end
            OP.rGain = typecast(out(1,1:4), 'uint32');

            % probe serial number (ASCII 16 characters)
            for bb = 1:16
                fprintf(OP.serialObject, '%s', char(128+bb+79));
                out(:,bb) = fread(OP.serialObject, 2, 'uint8');
            end
            OP.probeSN = char(out(1,1:16));

            % KCAL = probe calibration (4 bytes)
            for bb = 1:4
                fprintf(OP.serialObject, '%s', char(128+bb+95));
                out(:,bb) = fread(OP.serialObject, 2, 'uint8');
            end
            OP.kCal = typecast(out(1,1:4), 'uint32');

            % for luminance calculation
            OP.lcDenom = double(OP.kCal)*double(OP.rFeed)*(1e-15);
            OP.lcScale = double(OP.vRef)*(1e-6);
        end
        
        % set to current or voltage mode
        function setMode(self, mode)
            
            if isempty(self.serialObject)
                disp('setMode: no object')
                return
            end
            
            if strcmp(mode, self.mode)
                return
            end
            
            if strcmp(mode, 'current')
                fprintf(self.serialObject, '%s', 'I');
            elseif strcmp(mode, 'voltage')
                fprintf(self.serialObject, '%s', 'V');
            else
                disp(sprintf('setMode: unknown mode (%s)', mode))
                return
            end
            
            if fread(self.serialObject, 1, 'uint8') ~= self.ack
                disp(sprintf('setMode: could not set to %s', mode))
            end
            self.mode = mode;            
        end
        
        % get luminance reading
        function getLuminance(self, numSamples, pauseBetweenSamples)
        
            % Put into current mode, if necessary
            if ~strcmp(self.mode, 'current')
                setMode(self, 'current');
            end
    
            % read data
            if nargin < 2 || isempty(numSamples)
                numSamples = 1;
            end
            if nargin < 3 || isempty(pauseBetweenSamples)
                pauseBetweenSamples = 0.1; % in seconds
            end
            
            self.values = nan.*zeros(numSamples, 1);
            out         = zeros(4,1,'uint8');
            
            for ii = 1:numSamples

                fprintf(self.serialObject, '%s', 'L');
                out(:) = fread(self.serialObject, 4, 'uint8');
                self.values(ii) = (((double(typecast([out(1:3)' uint8(0)], 'uint32') - ...
                    self.zCount - 524288))/524288.)*self.lcScale)/self.lcDenom;
                % disp(self.values(ii))
                pause(pauseBetweenSamples)
            end
        end
        
        % close the serial port
        function close(self)
            fclose(self.serialObject);
            self.serialObject = [];
        end
    end
end
