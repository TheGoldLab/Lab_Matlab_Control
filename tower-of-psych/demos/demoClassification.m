% How to classify data based on a spatial model.
%
% @ingroup topsDemos
function demoClassification()

% query dimensions of primary display
monitorRects = get(0, 'MonitorPositions');
primaryRect = monitorRects(1,:);
x = primaryRect(1);
y = primaryRect(2);
w = primaryRect(3);
h = primaryRect(4);

% topsClassification will map curosr position to arbitrary outputs
classn = topsClassification('cursor position');

% define the monitor space and how to access x and y position
nPoints = 100;
classn.addSource('x', @getCursorX, x, x+w, nPoints);
classn.addSource('y', @getCursorY, y, y+h, nPoints);

%% define 5 regions of the cursor space: four corners and the center
bl = topsRegion('bottomLeft', classn.space);
bl = bl.setRectangle('x', 'y', [x y w/2 h/2], 'in');

br = topsRegion('bottomRight', classn.space);
br = br.setRectangle('x', 'y', [x+w/2 y w/2 h/2], 'in');

tl = topsRegion('topLeft', classn.space);
tl = tl.setRectangle('x', 'y', [x y+h/2 w/2 h/2], 'in');

tr = topsRegion('topRight', classn.space);
tr = tr.setRectangle('x', 'y', [x+w/2 y+h/2 w/2 h/2], 'in');

m = topsRegion('middle', classn.space);
m = m.setRectangle('x', 'y', [x+w/4 y+h/4 w/2 h/2], 'in');

%% map each region to an arbitrary output
classn.addOutput(bl.name, bl, 'This is the bottom-left.');
classn.addOutput(br.name, br, 'This is the bottom-right.');
classn.addOutput(tl.name, tl, 'This is the top-left.');
classn.addOutput(tr.name, tr, 'This is the top-right.');
classn.addOutput(m.name, m, 'Stuck in the middle with you!');

%% now classify data for a while
f = figure( ...
    'Name', '', ...
    'NumberTitle', 'off', ...
    'ToolBar', 'none', ...
    'MenuBar', 'none');
while ishandle(f)
    [output, outputName] = classn.getOutput();
    set(f, 'Name', [outputName ': ' output])
    drawnow();
end


%% handy functions referenced above
function x = getCursorX()
pos = get(0, 'PointerLocation');
x = pos(1);

function y = getCursorY()
pos = get(0, 'PointerLocation');
y = pos(2);