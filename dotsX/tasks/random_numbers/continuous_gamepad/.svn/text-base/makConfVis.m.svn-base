function makConfVis(line2)

rSet('dXline', line2, 'visible', true);
v = rGet('dXtext', 11, 'string');
if ischar(v)
    v = sscanf(v, '%f', 1);
end

% convert number to deg. vis. and to
gain = 30/300
midPos=rGet('dXline',2, 'x1')

% x-positions for confidence bar
tickers=min([floor(abs(v)./10), 15])
if tickers>0
    maxVis=12+tickers.*2;
    expo=midPos-(tickers.*10).*gain:10.*gain:midPos+tickers.*10.*gain;
    expo=[expo(1:tickers) expo(tickers+2:end)];


    rSet('dXline',13:12+length(expo),'visible',true, 'x1',num2cell(expo),'x2',num2cell(expo));

    if maxVis<42
        rSet('dXline', maxVis+1:42, 'visible', false)
    end
end

