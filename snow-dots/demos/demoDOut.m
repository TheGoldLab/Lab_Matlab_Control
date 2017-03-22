% Demonstrate locating and using a dotsAllDOut object for this system.
%
% @ingroup dotsDemos
function demoDOut()

% Find the digital output implementation correct for this machine
%   and create an instance
dOutClassName = ...
    dotsTheMachineConfiguration.getDefaultValue('dOutClassName');
dOutObject = feval(dOutClassName);

% an pick arbitrary digital word to send from the 0th output port
word = 124;
port = 0;
timestamp = dOutObject.sendStrobedWord(word, port);

% send short "high-low" pulses of TTL-level voltage from each of two output
% ports (if available)
timestamp = dOutObject.sendTTLPulse(0);
timestamp = dOutObject.sendTTLPulse(1);

% specify an arbitrary sequence of TTL-level voltages to output.  True
% corresponds to "high" and false to "low".
signal = 1:100 > 25;
signal(end) = false;

% output the whole sequence of TTL-level voltages from each of two output
% ports (if available).  Use different arbitrary sample output frequencies
% to output the same sequence at different rates.
frequency = 100;
timestamp = dOutObject.sendTTLSignal(0, signal, frequency);
frequency = 1000;
timestamp = dOutObject.sendTTLSignal(1, signal, frequency);