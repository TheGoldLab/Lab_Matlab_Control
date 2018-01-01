% Demonstrate drawing strings of text, allow visual inspection.
%  with special formatting
%  
function demoDrawableText2(delay)

if nargin < 1
    delay = 0.3;
end

% get a drawing window
dotsTheScreen.reset();
dotsTheScreen.openWindow();

% create text objects
tx          = dotsDrawableText();
tx.string   = 'OOGA BOOGA';
tx.color    = [0 0.5 0.5];
tx.x        = -3;
tx.y        = 5;

for ii = 0:10:360
   
   tx.rotation = ii;   
   dotsDrawable.drawFrame({tx});
   pause(delay);
end

% close the OpenGL drawing window
dotsTheScreen.closeWindow();