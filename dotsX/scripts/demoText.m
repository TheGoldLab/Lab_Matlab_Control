% show some text with the dXtext class
% also a good way to find text that looks good on a particular screen

try
    rInit('local')

    % dXscreen sets the Screen('TextBackgroundColor', ...) to match
    %   (for all the good it does)
    rSet('dXscreen', 1, 'bgColor', 0.31555);

    % shoe a normal text, and
    %   try to make another that looks good on mono++
    rAdd('dXtext', 2, 'visible', true, ...
        'x', -12, 'y', {1,-1}, ...
        'size', 60, ...
        'font', 'Courier',  ...
        'bold', true, ...
        'color', {[1 1 1]*255, [1 1 0]*255}, ...
        'string', {'I look bad on mono++', 'I look better'});
    
    rGraphicsDraw(inf)

catch
    e = lasterror
end
rDone