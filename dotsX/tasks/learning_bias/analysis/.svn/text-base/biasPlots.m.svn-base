% learningBias_biasPlots

% Copyright 2008 Benjamin Naecker

% take FIRAs and create plots which show (1) bias as a shift in a logistic
% plot and (2) relative bias as shift in the percentage of 'rightward'
% choices (cf. Jazayeri/Movshon 2007)

% preprocess multiple FIRA structures

clear all
concatenateFIRAs
[uNames, tnID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(300,20);
uSessionID = unique(sessionID);

global FIRA
tnID = tnID';

% SORT DATA by task, subthreshold direction, test direction, and test
% coherence, using method of logical selectors

%% by TASK

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

%% FIRA selectors

% relevant FIRA data columns

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
eBiasDir = strcmp(FIRA.ecodes.name, 'low_coh_dot_dir');
eTestDir = strcmp(FIRA.ecodes.name, 'high_coh_dot_dir');
eTestCoh = strcmp(FIRA.ecodes.name, 'high_coh');
eRight = strcmp(FIRA.ecodes.name, 'right');
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
eSessionID = strcmp(FIRA.ecodes.name, 'sessionID');

% select for good trials

selectGood = FIRA.ecodes.data(:, eGood);
selectGood = selectGood';

% extract relevant data from above columns

biasDir180C = FIRA.ecodes.data(select180C & selectGood, eBiasDir);
biasDir20C = FIRA.ecodes.data(select20C & selectGood, eBiasDir);
testDir180C = FIRA.ecodes.data(select180C & selectGood, eTestDir);
testDir20C = FIRA.ecodes.data(select20C & selectGood, eTestDir);
testCoh180C = FIRA.ecodes.data(select180C & selectGood, eTestCoh);
testCoh20C = FIRA.ecodes.data(select20C & selectGood, eTestCoh);

% get out the sessionID numbers for all the 180C and 20C trials

sessionID180C = FIRA.ecodes.data(select180C & selectGood, eSessionID);
sessionID20C = FIRA.ecodes.data(select20C & selectGood, eSessionID);

uSessionID180C = unique(sessionID180C);
uSessionID20C = unique(sessionID20C);

% concat all info together into lists for 180C and 20C.  this way we can
% pull out the same info, but it is indexed by the sessionID number

data180C = [sessionID180C biasDir180C testDir180C testCoh180C];
data20C = [sessionID20C biasDir20C testDir20C testCoh20C];

% stem plot will show informally whether the selectors worked.  i.e., the
% stem plot blocks should alternate and should be about 800 trials apart

% stem(FIRA.ecodes.data(:, eTestCoh))

%% SUBJECT'S CHOICE

rightChoice180C = ~isnan(FIRA.ecodes.data(select180C & selectGood, eRight));
rightChoice20C = ~isnan(FIRA.ecodes.data(select20C & selectGood, eRight));

%% PREPARE 180C TRIALS
% construct array with unique bias coherence directions, signing them with
% left = -1, right = 1.  construct array with unique test directions, same
% sign convention.

uBiasDir180C = unique(biasDir180C);
signCoh180C = 2*(testDir180C < 90) - 1;
uTestCoh180C = unique(testCoh180C);
allSignedTestCoherences180C = [uTestCoh180C; -uTestCoh180C];

% color scheme - group trials by direction of biasing stimulus, with
% symmetry with respect to 90 deg
L = length(uBiasDir180C);
colorInts = [1:(L/2), 1:(L/2)];

%% INITS to logistic fit function
% syntax of logist_fit is [fits_, sems_, stats_, preds_, resids_] =
% logist_fit(data, lumode, varargin)

inits = [0 -10 10; .02 .02 .2; .01 0 .2];

%% PREPARE FIGURE
figure(1)
clf

%% LOOP through unique sessions

for ii = 1:length(uSessionID180C)
    
    % NEED TO INLCUDE SUBPLOT MECHANISMS HERE
    ax = axes('YLim', [0 1], 'XLim', [-100 100]);
    xAxis = linspace(-100, 100, 1000);
    axisData = [ones(1000,1), xAxis'];




    
    sessBiasDir180C = biasDir180C();

    %% LOOP through 180C trials
    % loop goes through bias directions, then by test coherences

    for i = 1:length(uBiasDir180C)

        % define boolean array selecting bias direction which matches unique
        % bias direction

        dirSelect = biasDir180C == uBiasDir180C(i);

        % compute color scheme
        %%% NOT IDEAL FOR > 8 COLORS

        color = dec2bin(colorInts(i), 3) == '1';

        % data input to logist_fit function

        choices = rightChoice180C(dirSelect);
        coherences = signCoh180C(dirSelect).*testCoh180C(dirSelect);

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
            pRightByCoh(j) = mean(choices(cohSelect));

        end

        % PLOTS
        % first the relative bias

        l1 = line(allSignedTestCoherences180C, pRightByCoh, 'Parent', ax, ...
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

    %     % explicitly compute the biases, interpolated from the fits function
    %     bias180C(i) = interp1(y, xAxis, .5);

    end
    
end

%% PREPARE 20C TRIALS
% construct array with unique bias coherence directions, signing them with
% left = -1, right = 1.  construct array with unique test directions, same
% sign convention.

uBiasDir20C = unique(biasDir20C);
signCoh20C = 2*(testDir20C < 90) - 1;
uTestCoh20C = unique(testCoh20C);
allSignedTestCoherences20C = [uTestCoh20C; -uTestCoh20C];

%% PREPARE FIGURE
figure(2)
clf
ax = axes('YLim', [0 1], 'XLim', [-100 100]);
xAxis = linspace(-100, 100, 1000);
axisData = [ones(1000,1), xAxis'];

% color scheme - group trials by direction of biasing stimulus, with
% symmetry with respect to 90 deg
L = length(uBiasDir20C);
colorInts = [1:(L/2), 0, 1:(L/2)];

%% INITS to logistic fit function
% syntax of logist_fit is [fits_, sems_, stats_, preds_, resids_] =
% logist_fit(data, lumode, varargin)

inits = [0 -10 10; .02 .02 .2; .01 0 .2];

%% LOOP through 20C trials
% loop goes through bias directions, then by test coherences

for i = 1:length(uBiasDir20C)
   
    % define boolean array selecting bias direction which matches unique
    % bias direction
    
    dirSelect = biasDir20C == uBiasDir20C(i);
    
    % compute color scheme
    %%% NOT IDEAL FOR > 8 COLORS
    
    color = dec2bin(colorInts(i), 3) == '1';
    
    % data input to logist_fit function
    
    choices = rightChoice20C(dirSelect);
    coherences = signCoh20C(dirSelect).*testCoh20C(dirSelect);
    
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
        pRightByCoh(j) = mean(choices(cohSelect));
        
    end
    
    % PLOTS
    % first the relative bias
    
    l1 = line(allSignedTestCoherences20C, pRightByCoh, 'Parent', ax, ...
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

%     % explicitly compute the biases, interpolated from the fits function
%     bias20C(i) = interp1(y, xAxis, .5);
    
end

%% ADD IN EXPLICIT BIAS/ANGLE PLOTS NEXT


