% Use ASL "eye movements" which are actually head movements with fixed eye,
% to parametrically vary a GLSL virtual texture

% 2008 by Benjamin Heasly
%   University of Pennsylvania

% start HIDx, etc
clear all
global ROOT_STRUCT GL
AssertOpenGL;

rInit({'screenMode', 'local', 'bgColor', [1 1 1]*128})

% Eyepos range
maxP = 10;
minP = -10;
midP = mean([minP,maxP]);


BF.n = 5;
BF.lowP = 0;
BF.deltaP = 10;
BF.deltaH = 650;
BF.deltaV = 650;
rAdd('dXasl', ...
    'freq',         120, ...
    'blinkParams',  BF, ...
    'aslRect',      [-2032, 1532, 4064, -3064]);

% make two gaussian mask textures
s = 10;
ppd = rGet('dXscreen', 1, 'pixelsPerDegree');
sPix = floor(s*ppd);

% gray background
bg = 128;

% locate the Gabor GLSL shader code
[path, name, ext] = fileparts(mfilename('fullpath'));
shadFile = fullfile(path, 'tryGLSL.frag.txt');

f = 1;
c = .999;
fRef = 1;
cRef = .999;

% make two mask textures and two virtual Gabor textures
numTex = 1;
xs = [0 0];
rots = [0 0];
for tt = 1:numTex
    mt(tt) = rAdd('dXtexture', 1, ...
        'textureArgs',      s/8, ...
        'textureFunction',  @textureGaussAlpha, ...
        'modulateColor',    rGet('dXscreen', 1, 'bgColor'), ...
        'x',                xs(tt), ...
        'y',                0, ...
        'w',                s, ...
        'h',                s, ...
        'rotation',         rots(tt), ...
        'filterMode',       1, ...
        'preload',          true, ...
        'visible',          true);
    maskTex(tt) = rGet('dXtexture', tt, 'textures');
    drawRect(tt,:) = rGet('dXtexture', tt, 'drawRect');

    % Load my lame GLSL texutre program fragment
    gaborGLSL(tt) = LoadGLSLProgramFromFiles(shadFile, 1);

    % Create virtual texture with pixels defined by gaborGLSL function
    gaborTex(tt) = Screen('SetOpenGLTexture', rWinPtr, [], 0, ...
        GL.TEXTURE_RECTANGLE_EXT, sPix, sPix, 1, gaborGLSL(tt));

    % Bind the shader, setup parameters
    glUseProgram(gaborGLSL(tt));

    % pick sinusoid colors
    glUniform4f(glGetUniformLocation(gaborGLSL(tt), 'ColorHigh'), ...
        1.0, 1.0, 1.0, 1.0);
    glUniform4f(glGetUniformLocation(gaborGLSL(tt), 'ColorLow'), ...
        0.0, 0.0, 0.0, 1.0);

    % pass in pixels per degree
    glUniform1f(glGetUniformLocation(gaborGLSL(tt), 'ppd'), ppd);

    % Set the frequency and contrast of the sinusoid
    fParam(tt) = glGetUniformLocation(gaborGLSL(tt), 'f');
    glUniform1f(fParam(tt), f);

    cParam(tt) = glGetUniformLocation(gaborGLSL(tt), 'c');
    glUniform1f(cParam(tt), c);

    % Done with setup, disable shader:
    glUseProgram(0);
end

% press F3 to error/quit
try
    while true
        
        % check keyboard to allow F3 quit
        HIDx('run');

        % get ASL data
        ROOT_STRUCT.dXasl = query(ROOT_STRUCT.dXasl);
        val = get(ROOT_STRUCT.dXasl, 'values');

        if ~isempty(val)

            % % detect commit response of some kind...
            % trig = any(val(val(:,1)==chans(3), 2) < trigV);
            % if trig
            % 
            %     % pick new reference target
            %     fRef = exp(rand);
            %     cRef = rand*.999;
            %     glUseProgram(gaborGLSL(1));
            %     glUniform1f(fParam(1), fRef);
            %     glUniform1f(cParam(1), cRef);
            %     glUseProgram(0);
            % 
            %     % show it for any time
            %     Screen('DrawTexture', rWinPtr, gaborTex(1), ...
            %         [], drawRect(1,:), rots(1));
            %     ROOT_STRUCT.dXtexture = draw(ROOT_STRUCT.dXtexture);
            %     vbl = Screen('Flip', rWinPtr);
            % 
            %     % hold unil release
            %     while trig
            %         WaitSecs(.002);
            %         HIDx('run');
            %         val = get(ROOT_STRUCT.dXPMDHID, 'values');
            %         if ~isempty(val)
            %             trig = any(val(val(:,1)==chans(3), 2) < trigV);
            %             ROOT_STRUCT.dXPMDHID = ...
            %                 set(ROOT_STRUCT.dXPMDHID, 'values', []);
            %         end
            %     end
            % end

            % update probe position
            x = mean(val(:,2));
            y = mean(val(:,3));

            f = exp(x/maxP);
            c = y/maxP;

            % done with these values
            ROOT_STRUCT.dXasl = set(ROOT_STRUCT.dXasl, 'values', []);
        end

        % update the probe texture parameters
        glUseProgram(gaborGLSL(1));
        glUniform1f(fParam(1), f);
        glUniform1f(cParam(1), c);
        glUseProgram(0);

        % Redraw
        Screen('DrawTexture', rWinPtr, gaborTex(1), ...
            [], drawRect(1,:), rots(1));
        ROOT_STRUCT.dXtexture = draw(ROOT_STRUCT.dXtexture);
        vbl = Screen('Flip', rWinPtr);
    end
catch
    e = lasterror
end

% cleanemup
rDone;
Screen('CloseAll');