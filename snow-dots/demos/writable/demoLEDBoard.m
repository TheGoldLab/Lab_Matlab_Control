function demoLEDBoard
% function demoLEDBoard
% Demonstrate the LED board
%

d = dotsWritableDOutArduinoLEDs();

LEDs = {'center', 'left', 'top', 'right', 'bottom'};
colors = {'r' 'g' 'b'};

for ii = 1:length(colors)
   for jj = 1:length(LEDs)
      disp(sprintf('LED <%s>, color <%s>', LEDs{jj}, colors{ii}))
      d.toggleLED(LEDs{jj}, colors{ii}, 1);
      pause(0.5);
      d.toggleLED(LEDs{jj}, colors{ii}, 0);
   end
   pause(0.2);
end