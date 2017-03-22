% demonstrate plotting a table with the function surfTable.  This combines
% a regular looking table with the colors of a surf plot.

close all
clear all

% how about an arbitrary 3x2 array of data?
data = [ ...
    2 2; ...
    9 1; ...
    2 5; ...
    ];

% label the rows and columns
rowNames = {'even', 'decreasing', 'increasing'};
colNames = {'peak', 'valley', 'tot'};

% a format for printing number values: one decimal place
format = '%.1f';

% select whether to color the table entries by value
%   default colors are green and yellow from colormap 'summer'
colorMap = 'summernight';

% select a text color that will look good agains the chosen colormap
textColor = [1 0 0];

% get back handles to the surface plot and the axes created
[s, ax] = surfTable(data, rowNames, colNames, format, colorMap, textColor);