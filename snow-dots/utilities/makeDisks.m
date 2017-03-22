% Calculate x and y vertex positions for one or more disks.
% @param xCenter scalar or array of disk horizontal center positions
% @param yCenter scalar or array of disk vertical center positions
% @param rInner scalar or array of disk inner radiuses
% @param rOuter scalar or array of disk outer radiuses
% @param startAngle scalar or array of disk angular start locations
% @param sweepAngle scalar or array of disk angular sweep widths
% @param nPieces the number of sides for the disk approximation
% @details
% makeDisks() takes parameters that specify one or more circular disks and
% computes vertex x and y positions for each disk.  It also computes
% vertex indices which are suitable for drawing all the disks from
% quad primitives, with counterclockwise winding.
% @details
% @a xCenter, @a yCenter, @a rInner, and @a rOuter, may be scalars or
% arrays.  All arrays provided must have the same number of elements.
% Scalars will be expanded match any arrays.  The number of polygons
% created will match the number of array elements.
% @details
% Together, @a xCenter, @a yCenter, @a rInner, and @a rOuter specify two
% concentric circles with radiuses @rInner and @rOuter.  @a startAngle
% specifies where around each circle to start drawing a disk.  @a
% sweepAngle specifies how far around each circle to draw a disk.  @a
% startAngle and @a sweepAngle are interpreted as degrees, increasing
% counterclockwise, with 0 coinciding with the positive x-axis. @a
% sweepAngle may omitted, in which case complete disks will be drawn.
% @details
% @a nPieces specifies how coarsely or finely to approxomate disk curvature
% out of flat sides.  The larger nPieces, the more sides and the smoother
% the disks will appear.
% @details
% Returns x and y positions for one or more disks.  The number of
% rows of x and y will be equal to the number of vertices required to make
% up each disk, which is nPieces plus 1, times 2.  The number of
% columns of x and y will be equal to the number of disks.
% @details
% Also returns linear, 1-based indices into x and y, suitable for drawing
% all disks out of quad primitives.  The primitives will
% share some vertices.  The number of rows of indices will be 4.  The
% number of columns of indices will be the number of quads required to
% cover all disks, which is nPieces times the number of disks.
%
% @ingroup dotsUtilities
function [x, y, indices] = makeDisks(xCenter, yCenter, ...
    rInner, rOuter, startAngle, sweepAngle, nPieces)

if nargin < 3 || isempty(rInner)
    rInner = 1;
end

if nargin < 4 || isempty(rOuter)
    rOuter = 2;
end

if nargin < 5 || isempty(startAngle)
    startAngle = 0;
end

if nargin < 6 || isempty(sweepAngle)
    sweepAngle = 360;
end

if nargin < 7 || isempty(nPieces)
    nPieces = 30;
end

if nPieces < 1
    nPieces = 1;
end

% check for scalars and correct array sizes
lengths = [numel(xCenter), ...
    numel(yCenter), ...
    numel(rInner), ...
    numel(rOuter), ...
    numel(startAngle), ...
    numel(sweepAngle)];
nDisks = max(lengths);
if ~all((lengths == 1) | (lengths == nDisks))
    x = [];
    y = [];
    indices = [];
    return;
end

% get full-sized parameter matrices
verticesPerSweep = nPieces + 1;
verticesPerDisk = 2*verticesPerSweep;
param = zeros(1, nDisks);
param(:) = xCenter;
xMat = repmat(param, verticesPerDisk, 1);
param(:) = yCenter;
yMat = repmat(param, verticesPerDisk, 1);
param(:) = rInner;
innerMat = repmat(param, verticesPerSweep, 1);
param(:) = rOuter;
outerMat = repmat(param, verticesPerSweep, 1);
param(:) = startAngle;
startMat = repmat(param, verticesPerSweep, 1);
param(:) = sweepAngle;
sweeps = param;

% get vertex positions along the inner and outer circles
%   run counterclockwise around each disk edge
%   interleave inner and outer vertices
xVertex = zeros(verticesPerDisk, nDisks);
yVertex = zeros(verticesPerDisk, nDisks);
linSpacing = linspace(0, 1, verticesPerSweep);
radiansMat = startMat + linSpacing'*sweeps;
xVertex(1:2:end) = innerMat .* cosd(radiansMat);
xVertex(2:2:end) = outerMat .* cosd(radiansMat);
yVertex(1:2:end) = innerMat .* sind(radiansMat);
yVertex(2:2:end) = outerMat .* sind(radiansMat);

% move the disks to specified positions
x = xMat + xVertex;
y = yMat + yVertex;

% compute indices for drawing disks out of quads
%   walk through vertices in a staggered fashion
oneQuad = [1 2 4 3];
quadOffsets = 2*(0:(nPieces-1));
oneDisk = zeros(4, nPieces);
oneDisk(1,:) = oneQuad(1) + quadOffsets;
oneDisk(2,:) = oneQuad(2) + quadOffsets;
oneDisk(3,:) = oneQuad(3) + quadOffsets;
oneDisk(4,:) = oneQuad(4) + quadOffsets;

% use the same index scheme for all disks, with offsets
allDisks = repmat(oneDisk, 1, nDisks);
diskOffsets = verticesPerDisk*(ceil((1:(nPieces*nDisks))/nPieces) - 1);
offsetMat = repmat(diskOffsets, 4, 1);
indices = allDisks + offsetMat;
