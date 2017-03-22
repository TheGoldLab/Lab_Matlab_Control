% script to analyze FIRA data for learning_bias tasks
% conceived by Benjamin Heasly, transcribed by Benjamin Naecker
% University of Pennsylvania 2008

% preprocess FIRAs -- concatenate, clean up
clear all
concatenateFIRAs
[uNames, tnID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(20, 20);

% declare FIRA
global FIRA
% transpose tnID
tnID = tnID';

% extract relevant data by task type and put into relevant variables
% sorting data by task, subthresh direction, test direction, test coherence

% get all trials of each task type
if any(strcmp(uNames, 'BiasLever_180C'))
    select180C = find(strcmp(uNames, 'BiasLever_180C')) == tnID;
else
end

if any(strcmp(uNames, 'BiasLever_180Q'))
    select180Q = find(strcmp(uNames, 'BiasLever_180Q')) == tnID;
else
end

if any(strcmp(uNames, 'BiasLever_20C'))
    select20C = find(strcmp(uNames, 'BiasLever_20C')) == tnID;
else
end

if any(strcmp(uNames, 'BiasLever_20Q'))
    select20Q = find(strcmp(uNames, 'BiasLever_20Q')) == tnID;
else
end

% get relevant data columns from FIRA.ecodes
eLowCohDir = strcmp(FIRA.ecodes.name, 'low_coh_dot_dir');
eRight = strcmp(FIRA.ecodes.name, 'right');
eGood = strcmp(FIRA.ecodes.name, 'good_trial');
eHighCohDir = strcmp(FIRA.ecodes.name, 'high_coh_dot_dir');
eHighCoh = strcmp(FIRA.ecodes.name, 'high_coh');
eCorrect = strcmp(FIRA.ecodes.name, 'correct');

% which trials are good?
selectGood = FIRA.ecodes.data(:,eGood);

% finally, pull out the data we need
lowCohDir180C = FIRA.ecodes.data(select180C & selectGood, eLowCohDir);
lowCohDir20C = FIRA.ecodes.data(select20C & selectGood, eLowCohDir);
highCohDir180C = FIRA.ecodes.data(select180C & selectGood, eHighCohDir);
highCohDir20C = FIRA.ecodes.data(select20C & selectGood, eHighCohDir);
highCoh180C = FIRA.ecodes.data(select180C & selectGood, eHighCoh);
highCoh20C = FIRA.ecodes.data(select20C & selectGood, eHighCoh);

% stem(FIRA.ecodes.data(:, eHighCoh))

% did the subject choose "right"?
rightChoice180C = ~isnan(FIRA.ecodes.data(select180C & selectGood, eRight));
rightChoice20C = ~isnan(FIRA.ecodes.data(select20C & selectGood, eRight));

% PREPARE 180C TRIALS
% get unique array with low coherence directions
% also sign the directions (left = -1, right = 1)
% get unique test coherences
% put all the coherences in a signed array
uLowCohDir180C = unique(lowCohDir180C);
signCoh180C = 2*(highCohDir180C < 90) - 1;
uHighCoh180C = unique(highCoh180C);
allSignedHighCoherences180C = [uHighCoh180C; -uHighCoh180C];

% prepare the figure to show all the relevant data
figure(1)
clf
ax = axes('YLim', [0 1], 'XLim', [-100 100]);
xAxis = linspace(-100, 100, 1000);
axisData = [ones(1000,1), xAxis'];

% nothing going on here...just grouping the trials by color for clarity
l = length(uLowCohDir180C);
colorIntegers = [1:(l/2), 1:(l/2)];

% inits to logist_fit --> [fits_,sems_,stats_,preds_,resids_] =
% logist_fit(data, lumode, varargin)
inits = [0 -10 10; .02 .02 .2; .01 0 .2];

% loop through 180C trials first by unique direction, then by test
% coherences
for i = 1:length(uLowCohDir180C)
    
    % boolean array: subthresh dir on this trial matches unique subthresh dir
    dirSelect = lowCohDir180C == uLowCohDir180C(i);
    
    % color scheme --> convert index to binary...clever for < 8 colors
    color = dec2bin(colorIntegers(i), 3) == '1';
    
    % data input to logist_fit
    choices = rightChoice180C(dirSelect);
    coherences = signCoh180C(dirSelect).*highCoh180C(dirSelect);
    
    % data format for logist_fit
    data = [ones(size(coherences)), coherences, choices];
   
    % percent of rightward choices --> this is the bias!
    % cf. fig. 4 Jazayeri/Movshon paper
    pRight180(i) = mean(choices);
    
    % the logistic fits
    fits(i, :) = logist_fit(data, 'lu1', 'inits', inits);
    
    % go through each test coherence
    for j = 1:length(allSignedHighCoherences180C)
        
        % group "right" percentage by coherences
        cohSelect = coherences == allSignedHighCoherences180C(j);
        pRightByCoh(j) = mean(choices(cohSelect));
        
    end
    
    % l1 = relative bias
    l1 = line(allSignedHighCoherences180C, pRightByCoh, 'Parent', ax, 'LineStyle', '--',...
        'Marker', '*', 'Color', color);
    
    % l2 = logistic fits showing bias as shift
    y = logist_val(fits(i, 1:2), axisData);
    l2 = line(xAxis, y*(1-fits(i, 3)*2) + fits(i,3), 'Parent', ax, 'LineStyle', '-',...
        'Marker', 'none', 'Color', color);
    
    
    
%     % optional controlled loop through each coherence group, delete it
%     % after viewing
%     waitforbuttonpress;
%     delete([l1, l2]);
% 
%     % explicitly compute the biases, interpolated from the fits
    bias180C(i) = interp1(y, xAxis, .5);
    
end



% PREPARE 20C TRIALS
% get unique array with low coherence directions
% sign the directions -1 or 1
% get unique test coherences
% put all coherences in signed array
uLowCohDir20C = unique(lowCohDir20C);
signCoh20C = 2*(highCohDir20C < 90) - 1;
uHighCoh20C = unique(highCoh20C);
allSignedHighCoherences20C = [uHighCoh20C; -uHighCoh20C];

% prepare the figure to show all the relevant data
figure(2)
clf
ax = axes('YLim', [0 1], 'XLim', [-100 100]);
xAxis = linspace(-100, 100, 1000);
axisData = [ones(1000,1), xAxis'];

% nothing going on here...just grouping the trials by color for clarity
l = floor(length(uLowCohDir20C)/2);
colorIntegers = [1:l, 0, l:-1:1];

% loop through 20C trials first by unique direction, then by test
% coherences
for i = 1:length(uLowCohDir20C)
    
    % match subthresh direction with unique directions
    dirSelect = lowCohDir20C == uLowCohDir20C(i);
    
    % color scheme --> convert index to 3-digit binary...clever, for < 8 colors
    color = dec2bin(colorIntegers(i), 3) == '1';
    
    % data input to logist_fit
    choices = rightChoice20C(dirSelect);
    coherences = signCoh20C(dirSelect).*highCoh20C(dirSelect);
    
    % data format for logist_fit
    data = [ones(size(coherences)), coherences, choices];
   
    % percent of rightward choices --> this is the bias!
    % cf. fig. 4 Jazayeri/Movshon paper
    pRight20(i) = mean(choices);
    
    % the logistic fits
    fits(i, :) = logist_fit(data, 'lu1', 'inits', inits);
   
    % go through each test coherence
    for j = 1:length(allSignedHighCoherences20C)
        
        % group "right" percentage by coherences
        cohSelect = coherences == allSignedHighCoherences20C(j);
        pRightByCoh(j) = mean(choices(cohSelect));
        
    end
    
    % l1 = relative bias
    l1 = line(allSignedHighCoherences20C, pRightByCoh, 'Parent', ax, 'LineStyle', 'none',...
        'Marker', '*', 'Color', color);
    
    % l2 = logistic fits showing bias as shift
    y = logist_val(fits(i, 1:2), axisData);
    l2 = line(xAxis, y*(1-fits(i, 3)*2) + fits(i,3), 'Parent', ax, 'LineStyle', '-',...
        'Marker', 'none', 'Color', color);
    
    % optional controlled loop through each coherence group, delete it
    % after viewing
%     waitforbuttonpress;
%     delete([l1, l2]);

    % explicitly compute the biases, interpolated from the fits
    bias20C(i) = interp1(y, xAxis, .5);

end


% set up graphs of relative bias
figure(3)
a = subplot(2,1,1);
title(gca, 'Proportion of Rightward Choices by Biasing Angle, 180C')
plot(uLowCohDir180C, pRight180);
b = subplot(2,1,2);
title(gca, 'Proportion of Rightward Choices by Biasing Angle, 20C')
plot(uLowCohDir20C, pRight20);

% plot the biases explicitly
figure(4)
c = subplot(2,1,1);
title(gca, 'Explicit Bias by Biasing Angle, 180C')
plot(uLowCohDir20C, bias20C);
d = subplot(2,1,2);
title(gca, 'Explicit Bias by Biasing Angle, 20C')
plot(uLowCohDir180C, bias180C);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





% plot bias per bias angle and by session type over the course of all trials

% get all good trials of each session type
% goodTrials180C = FIRA.ecodes.data(select180C & selectGood);
% goodTrials20C = FIRA.ecodes.data(select20C & selectGood);

% selector for the good QUEST trials
goodTrials180Q = FIRA.ecodes.data(select180Q & selectGood);
goodTrials20Q = FIRA.ecodes.data(select20Q & selectGood);

% unique sessionID arrary
uSessionID = unique(sessionID);

% % prepare figure to show bias by session number
% figure(5)
% clf
% ax1 = axes('YLim', [0 100], 'XLim', [0 8]);

% axes for plot of estimate of threshold from task data
figure(300)
c = axes('XLim', [0 8], 'YLim', [0 100]);

% inits for the above esimate
wInits = [40 0 100; 3.5 3.5 3.5; .01 .01 .01; .5 .5 .5];

% get all good trials of each session type and each subthresh angle
% first 180C trials
for j = 1:length(uSessionID)
    
    sessionSelect = sessionID == uSessionID(j);
    totalSelect = selectGood & select180C & sessionSelect;
    QUESTSelect = selectGood & select180Q & sessionSelect;
    
    if any(totalSelect)
        choices180CbySession = ~isnan(FIRA.ecodes.data(totalSelect, eRight));
        correct180CbySession = ~isnan(FIRA.ecodes.data(totalSelect, eCorrect));
        lowCohDir180CbySession = FIRA.ecodes.data(totalSelect, eLowCohDir);
        highCoh180CbySession = FIRA.ecodes.data(totalSelect, eHighCoh);
        highCohDir180CbySession = FIRA.ecodes.data(totalSelect, eHighCohDir);
        signCoh180CbySession = 2*(highCohDir180CbySession < 90) - 1;
        
        ROOT_STRUCT = FIRA.allHeaders(uSessionID(j)).session;
        dots = struct(ROOT_STRUCT.classes.dXdots.objects);
        uSessionID(j);
        lowCohbySession = (dots(1).fields.userData)/4;
    else
        continue
    end
    

    
    
    % put in the above loops minus plotting lines
    for i = 1:length(uLowCohDir180C)

        % boolean array: subthresh dir on this trial matches unique subthresh dir
        dirSelect = lowCohDir180CbySession == uLowCohDir180C(i);

        % data input to logist_fit
        choices = choices180CbySession(dirSelect);
        coherences = signCoh180CbySession(dirSelect).*highCoh180CbySession(dirSelect);
        uCoherences = unique(coherences);

        % data format for logist_fit
        data = [ones(size(coherences)), coherences, choices];

        % the logistic fits
        fits(i, :) = logist_fit(data, 'lu1', 'inits', inits);

        y = logist_val(fits(i, 1:2), axisData)*(1-fits(i, 3)*2) + fits(i,3);

        % explicitly compute the biases, interpolated from the fits, i.e.,
        % % get out relevant data from fits --> bias for *each* session block, by
        % angle
        bias180C(j,i) = abs(interp1(y, xAxis, .5));
        
        % color scheme --> convert index to binary...clever for < 8 colors
        color = dec2bin(colorIntegers(i), 3) == '1';
        yPos = i*.05;

        % go through each test coherence
        for k = 1:length(uCoherences)

            % group "right" percentage by coherences
            cohSelect = coherences == uCoherences(k);
            pRightByCoh(k) = mean(choices(cohSelect));

        end

%         % l1 = percent correct
%         l1 = line(uCoherences, pRightByCoh, 'Parent', ax, 'LineStyle', 'none',...
%             'Marker', '*', 'Color', color);
%         s = sprintf('session = %d, low coherence = %.2f',...
%              uSessionID(j), lowCohbySession);
%         s2 = sprintf('%d deg', uLowCohDir180C(i));
%         t1 = text(-95, .8, s);
%         t2 = text(85, yPos, s2, 'Color', color);
%         
%         % l2 = logistic fit showing bias as shift
%         l2 = line(xAxis, y, 'Parent', ax, 'LineStyle', '-',...
%         'Marker', 'none', 'Color', color);
%         
%         waitforbuttonpress;
%         delete([l1, t1]);

    end
    
    
    
    % get out the good QUEST trials, select for session and good
    goodQUESTS = FIRA.QUESTData(find(QUESTSelect));
    lastQUEST = goodQUESTS{numel(goodQUESTS)};
    threshold(j) = lastQUEST.estimatePost;
    
    
    % plot all coherences from each session's QUEST
    figure(100+j)
    b = axes('XLim', [0 50], 'YLim', [0 100]);
    for i = 1:length(goodQUESTS)
        estimate = goodQUESTS{i}.estimatePost;
        thresh = line(i, estimate, 'Parent', b, 'LineStyle', '-',...
            'Marker', '*');
    end
    title(b, 'Incremental QUEST Threshold Estimates - 180Q');
    
    % calculating threshold from actual choices during task

    % go through each test coherence
    for k = 1:length(uCoherences)

        % group "right" percentage by coherences
        cohSelect = highCoh180CbySession == uCoherences(k);
        numTrials(k) = sum(cohSelect);
        pCorrect(k) = sum(correct180CbySession(cohSelect))/numTrials(k);

    end

    wFits = ctPsych_fit(@quick4, uCoherences, [pCorrect' numTrials'],...
        [], [], wInits)
    
    guessCoh = line(j, wFits(1), 'Parent', c, 'Color', [0 0 1], 'Marker', '*');
    QUESTCoh = line(j, threshold(j), 'Parent', c, 'Color', [0 1 0], 'Marker', '*');
    title(c, 'Blue - Threshold from ctPsychFit, Green - Threshold from QUEST data')
    
    
    
    cla(ax);   
    
    
end





    % PLOT BIAS(J,:) ON NEW AXES AX1, DO NOT DELETE BETWEEN LOOPS, also add
    % the a color in the same type of scheme as above, maybe some text
    % saying what session we're in
    
% for i = 1:length(uSessionID)
%     
%     color1 = dec2bin(colorIntegers(i), 3) == '1';
%     yPos1 = i*.02;
%     biasline = line(uSessionID, bias180C(:,i), 'Parent', ax1, 'LineStyle', '-', ...
%                 'Marker', '*', 'Color', color1);
%     str = sprintf('session %d', uSessionID(i));
%     txt = text(.05, yPos1, str, 'Color', color1);
%     
%     waitforbuttonpress;
%     
% end

% now we get the average bias, per session, across all angles
% first get some new axes

% figure(6)
% clf
% ax2 = axes('YLim', [0 100], 'XLim', [0 8]);
% title('Average bias per session, across all angles - Coarse');

for i = 1:length(uSessionID)
    
    meanBias180C(i) = mean(bias180C(i,:));  
%     color1 = dec2bin(colorIntegers(i), 3) == '1';
%     yPos1 = i*5;
%     biasline = line(uSessionID(i), meanBias180C(i), 'Parent', ax2, 'LineStyle', '-', ...
%                 'Marker', '*', 'Color', color1);
%     str = sprintf('session %d', uSessionID(i));
%     txt = text(.05, yPos1, str, 'Color', color1);
    
    
end


% axes for estimate of threshold from task data
figure(400)
d = axes('XLim', [0 8], 'YLim', [0 100]);



%%% NOW DO THE SAME FOR 20C trials...
for j = 1:length(uSessionID)
    
    sessionSelect = sessionID == uSessionID(j);
    totalSelect = selectGood & select20C & sessionSelect;
    QUESTSelect = selectGood & select20Q & sessionSelect;
    
    if any(totalSelect)
        choices20CbySession = ~isnan(FIRA.ecodes.data(totalSelect, eRight));
        correct20CbySession = ~isnan(FIRA.ecodes.data(totalSelect, eCorrect));
        lowCohDir20CbySession = FIRA.ecodes.data(totalSelect, eLowCohDir);
        highCoh20CbySession = FIRA.ecodes.data(totalSelect, eHighCoh);
        highCohDir20CbySession = FIRA.ecodes.data(totalSelect, eHighCohDir);
        signCoh20CbySession = 2*(highCohDir20CbySession < 90) - 1;
        
        ROOT_STRUCT = FIRA.allHeaders(uSessionID(j)).session;
        dots = struct(ROOT_STRUCT.classes.dXdots.objects);
        uSessionID(j);
        lowCohbySession = (dots(1).fields.userData)/4;
    else
        continue
    end
    
    % get out the good QUEST trials, select for session and good
    goodQUESTS = FIRA.QUESTData(find(QUESTSelect));
    lastQUEST = goodQUESTS{numel(goodQUESTS)};
    threshold(j) = lastQUEST.estimatePost;
    
    % plot all coherences from each session's QUEST
    figure(200+j)
    b = axes('XLim', [0 50], 'YLim', [0 100]);
    for i = 1:length(goodQUESTS)
        estimate = goodQUESTS{i}.estimatePost;
        thresh = line(i, estimate, 'Parent', b, 'LineStyle', '-',...
            'Marker', '*');
    end
    title(b, 'Incremental QUEST Threshold Estimates - 20Q')

    % calculating threshold from actual choices during task

    % go through each test coherence
    for k = 1:length(uCoherences)

        % group "right" percentage by coherences
        cohSelect = highCoh20CbySession == uCoherences(k);
        numTrials(k) = sum(cohSelect);
        pCorrect(k) = sum(correct20CbySession(cohSelect))/numTrials(k);

    end

    wFits = ctPsych_fit(@quick4, uCoherences, [pCorrect' numTrials'], ...
        [], [], wInits)
    
    guessCoh = line(j, wFits(1), 'Parent', d, 'Color', [0 0 1], 'Marker', '*');
    QUESTCoh = line(j, threshold(j), 'Parent', d, 'Color', [0 1 0], 'Marker', '*');
    title(d, 'Blue - Threshold from ctPsychFit, Green - Threshold from QUEST data')
    
    % put in the above loops minus plotting lines
    for i = 1:length(uLowCohDir20C)

        % boolean array: subthresh dir on this trial matches unique subthresh dir
        dirSelect = lowCohDir20CbySession == uLowCohDir20C(i);

        % data input to logist_fit
        choices = choices20CbySession(dirSelect);
        coherences = signCoh20CbySession(dirSelect).*highCoh20CbySession(dirSelect);
        uCoherences = unique(coherences);

        % data format for logist_fit
        data = [ones(size(coherences)), coherences, choices];

        % the logistic fits
        fits(i, :) = logist_fit(data, 'lu1', 'inits', inits);

        y = logist_val(fits(i, 1:2), axisData)*(1-fits(i, 3)*2) + fits(i,3);

        % explicitly compute the biases, interpolated from the fits, i.e.,
        % % get out relevant data from fits --> bias for *each* session block, by
        % angle
        bias20C(j,i) = abs(interp1(y, xAxis, .5));
        
        % color scheme --> convert index to binary...clever for < 8 colors
        color = dec2bin(colorIntegers(i), 3) == '1';
        yPos = i*.05;

        % go through each test coherence
        for k = 1:length(uCoherences)

            % group "right" percentage by coherences
            cohSelect = coherences == uCoherences(k);
            pRightByCoh(k) = mean(choices(cohSelect));

        end

%         % l1 = percent correct
%         l1 = line(uCoherences, pRightByCoh, 'Parent', ax, 'LineStyle', 'none',...
%             'Marker', '*', 'Color', color);
%         s = sprintf('session = %d, low coherence = %.2f',...
%              uSessionID(j), lowCohbySession);
%         s2 = sprintf('%d deg', uLowCohDir20C(i));
%         t1 = text(-95, .8, s);
%         t2 = text(85, yPos, s2, 'Color', color);
%         
%         % l2 = logistic fit showing bias as shift
%         l2 = line(xAxis, y, 'Parent', ax, 'LineStyle', '-',...
%         'Marker', 'none', 'Color', color);
%         
%         waitforbuttonpress;
%         delete([l1, t1]);

    end
    
    cla(ax);   



    
end









% output the final threshold estimates for each session
figure(100)
ax100 = axes('YLim', [0 100], 'XLim', [0 8]);
title('Threshold Estimates by Session Number, Red = 180C, Blue = 20C');

for i = 1:length(uSessionID)
    
    if mod(i,2) == 0
        color1 = 'red';
    else 
        color1 = 'blue';
    end
    
    thresh = line(uSessionID(i), threshold(i), 'Parent', ax100,...
        'LineStyle', '-', 'Marker', '*', 'Color', color1);
    
end


% PLOT BIAS(J,:) ON NEW AXES AX1, DO NOT DELETE BETWEEN LOOPS, also add
% the a color in the same type of scheme as above, maybe some text
% saying what session we're in
% augment bias20C by one row to make plots work
bias20C(8,:) = 0;

% make a figure first
figure(7)
clf
ax3 = axes('YLim', [0 100], 'XLim', [0 8]);
title('Average bias per session, across all angles');
    
for i = 1:length(uSessionID)
    
    color1 = dec2bin(colorIntegers(i), 3) == '1';
    yPos1 = i*.02;
    biasline = line(uSessionID(i), bias20C(i,:), 'Parent', ax3, 'LineStyle', '-', ...
                'Marker', '*', 'Color', color1);
    str = sprintf('session %d', uSessionID(i));
    txt = text(.05, yPos1, str, 'Color', color1);
    
    waitforbuttonpress;
    
end

% now we get the average bias, per session, across all angles
% first get some new axes

figure(8)
clf
ax4 = axes('YLim', [0 100], 'XLim', [0 8]);
title('Average bias per session, across all angles - Fine');

for i = 1:length(uSessionID)
    
    meanBias20C(i) = mean(bias20C(i,:));  
    color1 = dec2bin(colorIntegers(i), 3) == '1';
    yPos1 = i*5;
    biasline = line(uSessionID(i), meanBias20C(i), 'Parent', ax4, 'LineStyle', '-', ...
                'Marker', '*', 'Color', color1);
    str = sprintf('session %d', uSessionID(i));
    txt = text(.05, yPos1, str, 'Color', color1);
    
    
end

% next, we interleave the biases of each session to show the total average
% bias throughout training

figure(9)
clf
ax5 = axes('YLim', [0 100], 'XLim', [0 8]);
title('Average bias per session, across all angles - Both Tasks');

for i = 1:length(uSessionID)
    
    if meanBias180C(i) ~= 0
        meanBias(i) = meanBias180C(i);
        color = [1 0 0];
    elseif meanBias20C(i) ~= 0
        meanBias(i) = meanBias20C(i);
        color = [0 1 0];
    end
    
    yPos = i*5;
    biasline = line(uSessionID(i), meanBias(i), 'Parent', ax5,...
                'LineStyle', '-', 'Marker', '*', 'Color', color);
    str = sprintf('session %d', uSessionID(i));
    txt = text(.05, yPos, str, 'Color', color);
    
end

% figure(10)
% clf
% ax6 = axes('YLim', [0 100], 'XLim', [0 8]);
% title('Trend line for average bias across sessions - Both Tasks');
% 
% bias = line(uSessionID, meanBias, 'Parent', ax6, 'LineStyle', 'none', 'Marker', '*',...
%             'Color', [0 0 0]);
% lsline;

% get some plots of the most biasing angles for each task
% 180C --> 30(1), 150(5), 210(6), 330(10)
% 20C --> 30(2), 60(3), 120(5), 150(6)

% % first a figure for 180C
% figure(11)
% clf
% ax7 = axes('YLim', [0 100], 'XLim', [0 8]);
% title('Evolution of Most Biasing Angles - Coarse');
% 
% % 30 degrees
% for i = 1:length(uSessionID)
%     
%     if bias180C(i,1) ~= 0
%    
%         biasLine = line(uSessionID(i), bias180C(i,1), 'Parent', ax7,...
%                     'LineStyle', '-', 'Marker', '*', 'Color', [1 0 0]);
%         txt = text(.05, 5, '30 degrees', 'Color', [1 0 0]);
%     else
%     end
%     
% end
% 
% % 150 degrees
% for i = 1:length(uSessionID)
%     
%     if bias180C(i,5) ~= 0
%    
%         biasLine = line(uSessionID(i), bias180C(i,5), 'Parent', ax7,...
%                     'LineStyle', '-', 'Marker', '*', 'Color', [0 1 0]);
%         txt = text(.05, 10, '150 degrees', 'Color', [0 1 0]);
%     else
%     end
%     
% end
% 
% % 210 degrees
% for i = 1:length(uSessionID)
%     
%     if bias180C(i,6) ~= 0
%    
%         biasLine = line(uSessionID(i), bias180C(i,6), 'Parent', ax7,...
%                     'LineStyle', '-', 'Marker', '*', 'Color', [0 0 1]);
%         txt = text(.05, 15, '210 degrees', 'Color', [0 0 1]);
%     else
%     end
%     
% end
% 
% % 330 degrees
% for i = 1:length(uSessionID)
%     
%     if bias180C(i,10) ~= 0
%    
%         biasLine = line(uSessionID(i), bias180C(i,10), 'Parent', ax7,...
%                     'LineStyle', '-', 'Marker', '*', 'Color', [0 1 1]);
%         txt = text(.05, 20, '330 degrees', 'Color', [0 1 1]);
%     else
%     end
%     
% end

% % then one just for 20C
% figure(12)
% clf
% ax8 = axes('YLim', [0 100], 'XLim', [0 8]);
% title('Evolution of Most Biasing Angles - Fine');
% 
% % 30 degrees
% for i = 1:length(uSessionID)
%     
%     if bias20C(i,1) ~= 0
%    
%         biasLine = line(uSessionID(i), bias20C(i,2), 'Parent', ax8,...
%                     'LineStyle', '-', 'Marker', '*', 'Color', [1 0 0]);
%         txt = text(.05, 5, '30 degrees', 'Color', [1 0 0]);
%     else
%     end
%     
% end
% 
% % 60 degrees
% for i = 1:length(uSessionID)
%     
%     if bias20C(i,3) ~= 0
%    
%         biasLine = line(uSessionID(i), bias20C(i,3), 'Parent', ax8,...
%                     'LineStyle', '-', 'Marker', '*', 'Color', [0 1 0]);
%         txt = text(.05, 10, '60 degrees', 'Color', [0 1 0]);
%     else
%     end
%     
% end
% 
% % 120 degrees
% for i = 1:length(uSessionID)
%     
%     if bias20C(i,5) ~= 0
%    
%         biasLine = line(uSessionID(i), bias20C(i,5), 'Parent', ax8,...
%                     'LineStyle', '-', 'Marker', '*', 'Color', [0 0 1]);
%         txt = text(.05, 15, '120 degrees', 'Color', [0 0 1]);
%     else
%     end
%     
% end
% 
% % 150 degrees
% for i = 1:length(uSessionID)
%     
%     if bias20C(i,6) ~= 0
%    
%         biasLine = line(uSessionID(i), bias20C(i,6), 'Parent', ax8,...
%                     'LineStyle', '-', 'Marker', '*', 'Color', [0 1 1]);
%         txt = text(.05, 20, '150 degrees', 'Color', [0 1 1]);
%     else
%     end
%     
% end




