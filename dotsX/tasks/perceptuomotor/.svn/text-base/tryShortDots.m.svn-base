
% How short can dots viewing time get and still have detectable direction?

global ROOT_STRUCT
rInit('local')

diam = 7;

tar = rAdd('dXtarget', 2, ...
    'diameter',     {.5, diam+10}, ...
    'cmd',          {0, 1});

dot = rAdd('dXdots', 1, ...
    'diameter',     diam, ...
    'direction',    0, ...
    'density',      40, ...
    'speed',        10);

% frames of viewing
f = 10;
while true

    % check keyboard for F3 "error"
    try
        HIDx('run');
    catch
        break
    end

    % make a pause
    WaitSecs(3);

    % show FP and ring
    rSet('dXtarget', tar, 'visible', true);
    rGraphicsDraw;

    % make a pause
    WaitSecs(2);

    % make the gap
    rSet('dXtarget', 1, 'visible', false);
    rGraphicsDraw;
    WaitSecs(.2);

    % pick a random direction
    d = rand*180 - 90;
    rSet('dXdots', dot, 'direction', d, 'visible', true);

    % show f frames
    for ii = 1:f
        rGraphicsDraw;
    end

    % wait for response
    rSet('dXdots', dot, 'visible', false);
    rGraphicsDraw;

    % make a pause
    WaitSecs(.5);

    % blanket
    rGraphicsBlank;
end

rDone