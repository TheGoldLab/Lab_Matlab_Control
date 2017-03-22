function [fig, axe, sur] = nDimVisualize(Y, YName, xDomains, xNames, xScales, point, face, obj)
% visualize a high-dimensional array with a sliding surface plot.
%
%   Y is an n-dimensional numeric array to be visualized.  The idea is: we
%   can easily plot a 3D surface, so we can easily view a cross section of
%   a higher-dimensional array.  Then, using sliders to represent other
%   dimensions, we can slide the plotted surface through different cross
%   sections of the same array.
%
%   Especially when Y represents a smooth function, this visualization
%   should facilitate good intuition about otherwise opaque functions,
%   datasets, etc.
%
%   Note that in this context, the number of dimensions, n, refers to the
%   number array subscripts required to access one element of Y.  For
%   example, the expression Y = f(x1,x2,x3) uses three independent
%   variables, so the dimensionalith here would be n=3--even though
%   Y = f(x1,x2,x3) can represent a 4-dimensional space.
%
%   YName is a string lable for the dependent variable Y.  If missing,
%   YName defaults to "Y"
%
%   xDomains is a cell array containing n vectors.  These are the domains
%   of the independent variables on which Y depends.  Thus, each
%   xDomains{i} should contain coordinate values for the iith dimension of
%   Y, and length(xDomains{i}) must equal size(Y,i).  If missing,
%   xDomains{i} defaults to [1:length(i)].
%
%   xNames is a cell array containing n strings.  Each xNames{i} should
%   contain a label for the ith independent variable on which Y depends.
%   If missing, xNames{ii} defaults to "x i".
%
%   xScales is a cell array of strings containing n strings.  Each
%   xScales{i} should contain either of the strings 'linear' or 'log',
%   specifying whether the ith independent variable should be plotten in
%   linear or log coordinates.  If missing, xScales defaults to all
%   'linear'.
%
%   point is a vector containing n indices, one for each dimension of Y,
%   specifying a single element of Y.  If missing, point defaults to all
%   ones.
%
%   face is a vector containing n boolean values, one for each dimension
%   of Y.  face should contain exactly 2 elements equal to true, and the
%   rest false.  These specify one of the 2-dimensional faces of Y.  If
%   missing, face defaults to the first two elements true.
%
%   Together, point and face specify the uniqe cross section of Y that
%   passes through point and is parallel to face.
%
%   obj is optional.  It may be the handle of a MATLAB figure, axes, or
%   surface object. If provided, nDimVisualize will use that object for
%   plotting. Otherwise, new graphics objects will be created.
%
%   fig, axe, and sur are the MATLAB graphics handles for the figure, axes
%   and surface objects that nDimVisualize used for plotting.
%
%   An Example (as seen in demoNDimVisualize.m):
%   
%   Imagine that Y is 4-dimensional array which represents a rocket's
%   predicted remaining fuel as a function of position and time.  Let each
%   x(i), y(j), and z(k) represent a positon coordinate, and each T(l)
%   represent some time value.  Then we can interpret any element of Y as
%       fuel = f(x(i), y(j), z(k), t(l)) = Y(i, j, k, l).
%
%   Also imagine that Y, x, y, z, and t are defined only at discrete
%   points.  For eample, let
%       {i: 1,2,...,10},
%       {j: 1,2,...,10},
%       {k: 1,2,...,20}, and
%       {l: 1,2,...,100}.
%   Then Y would be a 10 x 10 x 20 x 100 array and n=4.
%
%   Finally, imagine that we want to visualize a cross section of Y that
%   shows fuel vs. y and z, at medium values of x and t.  We could use
%   point and face to specify such a cross section:
%       point = [5 1 1 50], and 
%       face = [false true true false].
%   face selects the 2nd and 3rd dimensions of Y, which correspond to y and
%   z.  point selects the 5th element of the x domain and the 50th element
%   of the z domain. (It also selects the 1st elements of the y and z
%   domains, but these don't matter here because we're going to view all y
%   and z.)
%
%   nDimVisualize will combine point and face to make an indexing
%   expression for Y, as in
%       surface = Y(5,:,:,50),
%   and plot the inexed surface against the apropriate domain vectors,
%   x = xDomains{1} and t = xDomains{4}. 
%
%   You can select new values for x and t by sliding the sliders in the
%   lower left corner of the figure.  This slides the visualization through
%   multiple cross sections of Y.  You can also select a new plane of
%   section using the toggle buttons adjacent to the slider tools.
%
% See also figure, axes, surf, uicontrol, demoNDimVisualize

