% demonstrate high-dimensional visualization for differently dimensional
% arrays.

% Y = f(x1,x2)
%   This is the degenerate case of visualizing a 2-dimensional array.  The
%   visualization is successful, but the entire data set fits on a single
%   surface plot, so there is no higher-dimensional exploring to do.
x1 = 1:360;
x2 = -89:270;
Y_two = sind(x1)'*sind(x2);
nDimVisualize(Y_two, 'sin x cos', {x1,x2}, {'x1 (deg)', 'x2 (deg)'});

% Y = f(x,y,z,t)
%   This is a more interesting case of visualizing a 4-dimensional array.
%   At any time, two of the dimensions will be plotted on the surface, with
%   the other two dimensions held constant.  These constant values can be
%   changed with the sliders at the bottom of the figure.  Different
%   combinations of dimensions can be plotted.  Select with the buttons on
%   the bottom of the figure.

% make up some arbitrary independent variable domains
%   they can have different sizes
x = linspace(0,10,10);
y = linspace(-4,5,10);
z = linspace(-15,5,20);
t = linspace(0,1000,100);

% make up an arbitrary function for "predicted fuel remaining":
%   starting fuel - constant life support - cartesian distance traveled
%   fuel(x,y,z,t) = F0 -  - C*t(l) - ...
%       K*sqrt(x(i)^2 + y(j)^2 + z(k)^2)

% define these silly constants
F0 = 300;
C = .2;
K = 3;

% compute all predicted fuel values
Y_four = zeros(length(x), length(y), length(z), length(t));
for ii = 1:length(x)
    for jj = 1:length(y)
        for kk = 1:length(z)
            for ll = 1:length(t)
                Y_four(ii,jj,kk,ll) = F0 - C*t(ll) - ...
                    K*sqrt(x(ii).^2 + y(jj).^2 + z(kk).^2);
            end
        end
    end
end

% make lables for axes
YName = 'predicted fuel remaining';
xDomains = {x, y, z, t};
xNames = {'x pos', 'y pos', 'z pos', 'time'};

% start by viewing fuel vs all y and z, at medium values of x and t
point = [5 1 1 50];
face = [false, true, true, false];

% visualize the whole shebang
%   use figure 8, just for fun
%   zlim the axes, just for fun
[fig, ax, sur] = ...
    nDimVisualize(Y_four, YName, xDomains, xNames, point, face, figure(8));
set(ax, 'ZLim', [0, F0])