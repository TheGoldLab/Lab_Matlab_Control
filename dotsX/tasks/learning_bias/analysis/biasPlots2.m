% learningBias_biasPlots

% Copyright 2008 Benjamin Naecker University of Pennsylvania

% take FIRAs and create plots which show (1) bias as a shift in a logistic
% plot (2) relative bias as shift in the percentage of 'rightward'
% choices (cf. Jazayeri/Movshon 2007) (3) plots of QUEST sessions (4) QUEST
% threshold estimates over the course of learning and (5) the time course
% of the effect of biasing stimuli

% preprocess multiple FIRA structures

% clear all
% concatenateFIRAs
[uNames, tnID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(300,20);
uSessionID = unique(sessionID);

global FIRA
tnID = tnID';

% SORT DATA by task, subthreshold direction, test direction, and test
% coherence, using method of logical selectors

%% by TASK

% a little trick to get rid of some pesky data sneaking into other
% sessions...
Lblock = isfinite(FIRA.ecodes.data(:,25));
Lblock = Lblock';

if any(strcmp(uNames, 'BiasLever_180C'))
    select180C = Lblock & find(strcmp(uNames, 'BiasLever_180C')) == tnID;
end

if any(strcmp(uNames, 'BiasLever_180Q'))
    select180Q = Lblock & find(strcmp(uNames, 'BiasLever_180Q')) == tnID;
end

if any(strcmp(uNames, 'BiasLever_20C'))
    select20C = Lblock & find(strcmp(uNames, 'BiasLever_20C')) == tnID;
end

if any(strcmp(uNames, 'BiasLever_20Q'))
    select20Q = Lblock & find(strcmp(uNames, 'BiasLever_20Q')) == tnID;
end

%% FIRA selectors

% relevant FIRA data columns

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
eBiasDir = strcmp(FIRA.ecodes.name, 'low_coh_dot_dir');
eTestDir = strcmp(FIRA.ecodes.name, 'high_coh_dot_dir');
eTestCoh = strcmp(FIRA.ecodes.name, 'high_coh');
eRight = strcmp(FIRA.ecodes.name, 'right');
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
eSessionID = strcmp(FIRA.ecodes.name, 'sessionID');
eQUESTCoh = strcmp(FIRA.ecodes.name, 'dot_coh_92_used');

% select for good trials

selectGood = FIRA.ecodes.data(:, eGood);
selectGood = selectGood';

%% ORGANIZE C TRIALS INTO DATA STRUCTURES

% extract relevant data from above columns

biasDir180C = FIRA.ecodes.data(select180C & selectGood, eBiasDir);
biasDir20C = FIRA.ecodes.data(select20C & selectGood, eBiasDir);
testDir180C = FIRA.ecodes.data(select180C & selectGood, eTestDir);
testDir20C = FIRA.ecodes.data(select20C & selectGood, eTestDir);
testCoh180C = FIRA.ecodes.data(select180C & selectGood, eTestCoh);
testCoh20C = FIRA.ecodes.data(select20C & selectGood, eTestCoh);

% subject's choice

rightChoice180C = ~isnan(FIRA.ecodes.data(select180C & selectGood, eRight));
rightChoice20C = ~isnan(FIRA.ecodes.data(select20C & selectGood, eRight));

% were they correct?

correctChoice180C = ~isnan(FIRA.ecodes.data(select180C & selectGood, eCorrect));
correctChoice20C = ~isnan(FIRA.ecodes.data(select20C & selectGood, eCorrect));

% get out the sessionID numbers for all the 180C and 20C trials

sessionID180C = FIRA.ecodes.data(select180C & selectGood, eSessionID);
sessionID20C = FIRA.ecodes.data(select20C & selectGood, eSessionID);

tempSessionID180C = unique(sessionID180C);
uSessionID180C = tempSessionID180C(~isnan(tempSessionID180C));
tempSessionID20C = unique(sessionID20C);
uSessionID20C = tempSessionID20C(~isnan(tempSessionID20C));

% for 180C trials, construct array with unique bias coherence directions, signing them with
% left = -1, right = 1.  construct array with unique test directions, same
% sign convention.

uBiasDir180C = unique(biasDir180C);
testSign180C = 2*(testDir180C < 90) - 1;
uTestCoh180C = unique(testCoh180C);
allSignedTestCoherences180C = [uTestCoh180C; -uTestCoh180C];

% for 20C trials, construct array with unique bias coherence directions, signing them with
% left = -1, right = 1.  construct array with unique test directions, same
% sign convention.

uBiasDir20C = unique(biasDir20C);
testSign20C = 2*(testDir20C < 90) - 1;
uTestCoh20C = unique(testCoh20C);
allSignedTestCoherences20C = [uTestCoh20C; -uTestCoh20C];

% concat all info together into lists for 180C and 20C.  this way we can
% pull out the same info, but it is indexed by the sessionID number
% this is kind of a roundabout method, since i'm essentially creating a
% smaller FIRA, but this way it's indexed and set up the way i want...
%% contains: sessionID biasDir testDir testCoh testSign rightChoice correctChoice

data180C = [sessionID180C biasDir180C testDir180C testCoh180C testSign180C rightChoice180C correctChoice180C];
data20C = [sessionID20C biasDir20C testDir20C testCoh20C testSign20C rightChoice20C correctChoice20C];

% stem plot will show informally whether the selectors worked.  i.e., the
% stem plot blocks should alternate and should be about 800 trials apart

% stem(FIRA.ecodes.data(:, eTestCoh))

% color scheme - group trials by direction of biasing stimulus, with
% symmetry with respect to 90 deg
L = length(uBiasDir180C);
colorInts = [1:(L/2), 1:(L/2)];

%% INITS to logistic fit function
% syntax of logist_fit is [fits_, sems_, stats_, preds_, resids_] =
% logist_fit(data, lumode, varargin)

inits = [0 -10 10; .02 .02 .2; .01 0 .2];

%% LOOP through unique sessions

for ii = 1:length(uSessionID180C)
    
    % subplot mechanisms
    figure(1)
    ax = subplot(2,3,ii, 'YLim', [0 1], 'XLim', [-100 100]);
    s = sprintf('Session %d', uSessionID180C(ii));
    title(s);
    xAxis = linspace(-100, 100, 1000);
    axisData = [ones(1000,1), xAxis'];

    % get the right indices to data180C for this session
    
    indices = find(sessionID180C == uSessionID180C(ii));
    CSData180C = data180C(indices, :);
    
    % get the important info
    
    CSBiasDir180C = CSData180C(:, 2);
    CSTestDir180C = CSData180C(:, 3);
    CSTestCoh180C = CSData180C(:, 4);
    CSTestSign180C = CSData180C(:, 5);
    CSRightChoice180C = CSData180C(:, 6);
    CSCorrectChoice180C = CSData180C(:, 7);

    %% LOOP through 180C trials
    % loop goes through bias directions, then by test coherences

    for i = 1:length(uBiasDir180C)

        % define boolean array selecting bias direction which matches unique
        % bias direction

        dirSelect = CSBiasDir180C == uBiasDir180C(i);

        % compute color scheme
        %%% NOT IDEAL FOR > 8 COLORS

        color = dec2bin(colorInts(i), 3) == '1';

        % data input to logist_fit function

        choices = CSRightChoice180C(dirSelect);
        coherences = CSTestSign180C(dirSelect).*CSTestCoh180C(dirSelect);
        uCoherences = unique(coherences);

        % format data for logist_fit

        data = [ones(size(coherences)), coherences, choices];

        % now we compute the percentage of rightward choices, the bias, cf
        % Jazayeri & Movshon 2007

        pRight180(i) = mean(choices);

        % the actual logistic fit function

        fits(i, :) = logist_fit(data, 'lu1', 'inits', inits);

        % now loop through each test coherence

        for j = 1:length(allSignedTestCoherences180C)

            % and group 'right' percentages computed above by test coherence

            cohSelect = coherences == allSignedTestCoherences180C(j);
            pRightByCoh180C(j) = mean(choices(cohSelect));

        end

        % PLOTS
        % first the relative bias

        l1 = line(allSignedTestCoherences180C, pRightByCoh180C, 'Parent', ax, ...
            'Linestyle', 'none', 'Marker', '*', 'Color', color);
        s = num2str(uBiasDir180C(i));
        st = text(90,.03*i,s, 'Color', color);

        % then the logistic plots showing bias as shift

        y = logist_val(fits(i, 1:2), axisData);
        l2 = line(xAxis, y*(1-fits(i, 3)*2) + fits(i,3), 'Parent', ax, ...
            'LineStyle', '-', 'Marker', 'none', 'Color', color);

        % optional controlled loop through each coherence group
    %     waitforbuttonpress;
    %     delete([l1, l2, st]);

        % explicitly compute the biases, interpolated from the fits function
        bias180C(ii, i) = interp1(y, xAxis, .5);

    end
    
    
    %% PLOTS of relative bias by biasing angle
    figure(2)
    a = subplot(2,3,ii, 'YLim', [-100 100], 'XLim', [0 360]);
    plot(uBiasDir180C, pRight180./max(pRight180))
    s = sprintf('Session %d', uSessionID180C(ii));
    title(s);
    
%     % plots of explicit bias by biasing angle
%     figure(3)
%     b = subplot(2,3,ii);
%     plot(uBiasDir180C, bias180C);
%     title(s);
    
end



% color scheme - group trials by direction of biasing stimulus, with
% symmetry with respect to 90 deg
L = length(uBiasDir20C);
colorInts = [1:(L/2), 0, 1:(L/2)];

%% INITS to logistic fit function
% syntax of logist_fit is [fits_, sems_, stats_, preds_, resids_] =
% logist_fit(data, lumode, varargin)

inits = [0 -10 10; .02 .02 .2; .01 0 .2];

%% LOOP through unique 20C sessions

for ii = 1:length(uSessionID20C)
    
    % subplot mechanisms
    figure(4)
    ax = subplot(2,3,ii, 'YLim', [0 1], 'XLim', [-100 100]);
    s = sprintf('Session %d', uSessionID20C(ii));
    title(s);
    xAxis = linspace(-100, 100, 1000);
    axisData = [ones(1000,1), xAxis'];
    
    % get the right indices
    
    indices = find(sessionID20C == uSessionID20C(ii));
    CSData20C = data20C(indices, :);
    
    % get the right data
    
    CSBiasDir20C = CSData20C(:, 2);
    CSTestDir20C = CSData20C(:, 3);
    CSTestCoh20C = CSData20C(:, 4);
    CSTestSign20C = CSData20C(:, 5);
    CSRightChoice20C = CSData20C(:, 6);
    CSCorrectChoice20C = CSData20C(:, 7);

    %% LOOP through 20C trials
    % loop goes through bias directions, then by test coherences

    for i = 1:length(uBiasDir20C)

        % define boolean array selecting bias direction which matches unique
        % bias direction

        dirSelect = CSBiasDir20C == uBiasDir20C(i);

        % compute color scheme
        %%% NOT IDEAL FOR > 8 COLORS

        color = dec2bin(colorInts(i), 3) == '1';

        % data input to logist_fit function

        choices = CSRightChoice20C(dirSelect);
        coherences = CSTestSign20C(dirSelect).*CSTestCoh20C(dirSelect);
        uCoherences = unique(coherences);

        % format data for logist_fit

        data = [ones(size(coherences)), coherences, choices];

        % now we compute the percentage of rightward choices, the bias, cf
        % Jazayeri & Movshon 2007

        pRight20(i) = mean(choices);

        % the actual logistic fit function

        fits(i, :) = logist_fit(data, 'lu1', 'inits', inits);

        % now loop through each test coherence

        for j = 1:length(allSignedTestCoherences20C)

            % and group 'right' percentages computed above by test coherence

            cohSelect = coherences == allSignedTestCoherences20C(j);
            pRightByCoh20C(j) = mean(choices(cohSelect));

        end

        % PLOTS
        % first the relative bias

        l1 = line(allSignedTestCoherences20C, pRightByCoh20C, 'Parent', ax, ...
            'Linestyle', 'none', 'Marker', '*', 'Color', color);
        s = num2str(uBiasDir20C(i));
        st = text(90,.03*i,s, 'Color', color);

        % then the logistic plots showing bias as shift

        y = logist_val(fits(i, 1:2), axisData);
        l2 = line(xAxis, y*(1-fits(i, 3)*2) + fits(i,3), 'Parent', ax, ...
            'LineStyle', '-', 'Marker', 'none', 'Color', color);

        % optional controlled loop through each coherence group
    %     waitforbuttonpress;
    %     delete([l1, l2, st]);

        % explicitly compute the biases, interpolated from the fits function
        bias20C(ii, i) = interp1(y, xAxis, .5);

    end
    
    % graphs showing relative bias by angle
    figure(5)
    a = subplot(2,3,ii);
    plot(uBiasDir20C, pRight20);
    s = sprintf('Session %d', uSessionID20C(ii));
    title(s);
    
%     % graphs showing explicit bias by angle
%     figure(6)
%     b = subplot(2,3,ii);
%     plot(uBiasDir20C, bias20C)
%     title(s);
    
end

%% ORGANIZE QUEST TRIALS INTO DATA STRUCTURES

tempSessionID180Q = FIRA.ecodes.data(selectGood & select180Q, eSessionID);
sessionID180Q = tempSessionID180Q(~isnan(tempSessionID180Q));
uSessionID180Q = unique(sessionID180Q);
tempSessionID20Q = FIRA.ecodes.data(selectGood & select20Q, eSessionID);
sessionID20Q = tempSessionID20Q(~isnan(tempSessionID20Q));
uSessionID20Q = unique(sessionID20Q);

% get out QUEST coherences for all 180Q/20Q trials
QUESTCoh180Q = FIRA.ecodes.data(selectGood & select180Q, eQUESTCoh);
QUESTCoh20Q = FIRA.ecodes.data(selectGood & select20Q, eQUESTCoh);

% small loops to get out last QUEST coherences from each session (i.e., the
% threshold estimate for that QUEST session)

tempCoh180Q = zeros(90, length(uSessionID180Q));
tempCoh20Q = zeros(90, length(uSessionID20Q));
CSQUESTCoh180Q = zeros(90*length(uSessionID180Q));
CSQUESTCoh20Q = zeros(90*length(uSessionID20Q));

data180Q = zeros(length(sessionID180Q),2);
data20Q = zeros(length(sessionID20Q),2);

for i = 1:length(uSessionID180Q)
    
   tempCoh180Q(:,i) = QUESTCoh180Q(sessionID180Q == uSessionID180Q(i));
%    thresh180Q(i) = CSQUESTCoh180Q(numel(CSQUESTCoh180Q));
       
end

CSQUESTCoh180Q = reshape(tempCoh180Q, 90*length(uSessionID180Q), 1);

for i = 1:length(uSessionID20Q)
    
   tempCoh20Q(:,i) = QUESTCoh20Q(sessionID20Q == uSessionID20Q(i));
%    thresh20Q(i) = CSQUESTCoh20Q(numel(CSQUESTCoh20Q));
    
end

CSQUESTCoh20Q = reshape(tempCoh20Q, 90*length(uSessionID20Q), 1);

% concat all info together into lists for 180Q and 20Q
%% contains: sessionID allQUESTCohs

data180Q = [sessionID180Q CSQUESTCoh180Q];
data20Q = [sessionID20Q CSQUESTCoh20Q];

%%%%%%%%%%  what else do i need in data180Q/20Q?  what other QUEST data
%%%%%%%%%%  should i store from FIRA?

%% QUEST plots by session
for i = 1:length(uSessionID180Q)
    
    % get all QUEST coherences presented during current session
    CSQUESTCohs180Q = tempCoh180Q(:,i);
    CSThresh180Q(i) = CSQUESTCohs180Q(length(CSQUESTCohs180Q));
    
    % first - all coherences from each session's QUEST
    figure(7)
    a = subplot(2,3,i, 'YLim', [0 50], 'XLim', [0 90]);
    plot(1:90, CSQUESTCohs180Q, 'Marker', '*', 'LineStyle', 'none');
        
end

for i = 1:length(uSessionID20Q)
    
    % get all QUEST coherences presented during current session
    CSQUESTCohs20Q = tempCoh20Q(:,i);
    CSThresh20Q(i) = CSQUESTCohs20Q(length(CSQUESTCohs20Q));
    
    % first - all coherences from each session's QUEST
    figure(8)
    a = subplot(2,3,i, 'YLim', [0 50], 'XLim', [0 90]);
    plot(1:90, CSQUESTCohs20Q, 'Marker', '*', 'LineStyle', 'none', 'Color', 'g');
        
end

figure(9)
a = axes('YLim', [0 50], 'XLim', [0 12]);
plot(1:2:9, CSThresh180Q, 'Marker', '*', 'LineStyle', 'none');
figure(10)
b = axes('YLim', [0 50], 'XLim', [0 12]);
plot(2:2:10, CSThresh20Q, 'Marker', '*', 'LineStyle', 'none', 'Color', 'g');


%% PLOTS OF BIAS v SESSION BY ANGLE

for i = 1:length(uBiasDir180C)
    
    figure(11)
    subplot(3,4,i, 'YLim', [-80 60], 'XLim', [0 10]);
    
    biasLine = line(uSessionID180C, bias180C(:,i), 'LineStyle', '-', 'Marker', '*');
   s = sprintf('Angle = %d', uBiasDir180C(i));
   title(s);
    
end

for i = 1:length(uBiasDir20C)
    
    figure(12)
    subplot(4,4,i, 'YLim', [-80 60], 'XLim', [0 10]);
    
    biasLine = line(uSessionID20C, bias20C(:,i), 'LineStyle', '-', 'Marker', '*');
   s = sprintf('Angle = %d', uBiasDir20C(i));
   title(s);
    
end


%% PLOTS OF BIAS v ANGLE BY SESSION -- SHIFTS TAKEN FROM LOGISTIC PLOTS

for i = 1:length(uSessionID180C)
    
    figure(13)
    subplot(2,3,i, 'YLim', [-100 100], 'XLim', [0 360]);
    
    biasLine = line(uBiasDir180C, -bias180C(i,:), 'LineStyle', '-', 'Marker', '*');
    s = sprintf('Session %d', uSessionID180C(i));
    title(s)
    
end

for i = 1:length(uSessionID20C)
    
    figure(14)
    subplot(2,3,i, 'YLim', [-100 100], 'XLim', [0 180]);
    
    biasLine = line(uBiasDir20C, -bias20C(i,:), 'LineStyle', '-', 'Marker', '*', 'Color', 'g');
    s = sprintf('Session %d', uSessionID20C(i));
    title(s)
    
end

%% NORMALIZATION OF ABOVE CURVES (RELATIVE TO MAX VALUE, also switched sign)

for i = 1:length(uSessionID180C)
    
    figure(15)
    subplot(2,3,i, 'YLim', [-1 1], 'XLim', [0 360]);
    
    normBias180C(i,:) = -bias180C(i,:)./max(abs(bias180C(i,:)));
    
    biasLine = line(uBiasDir180C, normBias180C(i,:), 'LineStyle', '-', 'Marker', '*');
    s = sprintf('Session %d', uSessionID180C(i));
    title(s)
    
end

for i = 1:length(uSessionID20C)
    
    figure(16)
    subplot(2,3,i, 'YLim', [-1 1], 'XLim', [0 180]);
    
    normBias20C(i,:) = -bias20C(i,:)./max(abs(bias20C(i,:)));
    
    biasLine = line(uBiasDir20C, normBias20C(i,:), 'LineStyle', '-', 'Marker', '*', 'Color', 'g');
    s = sprintf('Session %d', uSessionID20C(i));
    title(s)
    
end

%% NORMALIZATION OF ABOVE CURVES, THIS TIME WITH MIN/MAX VALUES SET TO -1/1

for i =  1:length(uSessionID180C)
    
    % method to set min and max to -1/1 --> scale so min - max = 2, then
    % shift to -1/1
    U = max(normBias180C(i,:));
    L = min(normBias180C(i,:));
    
    S = 2/(U - L);
    
    tempNormBias180C(i,:) = S.*normBias180C(i,:);
    
    T = max(tempNormBias180C(i,:)) - 1;
    
    scaledNormBias180C(i,:) = tempNormBias180C(i,:) - T;
    
    figure(17)
    subplot(2,3,i, 'YLim', [-1 1], 'XLim', [0 360])
    
    biasLine = line(uBiasDir180C, scaledNormBias180C(i,:), 'LineStyle', '-', 'Marker', '*');
    s = sprintf('Session %d', uSessionID180C(i));
    title(s)
    
end

for i =  1:length(uSessionID20C)
    
    % method to set min and max to -1/1 --> scale so min - max = 2, then
    % shift to -1/1
    U = max(normBias20C(i,:));
    L = min(normBias20C(i,:));
    
    S = 2/(U - L);
    
    tempNormBias20C(i,:) = S.*normBias20C(i,:);
    
    T = max(tempNormBias20C(i,:)) - 1;
    
    scaledNormBias20C(i,:) = tempNormBias20C(i,:) - T;
    
    figure(18)
    subplot(2,3,i, 'YLim', [-1 1], 'XLim', [0 180])
    
    biasLine = line(uBiasDir20C, scaledNormBias20C(i,:), 'LineStyle', '-', 'Marker', '*',...
                    'Color', 'g');
    s = sprintf('Session %d', uSessionID20C(i));
    title(s)
    
end

%% FITTING GAUSSIANS TO THE DATA

% first split the data into two sections, 90 to -90 (Left), and -90 to 90
% (Right)
% REMEMBER: datasets now contain one column for angles and the rest are the
% data for each SESSION
L180 = [90; 120; 150; 180; 210; 240; 270;];
tempLFitData180C = [scaledNormBias180C(:,4)'; scaledNormBias180C(:,5)'; ...
                scaledNormBias180C(:,6)'; scaledNormBias180C(:,7)'; scaledNormBias180C(:,8)'; ...
                scaledNormBias180C(:,9)'; scaledNormBias180C(:,10)';];

LFitData180C = [L180, tempLFitData180C];            
            
R180 = [270; 300; 330; 0; 30; 60; 90;];
tempRFitData180C = [scaledNormBias180C(:,10)'; scaledNormBias180C(:,11)'; ...
    scaledNormBias180C(:,12)'; scaledNormBias180C(:,1)'; scaledNormBias180C(:,2)'; ...
    scaledNormBias180C(:,3)'; scaledNormBias180C(:,4)';];

RFitData180C = [R180, tempRFitData180C];




%%%%%% check to make sure this is the right data organization!!



L20 = [0; 15; 30; 45; 60; 75; 90;];
tempLFitData20C = [scaledNormBias20C(:,7)'; scaledNormBias20C(:,8)'; ...
                scaledNormBias20C(:,9)'; scaledNormBias20C(:,10)'; scaledNormBias20C(:,11)'; ...
                scaledNormBias20C(:,12)'; scaledNormBias20C(:,13)';];
            
LFitData20C = [L20, tempLFitData20C];             
            
R20 = [90; 105; 120; 135; 150; 165; 180;];            
tempRFitData20C = [scaledNormBias20C(:,10)'; scaledNormBias20C(:,11)'; ...
    scaledNormBias20C(:,12)'; scaledNormBias20C(:,1)'; scaledNormBias20C(:,2)'; ...
    scaledNormBias20C(:,3)'; scaledNormBias20C(:,4)';];

RFitData20C = [R20, tempRFitData20C]; 

% let fmincon minimize a Gaussian for each data set; need one Gaussian for
% each SESSION

% FIRST 180 tasks


%%% what is going ON???!?!?  why does fmincon hate me?!

Lxs = [90:270];
Rxs = [270:450]; ...need to modulate this so that it wraps around...

for i = 1:length(uSessionID180C)
    
    LData = [LFitData180C(:,1) LFitData180C(:,i+1) zeros(length(L180),1)];
        
    Lparams = fmincon(@gauss_err, [0 0 0], [], [], [], [], [-360 -360 -10], [360 360 10], [], [],...
                        LData);
                
    RData = [RFitData180C(:,1) RFitData180C(:,i)  zeros(length(R180),1)] ;             
                
    Rparams = fmincon(@gauss_err, [0 0 0], [], [], [], [], [-360 -360 -10], [360 360 10], [], [],...
                        RData);
                    
    figure(19)
    subplot(3,2,i, 'YLim', [-1 1], 'XLim', [0 360])
    
    LGuassLine = plot(Lxs, (1/(sqrt(2*pi)*Lparams(2))) * (exp(-(Lxs-Lparams(1))/(2*Lparams(2)^2))));
    RGaussLine = plot(Rxs, (1/(sqrt(2*pi)*Rparams(2))) * (exp(-(Rxs-Rparams(1))/(2*Rparams(2)^2))));
    
end

% 20 Tasks

Lxs = [0:90];
Rxs = [90:180];

for i = 1:length(uSessionID20C)
    
    LData = [LFitData20C(:,1) LFitData20C(:,i+1), zeros(length(L20),1)];
    
    Lparams = fmincon(@gauss_err, [0 0 0], [], [], [], [], [-360 -360 -10], [360 360 10], [], [],...
                        LData);
    
    
end



