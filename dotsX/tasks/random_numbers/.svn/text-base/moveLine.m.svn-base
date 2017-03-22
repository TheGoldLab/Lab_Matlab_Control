function moveLine(lineIndex, textIndex, value, isIncrement, line2, cue)

%value
%isIncrement
%line2
%cue
%cue=cue{2}

% get value from pointer
if iscell(value)
    value = rGet(value{:});
    if ischar(value)
        value = sscanf(value, '%f', 1);
    end
end

% increment value stored as a text string
if isIncrement && ~isempty(textIndex)
    v = rGet('dXtext', textIndex, 'string');
    if ischar(v)
        v = sscanf(v, '%f', 1);
    end
    value = value + v

    global FIRA
    taski = rGet('dXparadigm', 1, 'taski');
    %% THIS IS ONLY FOR UPDATING ESTIMATE, NOT CONFIDENCE BAR!!!!!
    if ~isempty(FIRA) && isfield(FIRA, 'ecodes') ...
            && rGet('dXtask', taski, 'goodTrials') > 0 %  && lineIndex < 12

        % limit movement to conform to delta rule with 0 <= alpha <= 1
        eEstimate = strcmp(FIRA.ecodes.name, 'estimate');
        est = FIRA.ecodes.data(end-1,eEstimate);

        name = rGet('dXdistr', 1, 'name');
        valECode = [name, '_value'];
        eVal = strcmp(FIRA.ecodes.name, valECode);
        val = FIRA.ecodes.data(end-1,eVal);

        low = min(est, val);
        high = max(est, val);

        if value < low && textIndex ~=11
            rPlay('dXsound', 1);
            WaitSecs(.25);
            value = low;
        elseif value > high && textIndex ~=11
            rPlay('dXsound', 1);
            WaitSecs(.25);
            value = high;


        end

        if ~isempty(line2)
            offset=rGet('dXline', 4', 'x1');
            gain = 30/300;
            wid=rGet('dXtext', 11, 'string');
            if ischar(wid)
                wid = sscanf(wid, '%f', 1);
            end
            x1= value.*gain+ wid.*gain+offset
            x2= value.*gain- wid.*gain+offset;
            rSet('dXline', line2, 'x1', x1, 'x2', x2);
        end
    end
end

%% THIS IS ONLY FOR UPDATING CONFIDENCE BAR!!!
if isIncrement && ~isempty(textIndex) && ~isempty(lineIndex) && lineIndex == 12  % what the hell is this?  confidence?
    mid = rGet('dXtext', 2, 'string')
    % get new x-positions for confidence bar
    if ischar(mid)
        mid = sscanf(mid, '%f', 1);
    end


    % convert number to deg. vis. and to
    gain = 30/300
    % left end of fixed line
    offset = rGet('dXline', 4', 'x1')
    % position of estimate tick mark
    midPos = gain*mid + offset
    % x-positions for confidence bar
    x1= midPos+ value.*gain
    x2= midPos- value.*gain

    % set new text string
    rSet('dXtext', textIndex, 'string', value);
    % move estimate bar

    % set new line length
    rSet('dXline', lineIndex, 'x1', x1, 'x2', x2);

    
    
    
    tickers=min([floor(abs(value)./10), 15])
    if tickers>0
        maxVis=tickers.*2;
        expo=midPos-(tickers.*10).*gain:10.*gain:midPos+tickers.*10.*gain;
        expo=[expo(1:tickers) expo(tickers+2:end)];
        rSet('dXline',13:12+length(expo),'visible',true, 'x1',num2cell(expo),'x2',num2cell(expo));
        %for i = 1:length(expo)
        %    rSet('dXline', 12+i, 'visible', true, 'x1', expo(i), 'x2', expo(i));
        %end
        if maxVis<30
            rSet('dXline', 13+length(expo):42, 'visible', false)
        end
    end
else

    %% THIS IS FOR ESTIMATE


    % get a screen x-position for value

    % convert number to deg. vis. and to
    gain = 30/300;

    % left end of fixed line
    offset = rGet('dXline', 4', 'x1');

    % new position of random number or estimate tick mark
    xPos = gain*value + offset;

    %% This is so that when you want to cue subjects to changes in mean we can
    %% pick a new color on the first trial of a new distribution.


    if iscell(cue)
        cue=cue{1}
    end
    if cue
        newS=rGet('dXdistr', 1, 'subBlockTrial')
        if newS==1
            prev=rGet('dXtext', textIndex, 'color')
            newC=[prev(2:3) prev(1)]
            rSet('dXtext', textIndex, 'color', newC)
        end
    end


    % set new text string
    if ~isempty(textIndex)
        rSet('dXtext', textIndex, 'string', value);
    end

    % move tick mark and the number
    if ~isempty(lineIndex)
        % set new line length
        rSet('dXline', lineIndex, 'x1', xPos, 'x2', xPos);
        rSet('dXtext', textIndex, 'x', xPos-1);
    end
end

