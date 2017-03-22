     % demoImage

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania
  rGet('dXimage', 1, 'file')
try

    rInit('local');
    rAdd('dXimage', 1, 'file', 'BWpandas.bmp', 'visible', false)
    rAdd('dXimage', 1, 'file', 'BWthumb.bmp', 'visible', false)
    rAdd('dXtexture',1, 'textureFunction',  'textureChecker', 'textureArgs', {1024./2 1280./2}, ...
             'color', 0 , 'bgColor', 40,  'visible', true,  'w', inf,'h', inf)
     
    rAdd('dXtexture',1, 'textureFunction',  'textureChecker', 'textureArgs', {1024./64 1280./64}, ...
             'color', 0 , 'bgColor', 40,  'visible', false,  'w', inf,'h', inf)
    
         
         
    %% This presents an image for 1 frame, then shows a mask for a variable
    %% number of frames.  The more frames of mask, the more difficult it is
    %% to perceive the initial image.  A delay can be inserted before the
    %% mask to make the stimulus even easier to perceive.
frac=256.*mid./20
    mid=5.33
    frac=num2cell([256 256 256].*mid./20, 2)
    arg_dXimage = { ...
    'file',         'BWapple.bmp', ...
    'visible',      false, ...
    'modulateColor', frac };

    rSet('dXimage', 1, 'file', 'BWapple.bmp', 'visible', false,'modulateColor', frac)

    
  
        rGraphicsDraw
        rSet('dXimage', 1, 'visible', true);
        %rSet('dXimage', 2, 'visible', false);
        rSet('dXtexture', 2, 'visible', false)
        rSet('dXtexture', 1, 'visible', false)
        rGraphicsDraw;
        %before = getMsgH(100);
        rSet('dXimage', 1, 'visible', false);    
        rSet('dXtexture', 2, 'visible', true)
        %rSet('dXimage', 2, 'visible', true);
        rGraphicsDraw;
        %after = getMsgH(100);
        %disp(after-before)
        rGraphicsDraw;
        rGraphicsDraw;
        rSet('dXtexture', 2, 'visible', false)
        rSet('dXtexture', 1, 'visible', true)
        %rset('dXimage', 2, 'visible', false)
        rGraphicsDraw;
        
        
        
    for rr = 0:1:360
        rSet('dXimage', 1, 'rotationAngle', rr);
        rGraphicsDraw;
    end
    rDone;

catch
    rDone;
    rethrow(lasterror);
end




%% This is to bring an image in and adjust the luminance.
b=imread('Athumb.bmp', 'bmp');
b=sum(b,3);
sumB=sum(sum(b));

lum=20

b=lum.*size(b,1).*size(b,2).*b./sumB;

grey=repmat((0:1./255:1)', 1, 3);
image(b)
colormap(grey)


imwrite(b, grey, 'BWthumb.bmp', 'bmp') 







rInit('local');

rAdd('dXimage', 1, 'file', 'thumb-up.jpg', 'visible', true, 'scale', inf)
rWinPtr
rGraphicsDraw
a=Screen('GetImage', rWinPtr );

imwrite(a, 'Athumb.bmp', 'bmp')



