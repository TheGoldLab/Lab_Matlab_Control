%% demoReadableHIDKeyboard
%
% Simple script to set up a keyboard object and wait for a particular
% keypress

%% Initialize the class
%
% Use certain matching properties to find a particular keyboard
doMatch = false;

if doMatch
   matching.ProductID = 36;
   matching.VendorID = 1008;
else
   matching = [];
end

% Get the keyboard
kb = dotsReadableHIDKeyboard(matching);

% Wait to press "J" key
[isPressed, waitTime, data, kb] = dotsReadableHIDKeyboard.waitForKeyPress(kb, 'KeyboardJ', 5, true)

