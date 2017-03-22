% demoPolygon.m
%
% demo graphcs class dXpolygon 
%

% Copyright 2008 by Joshua I. Gold
%   University of Pennsylvania

try
    % change priority (using Priority(<value0-9>)) to change
    %   the priority of the process and speed things up
    rInit({'screenMode', 'local', 'showWarnings', false});

    rAdd('dXpolygon', 3, 'visible', true, ...
        'color', {[255,0,0], [0,255,0], [0,0,255]}, ...
        'pointList', {[-3 -3; 3 -3; 0 3], [-2 -2; 2 -2; 0 2], [-1 -1; 1 -1; 0 1]});
   
    rGraphicsDraw(2000);
    rGraphicsBlank;
    rDone;
catch
    e = lasterror
    rDone;
end
