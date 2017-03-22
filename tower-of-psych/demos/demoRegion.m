% How to define regions in space with topsRegion, and view them.
%
% @ingroup topsDemos
function demoRegion()
close all

%% define 3 independent dimensions

% x ranges 1-100 and has 100 sample points
% y also ranges 1-100 and has 100 sample points
% z ranges 1-3 and has 3 sample points
dims(1) = topsDimension('x', 1, 100, 100);
dims(2) = topsDimension('y', 1, 100, 100);
dims(3) = topsDimension('z', 1, 3, 3);

% aggregate the dimensions into a space
%   the space happens to be like an RGB image
%   with 100x100 pixels and 3 color channels
space = topsSpace('image space', dims);

%% Define a rectangular region in the middle of the space

% the region will cover 50x50 pixels in the x-y plane
%   it will cut all the way through the z dimension
%   must assign the updated object to itself
middle = topsRegion('middle', space);
middle = middle.setRectangle('x', 'y', [25 25 50 50], 'in');

% view the space from the x-y plane
%   the z dimension is treated as RGB color
%   the "selector" is true in the rectangular region, so it appears white
subplot(2,2,1);
image(middle.selector);
title(sprintf('"%s" %s', middle.name, middle.description));

%% Define an edge region around the space
%   this region will be 10 pixels wide, all around x and y
%   it's an inverted rectangle
edge = topsRegion('edge', space);
edge = edge.setRectangle('x', 'y', [10 10 80 80], 'out');
subplot(2,2,2);
image(edge.selector);
title(sprintf('"%s" %s', edge.name, edge.description));

%% Define a ring region between the middle and the edge
%   this region is the gap between the middle and the edge
%   so take theur union, and invert the result
isInverted = true;
regions = [middle, edge];
ring = regions.combine('union', isInverted);
ring.name = 'ring';
subplot(2,2,3);
image(ring.selector);
title(sprintf('"%s" %s', ring.name, ring.description));

%% Define a slice through the z dimension, for color
%   the z dimension is perpendicular to the x-y viewing plane
%   it's treated as color
%   taking a slice out of the z dimension removes a color component
orange = topsRegion('orange', space);
orange = orange.setPartition('z', 3, '!=');

% color in the ring, by combining the orange region with the ring region
regions = [orange, ring];
orangeRing = regions.combine('intersection');
orangeRing.name = 'orange ring';
subplot(2,2,4);
image(orangeRing.selector);
title(sprintf('%s: %s', orangeRing.name, orangeRing.description));