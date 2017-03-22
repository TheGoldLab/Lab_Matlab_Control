% Get a colormap with evenly-spaced colors that show up against white.
% @param n the length of colormap to build
% @details
% Returns an nX3 colormap with rows of the form [R G B], and components in
% the range 0-1.
% @details
% Here's how spacedColors() picks evenly-spaced colors that show up against
% white: it uses a cube with sides in the interval [0 1].  It treats each
% cube dimension as a color component.  Thus, any point in the cube can be
% interpreted as an RGB color.
% @details
% Colors near the [1 1 1] corner will be close to white, so they won't show
% up against a white background.  spacedColors() truncates the cube by
% cutting off points near [1 1 1].  It picks @a n colors from the rest of
% the cube, by taking evenly-spaced strides.  The smaller @a n, the greater
% the spacing between colors.
% @details
% Here's a demo:
% @code
% n = 12;
% colormap([spacedColors(n); 1 1 1]);
% thingy = n+1*ones(1, 2*n+1);
% thingy(2:2:2*n) = 1:n;
% image(thingy);
% @endcode
%
% @ingroup topsUtilities
function colors = spacedColors(n)

if nargin < 1
   n = size(get(gcf,'colormap'),1);
end

% define a whiteness index, w = r + g + b, 
%   want to exclude colors with w > some k
%   this is monotonic with the area of excluded cube,
%   which is equivalent to some % of colors
%   so I'll just generate sufficient extra colors
%   and exclude the whitest of them
pExclude = .8;

% define color distance as d = (r1-r2)^2 + (g1-g2)^2 + (b1-b2)^2,
%   want to maxmize the smallest d among the n colors--tricky
%   but can guarantee some minimum d by staggering through the cube,
%   liked stacked oranges

% traverse the cube twice, mutually staggered
%   guarantee at least m points where m*pExclude = n
m = n./pExclude;
side = (m/2).^(1/3);
sRegular = ceil(side);
sInset = round(side);
sides = linspace(0,1,sRegular+sInset);
regular = sides(1:2:end);
inset = sides(2:2:end);

% generate colors by unhashing from each cube traversal
%   keep all colors in a big array
%   score all the colors for whiteness
nRegular = sRegular^3;
nInset = sInset^3;
allColors = zeros(nRegular+nInset,3);
allWhites = zeros(1,nRegular+nInset);
for ii = 1:nRegular
    [r, g, b] = cubeIndices(ii, sRegular);
    allColors(ii,1:3) = [regular(r), regular(g), regular(b)];
    allWhites(ii) = sum(allColors(ii,1:3));
end
for ii = 1:nInset
    jj = ii + nRegular;
    [r, g, b] = cubeIndices(ii, sInset);
    allColors(jj,1:3) = [inset(r), inset(g), inset(b)];
    allWhites(jj) = sum(allColors(jj,1:3));
end

% return the least-white colors
[sorted, order] = sort(allWhites);
colors = allColors(order(1:n), 1:3);

% % diagnostic
% for ii = 1:n
%     r = rectangle('Position', [0 ii-1 1 1], 'FaceColor', colors(ii,:), 'EdgeColor', 'none');
% end
% xlim([0 1]);
% ylim([0 ii]);

function [r, g, b] = cubeIndices(ii, s)
i0 = ii-1;
r = mod(i0,s) + 1;
g = mod(floor(i0/s),s) + 1;
b = floor(i0/(s^2)) + 1;