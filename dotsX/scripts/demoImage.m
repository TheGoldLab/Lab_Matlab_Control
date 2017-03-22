% demoImage

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania

try

    rInit('local');
    rAdd('dXimage', 1, 'file', 'flower1.bmp', 'visible', true)

    for ss = 0.1:0.01:3.5
        rSet('dXimage', 1, 'scale', ss);
        rGraphicsDraw;
    end
    for rr = 0:1:360
        rSet('dXimage', 1, 'rotationAngle', rr);
        rGraphicsDraw;
    end
    rDone;

catch
    rDone;
    rethrow(lasterror);
end