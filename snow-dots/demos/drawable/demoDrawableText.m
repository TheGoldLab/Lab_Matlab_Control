% Demonstrate drawing strings of text, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableText(delay)

if nargin < 1
    delay = 0.3;
end

% get a drawing window
dotsTheScreen.reset();
dotsTheScreen.openWindow();

% create text objects
tx          = dotsDrawableText();
tx.string   = 'COUNTDOWN';
tx.color    = [0 .5 .25];
tx.isItalic = true;
tx.x        = -4;
tx.y        =  2;

tx2         = dotsDrawableText();
tx2.string  = '';
tx2.color   = [1 .1 .6];
tx2.isBold  = true;
tx2.y       = -2;

% collect the objects in a (cell) list
textList = {tx tx2};

% draw the text object with an arbitrary string and settings
for ii = 1:11
   
   textList{2}.string = sprintf('%d', 11-ii);   
   dotsDrawable.drawFrame(textList);
   pause(delay)
end

% close the OpenGL drawing window
dotsTheScreen.closeWindow();