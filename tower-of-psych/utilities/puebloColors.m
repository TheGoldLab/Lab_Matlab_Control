% Get a colormap with bold, Earthy colors.
% @param n the length of colormap to build
% @details
% Returns an nX3 colormap with rows of the form [R G B], and components in
% the range 0-1.
% @details
% The "Pueblo" colors are inspired by the art work in Gerald McDermott's
% book Arrow to the Sun (http://en.wikipedia.org/wiki/Arrow_to_the_Sun).
% There are only a few unique colors in this color map.  If @a n is larger
% than the number of colors, they are repeated.
% @details
% Most of the "Pueblo" colors are on the red side of the spectrum.  They
% show up well against black.
% @details
% Here's a demo:
% @code
% n = 9;
% colormap([puebloColors(n); 0 0 0]);
% thingy = n+1*ones(1, 2*n+1);
% thingy(2:2:2*n) = 1:n;
% image(thingy);
% @endcode
%
% @ingroup topsUtilities
function colors = puebloColors(n)

if nargin < 1
    n = size(get(gcf,'colormap'),1);
end

% various colors identified in Arrow the the Sun
baseColors = [ ...
    206 1 1; ... % arrowmaker red
    126 165 33; ... % cactus green
    44 192 242; ... % morning blue
    236 76 150; ... % frosting pink
    49 224 85; ... % scrub green
    154 40 26; ... % rust brown
    238 86 25; ... % sunset orange
    224 225 6; ... % sun yellow
    251 178 64; ... % sand bronze
    ];

nBaseColors = size(baseColors, 1);
rows = 1 + mod(0:(n-1), nBaseColors);
colors = baseColors(rows,:) ./ 255;