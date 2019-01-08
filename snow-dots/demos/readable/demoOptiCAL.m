% Demonstrate reading luminance values from the optiCAL device
%
% opticalSerial assumes that the device is connected via a USB-serial
% connection that is accessible at /dev/tty.USA*

% open up the optiCAL device
OP = opticalSerial(optiCAL);

% take luminance readings
numberOfSamplesToRead = 10;
pauseBetweenSamples = 1; % sec
OP.getLuminance(numberOfSamplesToRead, pauseBetweenSamples);

% get the samples
samples = OP.values;

% close the optiCAL device
OP.close();