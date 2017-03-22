function sublim(varargin)



% Flash image on this trial?
p = .5
showIt=binornd(1, p, 1)

if showIt==1


    %setup array of possible image files

    Flash={'BWapple.bmp', 'BWbull.bmp', 'BWcandle.bmp', 'BWchess.bmp', ...
        'BWdog-sign.bmp', 'BWfireworks.bmp', 'BWgiraffe.bmp', 'BWlegs.bmp',...
        'BWleopard.bmp', 'BWorangs.bmp', 'BWpandas.bmp', 'BWthumb.bmp',...
        'BWtiger-eating.bmp', 'BWtiger.bmp', 'BWtree.bmp', 'BWturtle.bmp'}
    % pick a specific image to show this trial
    fp=ceil(rand(1).*size(Flash,2))


    global ROOT_STRUCT
    if ~isfield(ROOT_STRUCT, 'dXimage')
        rAdd('dXimage', 1, 'file', Flash{fp}, 'visible', false)
        rAdd('dXtexture',1, 'textureFunction',  'textureChecker', 'textureArgs', {1024./2 1280./2}, ...
            'color', 0 , 'bgColor', 128./12,  'visible', false,  'w', inf,'h', inf)
    else
        rSet('dXimage', 1, 'file', Flash{fp})

    end
    %% This presents an image for 1 frame, then shows a mask for a variable
    %% number of frames.  The more frames of mask, the more difficult it is
    %% to perceive the initial image.  A delay can be inserted before the
    %% mask to make the stimulus even easier to perceive.
    if isfield(ROOT_STRUCT, 'dXimage')
        rGet('dXimage', 1, 'file')
        rGraphicsShow('dXimage', 1, {}, 'dXtexture', 1:2,'dXtext' )
        rGraphicsDraw;
    end
else
    fp=0
end
    rSet('dXtext', [10], 'string', fp);


