function demoReadableHIDKeyboard(key, matching, timeout)
%
% Simple script to set up a keyboard object and wait for a particular
% keypress

% Wait to press key
if nargin < 1 || isempty(key)
   key = 'KeyboardJ';
elseif ~strncmp(key, 'Keyboard', 8)
   key = ['Keyboard' key];
end
   
% Use certain matching properties to find a particular keyboard
% e.g., 
%   matching.ProductID = 36;
%   matching.VendorID = 1008;
if nargin < 2
   matching = [];
end

if nargin < 3 || isempty(timeout)
   timeout = 10;
end

% Get the keyboard
kb = dotsReadableHIDKeyboard(matching);

disp(sprintf('press <%s> on the primary keyboard', key(end)))
didHappen = dotsReadableHIDKeyboard.waitForKeyPress(kb, key, timeout, true);
if didHappen
   disp('Got it!');
else
   disp('Nope');
end


% Try to get a secondary keyboard
kb2 = dotsReadableHIDKeyboard(2);
disp(sprintf('press <%s> on the secondary keyboard', key(end)))
didHappen = dotsReadableHIDKeyboard.waitForKeyPress(kb2, key, timeout, true);
if didHappen
   disp('Got it!');
else
   disp('Nope');
end
