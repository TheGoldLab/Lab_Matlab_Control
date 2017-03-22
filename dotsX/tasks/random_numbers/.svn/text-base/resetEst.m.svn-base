function resetEst(moveNum, half, line2)

%% reset estimate to alpha randomly if half is true.
%half

if iscell(half)
half=half{1}
end


if line2==12
    rSet('dXline', line2, 'visible', false)
    rSet('dXline', 13:42, 'visible', false)
end




global FIRA

if  ~isempty(FIRA) && FIRA.header.numTrials > 1 & half == true

    eEstimate = strcmp(FIRA.ecodes.name, 'estimate');
    est = FIRA.ecodes.data(end-1,eEstimate);
    Est=2

    eVal = strcmp(FIRA.ecodes.name, 'random_number_value');
    val = FIRA.ecodes.data(end-1,eVal);
    Rnd=1

        ptext=round(.5.*abs(est-val)+min([est val]));  % reset to a halfway point... not to random thing...
        rSet('dXtext', [2,4], 'string', ptext);

        if moveNum==1
            % convert number to deg. vis. and to
            gain = 30/300;
            % left end of fixed line
            offset = rGet('dXline', 4, 'x1');
            % new position of random number or estimate tick mark
            xPos = gain*ptext + offset;
            % move tick mark and the number
            rSet('dXline', Est, 'x1', xPos, 'x2', xPos);
            rSet('dXtext', Est, 'x', xPos-1);
            if ~isempty(line2)
                wid=rget('dXtext', 11, 'string');
                if ischar(wid)
                    wid = sscanf(wid, '%f', 1);
                end
                rset('dXline', line2, 'x1', xPos-(wid.*gain), 'x2', xPos+wid.*gain)
            end
        end
   

end