% Copyright 2008 Benjamin Heasly, University of Pennsylvania
%   benjamin.heasly@gmail.com

% check inputs: Y, YName, xDomains, xNames, point, face, obj
if ~nargin
    error('nDimVisualize requires an input array Y');
else
    h.Y = Y;
    h.nd = ndims(Y);
    h.sd = size(Y);
    if h.nd < 2
        error('Y is low-dimensional.  You don''t need to visualize it.')
    end
end

if nargin < 2 || isempty(YName) || ~ischar(YName)
    h.YName = 'Y';
else
    h.YName = YName;
end

if nargin < 3 || isempty(xDomains) || ~iscell(xDomains)
    for ii = 1:h.nd
        h.xDomains{ii} = 1:h.sd(ii);
    end
    h.xAllInds = h.xDomains;
else
    h.xDomains = xDomains;
    for ii = 1:h.nd
        h.xAllInds{ii} = 1:h.sd(ii);
    end
end

if nargin < 4 || isempty(xNames) || ~iscell(xNames)
    for ii = 1:h.nd
        h.xNames{ii} = sprintf('x_%d', ii);
    end
else
    h.xNames = xNames;
end

if nargin < 5 || isempty(xScales) || ~iscell(xScales)
    h.xScales = repmat({'linear'}, 1, h.nd);
else
    h.xScales = xScales;
end

if nargin < 6 || isempty(point) || ~isvector(point)
    h.point = ones(1,h.nd);
else
    h.point = point;
end

if nargin < 7 || isempty(face) || ~isvector(face)
    h.dimOne = 1;
    h.dimTwo = 2;
    h.face = logical(zeros(1,h.nd));
    h.face([h.dimOne, h.dimTwo]) = true;
else
    h.face = face;
    if sum(h.face) ~= 2
        error('face must contain exactly 2 elements equal to true')
    end
    h.dimOne = find(h.face, 1, 'first');
    h.dimTwo = find(h.face, 1, 'last');
end

if nargin < 8 || isempty(obj) || ~ishandle(obj)
    h.fig = figure;
    h.ax = axes('Parent', h.fig);
    h.surf = surf(1:2, 1:2, [1 1;1 1], 'Parent', h.ax);
else
    switch get(obj, 'Type');
        case 'surface'
            h.surf = obj;
            h.ax = get(h.surf, 'Parent');
            h.fig = get(h.ax, 'Parent');
        case 'axes'
            h.ax = obj;
            h.fig = get(h.ax, 'Parent');
            h.surf = surf(1:2, 1:2, [1 1;1 1], 'Parent', h.ax);
        case 'figure'
            h.fig = obj;
            clf(h.fig);
            h.ax = axes('Parent', h.fig);
            h.surf = surf(1:2, 1:2, [1 1;1 1], 'Parent', h.ax);
        otherwise
            error('input argument obj must be a surface, axes, or figure handle')
    end
end
set(h.fig, 'ToolBar', 'figure');
fig = h.fig;
axe = h.ax;
sur = h.surf;

% build the interface
set(h.ax, ...
    'Units', 'normalized', ...
    'Position', [0.11 0.25 0.8 0.7])
zlabel(h.ax, h.YName);

