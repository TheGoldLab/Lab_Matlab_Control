% Demonstrate drawing strings of text, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableText(delay)

if nargin < 1
    delay = 2;
end

% get a drawing window
dotsTheScreen.reset();
dotsTheScreen.openWindow();

% create a text object
tx = dotsDrawableText();
tx2 = dotsDrawableText();
tx2.string = 'hello';
tx2.color = [250 25 250];
% draw the text object with an arbitrary string and settings
tx.string = 'Juniper juice';
tx.color = [0 128 64];
dotsDrawable.drawFrame({tx tx2});
pause(delay)

% close the OpenGL drawing window
dotsTheScreen.closeWindow();