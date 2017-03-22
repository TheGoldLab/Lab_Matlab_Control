% demonstrate the use of dXdots with arbitrary distributions of dot motion
%   this is a new dXdots feature added by BSH on 30 April 2008
%
%   Show 4 fields of dots:
%   red     - two directions at once,   100% coherence
%   yellow  - gaussian directions,      100% coherence
%   blue    - two directions at once,   51.2% coherence
%   green   - gaussian directions,      51.2% coherence

rInit('local')

% pick two discrete directions to show
%   pick relative weights for these directions
%   convert weights to CDF
domain = [80 150];
CDF = [45 50];

rAdd('dXdots',      1, ...
    'speed',        4, ...
    'dirDomain',    domain, ...
    'dirCDF',       CDF, ...
    'coherence',    100);

rAdd('dXdots',      1, ...
    'speed',        4, ...
    'dirDomain',    domain, ...
    'dirCDF',       CDF, ...
    'coherence',    100);

one = true;
rSet('dXdots', 1:2, 'visible', {one, ~one});

rGraphicsDraw(inf);

rDone