% make a row of tools for each dimension
for ii = 1:h.nd
    label = sprintf('%s = ', h.xNames{ii});
    tip = sprintf('drag for new %s', h.xNames{ii});
    val = h.xDomains{ii}(h.point(ii));

    % height of a row of tools
    ht = 20;

    % a slider to select new values on this dimension
    h.dSlide(ii) = uicontrol('Style', 'slider', 'Parent', h.fig, ...
        'Callback', {@uptadeDimension, ii}, ...
        'Max', h.sd(ii), 'Min', 1, ...
        'Units', 'pixels', 'Position', [5 ht*ii 390, ht-5], ...
        'TooltipString', tip, ...
        'SliderStep', [1/h.sd(ii) 10/h.sd(ii)], 'Value', h.point(ii));

    % a label to with the name of this dimension
    h.dLabel(ii) = uicontrol('Style', 'text', 'Parent', h.fig, ...
        'Units', 'pixels', 'Position', [400 ht*ii 70, ht-5], ...
        'String', label, 'TooltipString', tip, ...
        'HorizontalAlignment', 'right');

    % a label with the current value of this dimension
    h.dValue(ii) = uicontrol('Style', 'text', 'Parent', h.fig, ...
        'Units', 'pixels', 'Position', [470 ht*ii 50, ht-5], ...
        'String', val, 'TooltipString', tip, ...
        'HorizontalAlignment', 'left');

    % a toggle button for selecting the x-dimension
    h.dSelectOne(ii) = uicontrol('Style', 'toggleButton', 'Parent', h.fig, ...
        'Callback', {@selectDimension, ii, 'dimOne'}, ...
        'Units', 'pixels', 'Position', [525 ht*ii 15, ht-5], ...
        'String', [], 'TooltipString', 'select a dimension');

    % a toggle button for selecting the y-dimension
    h.dSelectTwo(ii) = uicontrol('Style', 'toggleButton', 'Parent', h.fig, ...
        'Callback', {@selectDimension, ii, 'dimTwo'}, ...
        'Units', 'pixels', 'Position', [540 ht*ii 15, ht-5], ...
        'String', [], 'TooltipString', 'select another dimension');
end

guidata(h.fig, h);

% put labeled data on the axes
drawNewDimensions(h.fig)

function drawNewDimensions(fig)
h = guidata(fig);

% unselect all the tools (lazy)
set([h.dSlide, h.dValue], 'Enable', 'on');
set([h.dSelectOne, h.dSelectTwo], 'Value', false);

% select the cross-section dimension's tools
set([h.dSelectOne(h.dimOne), h.dSelectTwo(h.dimTwo)], 'Value', true);

% gray-out the selected tools
set([h.dSlide(h.face), h.dValue(h.face)], 'Enable', 'off');

% build an indexing expression from point and face
h.iii = num2cell(h.point);
h.iii{h.dimOne} = h.xAllInds{h.dimOne};
h.iii{h.dimTwo} = h.xAllInds{h.dimTwo};

% plot new cross section surface
%   and label the new dimensions
xDim = max(h.dimOne, h.dimTwo);
yDim = min(h.dimOne, h.dimTwo);
set(h.surf, ...
    'XData', h.xDomains{xDim}, ...
    'YData', h.xDomains{yDim}, ...
    'ZData', squeeze(h.Y(h.iii{:})));
set(h.ax, ...
    'XLim', h.xDomains{xDim}([1,end]), 'XScale', h.xScales{xDim}, ...
    'YLim', h.xDomains{yDim}([1,end]), 'YScale', h.xScales{yDim});
xlabel(h.ax, h.xNames{xDim});
ylabel(h.ax, h.xNames{yDim});

drawnow
guidata(fig, h);

function selectDimension(obj, event, ii, plotDim)
h = guidata(obj);

if ii == h.(plotDim)

    % if unpressing a button thats already pressed, do repress
    set(obj, 'Value', true);

elseif ii == h.dimOne || ii == h.dimTwo

    % if pressing the other button for the same dimension, unpress
    set(obj, 'Value', false);

else

    % if pressing a new button, make a new cross section

    % deselect the old cross section dimension
    h.face(h.(plotDim)) = false;

    % select the new dimension for cross sectioning
    h.(plotDim) = ii;
    h.face(ii) = true;

    % update the graphics
    guidata(obj, h);
    drawNewDimensions(h.fig)
end

function uptadeDimension(obj, event, ii)
h = guidata(obj);

% get an index into one of the dimensions from the slider
%   remember the new point
%   update the indexing expression
xInd = round(get(h.dSlide(ii), 'Value'));
h.point(ii) = xInd;
h.iii{ii} = xInd;

% display the dimension value from the dimension's domain
set(h.dValue(ii), 'String', h.xDomains{ii}(xInd));

% show the new cross section
set(h.surf, 'ZData', squeeze(h.Y(h.iii{:})));
drawnow
guidata(obj, h);