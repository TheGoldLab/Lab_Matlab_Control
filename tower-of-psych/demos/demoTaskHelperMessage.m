% Demo showing how to show simple messages using the topsTaskHelperMessage
% class

dotsTheScreen.openScreen(false, 0);

topsTaskHelperMessage.showTextMessage( ...
   {{'text1', 'fontSize', 20}, {'text2', 'color', [255 0 0]}}, ...
   'duration', 10)

dotsTheScreen.closeScreen();
