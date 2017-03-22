% make several dots fields, each with a gaussian direction distribution,
% each with its own mean.
%
% draw one at a time and randomly switch

global ROOT_STRUCT

try
    rInit('local')

    duration = 2;
    fr = rGet('dXscreen', 1, 'frameRate');
    nFrames = ceil(duration*fr);

    wn = rWinPtr;

    % make a new avi
    avi = avifile('distroDots.avi', 'Fps', fr);

    nDist = 2;
    means = [0 20];
    std = 15;

    for ii = 1:nDist

        % get gaussian distro for this dots
        gaussDomain = [-90:2:90] + means(ii);
        gaussCDF = normcdf(gaussDomain, means(ii), std);

        rAdd('dXdots',      1, ...
            'diameter',     8, ...
            'size',         3, ...
            'density',      50, ...
            'speed',        10, ...
            'groupMotion',  true, ...
            'x',            0, ...
            'y',            0, ...
            'coherence',    100, ...
            'color',        [255 255 255 255], ...
            'dirDomain',    gaussDomain, ...
            'dirCDF',       gaussCDF);
    end

    jj = nDist;
    for ii = 1:nDist
        rSet('dXdots', ii, 'visible', true, ...
            'pts', rGet('dXdots', jj, 'pts'));
        rSet('dXdots', jj, 'visible', false);
        jj = ii;

        % capture a series of frames
        for ff = 1:nFrames

            ROOT_STRUCT.dXdots = draw(ROOT_STRUCT.dXdots);
            frameArray = Screen('GetImage', wn, ...
                [1280/4 1024/4 3*1280/4 3*1024/4], ...
                [], ...
                [], ...
                1);
            avi = addframe(avi, 255-frameArray);
            Screen('Flip', wn);
        end
    end
end
rDone
avi = close(avi);