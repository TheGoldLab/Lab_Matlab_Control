function drawableMouse_clickEvent()
clc;
clear all;

dotsTheScreen.reset('displayIndex', 0);

MouseDot = dotsDrawableVertices();
MouseDot.pixelSize = 10;

compMouse = dotsReadableHIDMouse();

xAxis = compMouse.components(1);
compMouse.setComponentCalibration(xAxis.ID, [], [], [-1 1]);
    
yAxis = compMouse.components(2);
compMouse.setComponentCalibration(yAxis.ID, [], [], [-1 1]);

click = compMouse.components(3);
compMouse.defineEvent(click.ID,'press',1,1,false)

compMouse.defineEvent(xAxis.ID,'hello!',1,10,false)

dotsTheScreen.openWindow;

while MouseDot.x <= 42
    
    compMouse.read();    
    dotsDrawable.drawFrame({MouseDot});
    MouseDot.x = compMouse.x;
    MouseDot.y = compMouse.y;
    [lastName, lastID, names, IDs] = compMouse.getHappeningEvent();
    if strcmp(lastName,'hello!');
        disp('There')
    end
    if strmatch('press', names);
        MouseDot.x = 43;
    end    
end
dotsTheScreen.closeWindow;    