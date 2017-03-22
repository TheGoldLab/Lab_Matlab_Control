function demoBitsPlusGray

% Test BitsPlusPlus gray drawing in DotsX

% based Psychtoolbox/PsychHardware/BitsPlusToolbox/demoMonoCSF.m
% and made specific to GoldLab setup and DotsX, 2D gaussian

clear all
close all

% Define screen
whichScreen=max(Screen('Screens'));

% screen shorthands
white=WhiteIndex(whichScreen);
black=BlackIndex(whichScreen);
gray=GrayIndex(whichScreen);

Priority(9);
[window,screenRect] = Screen('OpenWindow',whichScreen,0,[],[],2);
Screen('LoadNormalizedGammaTable',window, ...
    linspace(0,(255/256),256)'*ones(1,3));

% find a calibrated lut for this machine/monitor/rig
[s,hn] = unix('hostname');
hndot = find(hn == '.');
gammaFile = ['Gamma_', hn(1:hndot), 'mat'];
if isempty(which(gammaFile))
    disp('found no characteristic clut, using linear clut')
    clut = repmat(round(linspace(0, 2^16 -1, 256))', 1, 3);
else
    load(gammaFile);
    clut = gamma16bit;
end

% make a 2D circular Gaussian
SIG = 75; % 95% of curve within 300 pixels (150 from MU)
c1 = 1/(2*pi*SIG^2);
c2 = (2*SIG^2);

% center in display, keep DM even
MU = SIG*3;
DM = SIG*6;

% luminance peak relative to mean
L_back  = 0.5;
L_max   = 0;

% allocate gaussian
% compute one quarter of it, flip-copy other three
f = zeros(DM, DM);
for x = 1:DM/2
    for y = 1:DM/2
        f(y,x) = exp(-((x-MU).^2 + (y-MU).^2)/c2);
    end
end
f(DM/2+1:DM, 1:DM/2) = flipud(f(1:DM/2, 1:DM/2));
f(1:DM/2, DM/2+1:DM) = fliplr(f(1:DM/2, 1:DM/2));
f(DM/2+1:DM, DM/2+1:DM) = flipud(f(1:DM/2, DM/2+1:DM));

% how many animation textures in 200ms?
nframes = 1000/Screen('NominalFrameRate', window);
nt = ceil(200/nframes/2);
L_dif = linspace(L_max, L_back, nt);

% make animation textures
grimage = zeros(size(f));
gamma_image = zeros(size(f));
textures = zeros(1, nt);
for t = 1:nt
    grimage = round((L_dif(t)*f + L_back)*(2^16-1));
    gamma_image = BitsPlusPackMonoImage(clut(grimage+1));
    textures(t) = Screen('MakeTexture', window, gamma_image);
end

% draw the middle gray background
Screen('FillRect', window, reshape(gamma_image(1,1,:), 1, 3))
Screen('Flip', window);
WaitSecs(2);

% draw those textures!
isPreloaded = Screen('PreloadTextures', window);
for t = [1:nt, nt:-1:1]
    Screen('DrawTexture', window, textures(t));
    Screen('Flip', window);
end

WaitSecs(2);

% Close the window.
Screen('CloseAll');