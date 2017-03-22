function [s, ax] = surfTable(data, rowNames, colNames, format, colorMap, textColor, ax)
%Plot data as a table, with colors provided by surf
%
%   [s, ax] = ...
%       surfTable(data, rowNames, colNames, format, colorMap, textColor, ax)
%
%   surfTable plots a table of data in some axes.  It shows text values for
%   each table entry, uses MATLAB's builtin surf function to make the
%   table itself.  surf gives the bonus of also showing color values for
%   table entries.
%
%   data is a two-dimensional array of table entries.
%
%   rowNames is the cell array of strings to use as lables for the table
%   rows.  length(rowNames) = size(data, 1).
%
%   colNames is the cell array of strings to use as lables for the table
%   columns.  length(colNames) = size(data, 2).
%
%   format is the optional format string passed to sprintf for printing
%   numeric values.  Default format is one decimal place: '%.1f'.  See
%   sprintf.
%
%   colorMap is optional.  It can be a boolean to say whether or not to
%   color the table entries by their values.  Default is true.  colorMap
%   can also be a string naming one of MATLAB's colormaps.  Default is the
%   green and yellow color map called "summer".  See colormap.
%
%   textColor is an optional ColorSpec that should look good against the
%   specified colorMap.  Default is black.
%
%   axes is an optional axes handle for plotting into.  Default is gca.
%
%   s is the handle of new surf object.
%
%   See also surf, sprintf, colormap

%   copyright 2008 by Benjamin Heasly at University of Pennsylvania.

if nargin < 4 || isempty(format) || ~ischar(format)
    format = '%.1f';
end

if nargin < 5 || isempty(colorMap)
    colorMap = true;
end

if nargin < 6 || isempty(textColor)
    textColor = [0 0 0];
end

if nargin < 7 || isempty(ax) || ~ishandle(ax)
    ax = gca;
end

% surf needs some padding on the top and left of the table
%   since it wants to think in terms of points, not spaces
rows = size(data, 1);
cols = size(data, 2);
padData = cat(2, zeros(rows+1,1), cat(1, zeros(1,cols), data));

% plot the padded table of data, colored with the original data
%   flip the surface so the 1st row is at the top
if ischar(colorMap)
    FaceColor = 'flat';
    colormap(colorMap);
elseif colorMap
    FaceColor = 'flat';
    colormap(summer);
else
    FaceColor = 'none';
end
s = surf(padData, data, 'Parent', ax, 'FaceColor', FaceColor);
view(ax, [0 -90])

% label the rows and columns
rowAxis = (1:rows)+.5;
colAxis = (1:cols)+.5;
set(ax, ...
    'YTick', rowAxis, 'XTick', colAxis, ...
    'YTickLabel', rowNames, 'XTickLabel', colNames, ...
    'YLim', [1,rows+1], 'XLim', [1,cols+1], ...
    'YAxisLocation', 'left', 'XAxisLocation', 'top', ...
    'YGrid', 'off', 'XGrid', 'off');

% put text in each table cell
for ii = 1:cols
    for jj = 1:rows
        str = sprintf(format, data(jj,ii));
        text(colAxis(ii)-.4, rowAxis(jj), str, ...
            'Color', textColor, 'Parent', ax);
    end
end