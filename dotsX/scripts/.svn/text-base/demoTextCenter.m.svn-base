% show some text with the dXtext class
% also a good way to find text that looks good on a particular screen

try
    rInit('local')

    % dXscreen sets the Screen('TextBackgroundColor', ...) to match
    %   (for all the good it does)???
    rSet('dXscreen', 1, 'bgColor', [0 0 64]);
    ppd = rGet('dXscreen', 1, 'pixelsPerDegree');
    
    rAdd('dXtext', 1, 'visible', true, 'color', [255 255 0], ...
        'font', 'Courier');
    %str = 'havabanana';
    str = 'iiiiiiiiiiwwwwwwwwww';
    
    % try several font sizes
    for fs = 10:20:200
        
        % try several string lengths
        for s = 1:length(str);

            % guess a conversion from font size to pixels
            xFontPerPix = .60;
            yFontPerPix = .8;

            % convert size in font units to pixels
            xPix = fs*xFontPerPix*s;
            yPix = fs*yFontPerPix;

            % shift the dXtext by half its size in degrees
            x = -.5*xPix/ppd;
            y = .5*yPix/ppd;
            rSet('dXtext', 1, 'x', x, 'y', y, ...
                'string', str(1:s), 'size', fs);

            % go nuts
            rGraphicsDraw(50)
        end
    end

catch
    e = lasterror
end
rDone