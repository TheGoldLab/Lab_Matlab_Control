function drawableMouse()
% description in this wiki:
% https://github.com/TheGoldLab/Lab-Matlab-Control/wiki/Building-a-sample-experiment-Part-2---Target-to-Mouse-wiring

% personal comments: This code doesn't work perfectly on my computer.
% In particular: 1/ mouse position doesn't always get linked to whtie
% square on screen; 2/ the window doesn't close automatically, even when
% moving the mouse to the far left.
clc;
clear all;

dotsTheScreen.reset('displayIndex', 0);

MouseDot = dotsDrawableVertices();
MouseDot.pixelSize = 10;

compMouse = dotsReadableHIDMouse();

xAxis = compMouse.components(1);
compMouse.setComponentCalibration(xAxis.ID, [], [], [-10 10]);
    
yAxis = compMouse.components(2);
compMouse.setComponentCalibration(yAxis.ID, [], [], [-10 10]);

dotsTheScreen.openWindow;

while MouseDot.x <= 42
    
    compMouse.read();    
    dotsDrawable.drawFrame({MouseDot});
    MouseDot.x = compMouse.x;
    MouseDot.y = -compMouse.y;
end

dotsTheScreen.closeWindow;