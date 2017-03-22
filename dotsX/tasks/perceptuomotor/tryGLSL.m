function tryGLSL
% try to make a virtual procedural texture for real time Gabor maipulation

try

    % Acquire a handle to OpenGL, so we can use OpenGL commands in our code:
    global GL;

    % Make sure this is running on OpenGL Psychtoolbox:
    AssertOpenGL;

    % Choose screen with maximum id - the secondary display:
    screenid = max(Screen('Screens'));

    % Open a fullscreen onscreen window on that display, choose a background
    % color of 128 = gray with 50% max intensity:
    [win winRect]= Screen('OpenWindow', screenid, 128);

    % Query window size: Need this to define center and radius of expanding
    % disk stimulus:
    [tw, th] = Screen('WindowSize', win);

    % Load my lame GLSL texutre program fragment
    [path, name, ext] = fileparts(mfilename('fullpath'));
    shadFile = fullfile(path, 'tryGLSL.frag.txt');
    tryGLSL = LoadGLSLProgramFromFiles(shadFile, 1);

    % Create a purely virtual texture of size tw x th virtual pixels.  Attach
    % the tryGLSL to it, to define its "appearance":
    tryTex = Screen('SetOpenGLTexture', win, [], 0, ...
        GL.TEXTURE_RECTANGLE_EXT, tw, th, 1, tryGLSL);

    % Bind the shader: After binding it, we can setup some parameters for our
    % stimulus:
    glUseProgram(tryGLSL);

    % Set the colors of the sinusoid
    glUniform4f(glGetUniformLocation(tryGLSL, 'ColorHigh'), 1.0, 1.0, 1.0, 1.0);
    glUniform4f(glGetUniformLocation(tryGLSL, 'ColorLow'), 0.0, 0.0, 0.0, 1.0);

    % set pixels per degree
    ppd = 33;
    glUniform1f(glGetUniformLocation(tryGLSL, 'ppd'), ppd);

    % Set the frequency and contrast of the sinusoid
    f = 1;
    fParam = glGetUniformLocation(tryGLSL, 'f');
    glUniform1f(fParam, f);

    c = .999;
    cParam = glGetUniformLocation(tryGLSL, 'c');
    glUniform1f(cParam, c);

    % Done with setup, disable shader:
    glUseProgram(0);

    n = 100;
    f = logspace(-1,-2,n);
    c = linspace(0,.999,n);

    % Perform initial flip to gray background and sync us to the retrace:
    vbl = Screen('Flip', win);

    % Animation loop: Run until keypress:
    for ii = 1:n

        % Assign the new shift- and radius values to the texture shader:
        glUseProgram(tryGLSL);

        % Assign new Frequency and Contrast
        glUniform1f(fParam, f(ii));
        glUniform1f(cParam, c(ii));

        % Done with stimulus setup for this iteration:
        glUseProgram(0);

        Screen('DrawTexture', win, tryTex);

        % Request stimulus onset at next video refresh:
        vbl = Screen('Flip', win);
    end

    % Close window, release all ressources:
    Screen('CloseAll');

catch

    evalin('base', 'e = lasterror');
    clear all

end
