% Demonstrate TTL out/analog in for PMD device
% 
% Sending TTL out via channel 0: pins 12 (ground) and 13 (signal)
% Reading analong input via (differential) channel 0: pins 0 and 1
function demoPMD()

% Set up TTL output
dout = dotsWritableDOut1208FS();

% Set up analog input
ain = AInScan1208FS();
ain.channels = 0;
ain.gains = 2; % 2 = +-5V
ain.frequency = 1000;

% Set up and scan for 10 sec
ain.prepareToScan();
ain.startScan();

pause(0.1);

% Send several standard TTL pulses
nTTLs = 4;
pauseBetweenPulses = 0.2;
dout.sendTTLPulses(0, nTTLs, pauseBetweenPulses);
            
pause(0.3);

% % change voltages
numSteps = 10;
maxVals = round(linspace(25, 250, numSteps));
for ii = 1:numSteps
   pause(0.1);
   dout.pulseMax = maxVals(ii);
   dout.pulseWidth = 0.001*ii;
   dout.sendTTLPulse();
end
pause(0.1);

[c, v, t, ~] = ain.getScanWaveform(true);
Lc = c == 0;
ain.stopScan();
plot(t(Lc)-t(1),v(Lc), 'x-')
