% Calculate x and y vertex positions for one or more polygons.
% @param xCenter scalar or array of polygon horizontal center positions
% @param yCenter scalar or array of polygon vertical center positions
% @param width scalar or array of polygon widths
% @param height scalar or array of polygon heights
% @param nSides the number of sides for the polygons
% @param isInscribed whether to fit the polygon inside an oval
% @details
% makePolygons() takes parameters that specify one or more polygons and
% computes vertex x and y positions for each polygon.  It also computes
% vertex indices which are suitable for drawing all the polygons from
% triangle primitives, with counterclockwise winding.
% @details
% @a xCenter, @a yCenter, @a width, and @a height may be scalars or arrays.
% All arrays provided must have the same number of elements.  Scalars will
% be expanded match any arrays.  The number of polygons created will match
% the number of array elements.
% @details
% @a nSides specifies the type of polygon to create.  For example, nSides =
% 3 creates triangles, nSides = 11 eleven-sided polygons.  nSides must be
% at least 3.  If nSides it large, polygons will approximate ovals.  All
% polygons are rotated so that one side is flat on the bottom.
% @details
% Together, @a xCenter, @a yCenter, @a width, and @a height specify ovals
% which are aligned with the x and y axes.  By default, polygons are scaled
% so that each polygon circumscribes its oval.  This makes rectangles
% look right but triangles look very large.  If @a isInscribed is provided
% and equal to true, each polygon will be inscribed within its oval,
% instead of circumscribed.
% @details
% Returns x and y positions for the vertices one or more polygons.  The
% number of rows of x and y will be equal to nSides.  The number of columns
% of x and y will be equal to the number of polygons.
% @details
% Also returns linear, 1-based indices into x and y, suitable for drawing
% all polygons out of triangle primitives.  The primitives will
% share some vertices.  The number of rows of indices will be 3.  The
% number of columns of indices will be the number of triangles required to
% cover all polygons, which is nSides minus 2, times the number of
% polygons.
%
% @ingroup dotsUtilities
function [x, y, indices] = makePolygons(xCenter, yCenter, ...
    width, height, nSides, isInscribed)

if nargin < 3 || isempty(width)
    width = 1;
end

if nargin < 4 || isempty(height)
    height = 1;
end

if nargin < 5 || isempty(nSides)
    nSides = 3;
end

if nSides < 3
    nSides = 3;
end

if nargin < 6 || isempty(isInscribed)
    isInscribed = false;
end

% check for scalars and correct array sizes
lengths = [numel(xCenter), numel(yCenter), numel(width), numel(height)];
nPolygons = max(lengths);
if ~all((lengths == 1) | (lengths == nPolygons))
    x = [];
    y = [];
    indices = [];
    return;
end

% get full-sized parameter matrices
param = zeros(1, nPolygons);
param(:) = xCenter;
xMat = repmat(param, nSides, 1);
param(:) = yCenter;
yMat = repmat(param, nSides, 1);
param(:) = width;
wMat = repmat(param, nSides, 1);
param(:) = height;
hMat = repmat(param, nSides, 1);

% get vertex positions inscribed in the unit circle
%   orient with one side flat on the bottom
%   run counterclockwise around the polygon
vertexAngle = (2*pi/nSides);
isEven = mod(nSides, 2) == 0;
if isEven
    orientation = (pi/2) - (vertexAngle/2);
else
    orientation = pi/2;
end
rads = ((2*pi/nSides)*(1:nSides) + orientation)';
xVertex = cos(rads);
yVertex = sin(rads);
x = repmat(xVertex, 1, nPolygons);
y = repmat(yVertex, 1, nPolygons);

% scale the polygon to circumscribe the unit circle?
if isInscribed
    scribeScale = 0.5;
else
    sideSquared = 2-2*cos(vertexAngle);
    apothem = sqrt(1 - sideSquared/4);
    scribeScale = 0.5/(apothem);
end

% transform the unit circle for specified oval positions and dimensions
x = xMat + (x.*wMat.*scribeScale);
y = yMat + (y.*hMat.*scribeScale);

% compute indices for drawing polygons out of triangles
%   let all triangles share the first vertex of each polygon
%   walk through the remaining vertices in staggered fashion
trianglesPerPolygon = nSides-2;
nTriangles = trianglesPerPolygon*nPolygons;
onePolygon = zeros(3, trianglesPerPolygon);
onePolygon(1,:) = 1;
onePolygon(2,:) = 1 + (1:trianglesPerPolygon);
onePolygon(3,:) = 2 + (1:trianglesPerPolygon);

% use the same index scheme for all polygons, with offsets
allPolygons = repmat(onePolygon, 1, nPolygons);
polygonOffsets = nSides*(ceil((1:nTriangles)/trianglesPerPolygon) - 1);
offsetMat = repmat(polygonOffsets, 3, 1);
indices = allPolygons + offsetMat;
