% Use a joystick connected to the PMD/USB 1208FS to parametrically vary a
% GLSL virtual texture

% 2008 by Benjamin Heasly
%   University of Pennsylvania

% start HIDx, etc
clear all
global ROOT_STRUCT GL
AssertOpenGL;

rInit({'screenMode', 'remote', 'bgColor', [1 1 1]*128})

% PMD sample frequency
f = 1000;

% PMD voltage range
maxV = 5;
minV = 0;
midV = mean([minV,maxV]);
trigV = 1;

% read pins 1, 2 and 4 vs ground (pin 3)
chans = 8:10;
nc = length(chans);

% gain and range modes for PMD channels
gains = [1 2 4 5 8 10 16 20];
ranges = [20 10 5 4 2.5 2 1.25 1];

modes = ones(size(chans))*2;

% setup reports
[load, loadID] = formatPMDReport('AInSetup', chans, modes-1);
[scan, scanID] = formatPMDReport('AInScan', chans, f);
[stop, stopID] = formatPMDReport('AInStop');

cc = num2cell(chans);
[channel(1:nc).ID]      = deal(cc{:});

gc = num2cell(0.01./gains(modes));
[channel(1:nc).gain]	= deal(gc{:});

[channel(1:nc).offset]	= deal(0);
[channel(1:nc).high]	= deal(nan);
[channel(1:nc).low]     = deal(nan);
[channel(1:nc).delta]	= deal(0);
[channel(1:nc).freq]	= deal(f);

rAdd('dXPMDHID', 1, 'HIDChannelizer', channel, ...
    'loadID', loadID, 'loadReport', load, ...
    'startID', scanID, 'startReport', scan, ...
    'stopID', stopID, 'stopReport', stop);

ROOT_STRUCT.dXPMDHID = reset(ROOT_STRUCT.dXPMDHID);

% for the Gabor
f = 1;
c = .999;
fRef = 1;
cRef = .999;
ppd = rGet('dXscreen', 1, 'pixelsPerDegree');

% for the mask
bg = rGet('dXscreen', 1, 'bgColor');

% for both
s = 10;

% make a mask textures and a GLSL Gabor texture
mt = rAdd('dXtexture', 1, ...
    'textureArgs',      s/8, ...
    'textureFunction',  'textureGaussAlpha', ...
    'modulateColor',    bg, ...
    'x',                0, ...
    'y',                0, ...
    'w',                s, ...
    'h',                s, ...
    'rotation',         0, ...
    'filterMode',       1, ...
    'preload',          true, ...
    'visible',          true);

glsl = { ...
    'f',    1, ...
    'c',    .5, ...
    'ppd',  ppd, ...
    'pixCenter',    [s s]*ppd/2, ...
    'ColorHigh',    [1 1 1 1], ...
    'ColorLow',     [0 0 0 1]};

% create the dXvirtualTexture with the GLSL Gabor shader
rAdd('dXvirtualTexture', 1, ...
    'visible',          true, ...
    'file',             'FreqConGabor.frag.txt', ...
    'GLSLArgs',         glsl, ...
    'x',                0, ...
    'y',                0, ...
    'w',                s, ...
    'h',                s, ...
    'GLSLDebugMode',    false, ...
    'sourceRect',       [], ...
    'rotation',         0, ...
    'filterMode',       1, ...
    'globalAlpha',      [], ...
    'modulateColor',    []);

% press F3 to error/quit
try
    while true

        % get HID events
        HIDx('run');
        val = get(ROOT_STRUCT.dXPMDHID, 'values');

        if ~isempty(val)

            % detect trigger press
            trig = any(val(val(:,1)==chans(3), 2) < trigV);
            if trig

                % pick new reference target
                fRef = exp(rand);
                cRef = rand*.999;
                rSet('dXvirtualTexture', 1, ...
                    'GLSLArgs', {'f', fRef, 'c', cRef});

                % show it for any time
                rGraphicsDraw;

                % hold unil release
                while trig
                    WaitSecs(.002);
                    HIDx('run');
                    val = get(ROOT_STRUCT.dXPMDHID, 'values');
                    if ~isempty(val)
                        trig = any(val(val(:,1)==chans(3), 2) < trigV);
                        ROOT_STRUCT.dXPMDHID = ...
                            set(ROOT_STRUCT.dXPMDHID, 'values', []);
                    end
                end
            end

            % update probe position
            x = mean(val(find(val(:,1)==chans(1)), 2));
            y = mean(val(find(val(:,1)==chans(2)), 2));

            f = exp(x/maxV);
            c = y/maxV;

            % done with these values
            ROOT_STRUCT.dXPMDHID = set(ROOT_STRUCT.dXPMDHID, 'values', []);
        end

        % update the probe texture parameters
        rSet('dXvirtualTexture', 1, ...
            'GLSLArgs', {'f', f, 'c', c});

        % Redraw
        rGraphicsDraw;
    end
catch
    e = lasterror
end

% cleanemup
rDone;
Screen('CloseAll');