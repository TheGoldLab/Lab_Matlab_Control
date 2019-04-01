function [data, kbr] = demoReadableHIDKeyboard(key, doMatch)
%
% Simple script to set up a keyboard object and wait for a particular
% keypress

%% Initialize the class
%
% Use certain matching properties to find a particular keyboard
if nargin >= 2 && doMatch
   matching.ProductID = 36;
   matching.VendorID = 1008;
else
   matching = [];
end

% Get the keyboard
kb = dotsReadableHIDKeyboard(matching);

% Wait to press key
if nargin < 1 || isempty(key)
   key = 'KeyboardJ';
elseif ~strncmp(key, 'Keyboard', 8)
   key = ['Keyboard' key];
end
   
[~, ~, data, kbr] = dotsReadableHIDKeyboard.waitForKeyPress(kb, key, 5, true);

