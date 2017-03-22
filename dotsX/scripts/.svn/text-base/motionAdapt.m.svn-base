rInit('local')

% pick two discrete directions to show
%   pick relative weights for these directions
%   convert weights to CDF
twoDomain = 270+[-.5 .5]*0;
twoPmf = [2 2];
twoCDF = cumsum(twoPmf)/sum(twoPmf);

rAdd('dXdots',      1, ...
    'diameter',     8, ...
    'size',         3, ...
    'density',      67, ...
    'speed',        6, ...
    'coherence',    100, ...
    'visible',      true, ...
    'dirDomain',    twoDomain, ...
    'dirCDF',       twoCDF);

rGraphicsDraw(10000);

% rGraphicsBlank
% WaitSecs(10)

rSet('dXdots', 1, 'coherence', 0)
rGraphicsDraw(10000);

% rGraphicsShow;

rGraphicsDraw()
WaitSecs(5)

rDone