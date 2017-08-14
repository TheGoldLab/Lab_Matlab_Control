%Add compMouse.flushData to 'prepare' state's exit stateField to get the
%target back to 0 and remove user swipes

compMouse = dotsReadableHIDMouse();
xAxis = compMouse.components(1);
compMouse.setComponentCalibration(xAxis.ID, [], [], [-5 5]);
click = compMouse.components(3);
compMouse.defineEvent(click.ID,'press',1,1,false)
list{'mousemouse'}{'mouse'} = compMouse;

function next_state_ = positionBall(list)

next_state_ = 'position';
drawables = list{'graphics'}{'drawables'};
gTI = list{'graphics'}{'target index'};
compMouse = list{'mousemouse'}{'mouse'};
if true    
    compMouse.read();
    [names] = compMouse.getHappeningEvent()                        
    if compMouse.x >= 6
        compMouse.x = 6;
    elseif compMouse.x <= -6
        compMouse.x = -6;
    end
    drawables.setObjectProperty('x', compMouse.x, gTI);    
        if strmatch('press', names)            
            next_state_ = 'set';           
        end
end