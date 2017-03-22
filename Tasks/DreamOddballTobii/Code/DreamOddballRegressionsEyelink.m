%% DreamOddball Regressions
% By M.Kabir
clear all
subID = 'IJ'; %Write the Two letter string here to pool subject data, leave empty to pool all subjects

files = dir(['0Fused_' subID '*.mat']); 
X_matrix = [];
Y_matrix = [];

%Loop to build features matrices
for z = 1:length(files)

    load(files(z).name)

    ld = Data.pupilDiameter';
    eyetime = Data.eyelinkTimeStamps';

    %clean
    ld = pupilclean(ld, 2);

    %find sound time stamps in terms of idx
    playtimes = Data.eyelinkStimTimes;
    stim_idx = arrayfun(@(x) find(eyetime <= x, 1, 'last'), playtimes, 'UniformOutput', 1); %arrayfun(@(x) max(find(eyetime <= x)), playtimes', 'UniformOutput', 1);
    stim_times = eyetime(stim_idx);

    % Setting window sizes for pre and post stimulus clips of the pupil 
    % waveform.
    prewindow = 1000;
    postwindow = 3000;

    % Collecting pre and postpackets
    pre = zeros(length(stim_idx), prewindow);
    post = zeros(length(stim_idx), postwindow);
    skippedwaves = [];
    for i = 1:length(stim_idx)
        if stim_idx(i)-prewindow < 1 || stim_idx(i) + postwindow - 1 > length(ld)
            fprintf('Skipping waves %d', i);
            skippedwaves(end+1) = i;
            continue
        end
        pre(i,:) = ld(stim_idx(i)-prewindow:stim_idx(i)-1);
        post(i,:) = ld(stim_idx(i):stim_idx(i) + postwindow - 1);
    end
    
    %Cutting out the skipped waves:
    pre(skippedwaves,:) = [];
    post(skippedwaves, :) = [];

    % Getting multiple timewindows of postwave stuff
    window = 200;
    shift = 50;
    timebins = (postwindow-window)/shift;
    postmatrix = zeros(size(post, 1), window, timebins);

    %Get 3D matrix with individual timebins in 3rd dimension
    %Each row is a different trial
    %Each column is a sample
    %Each 3rd dimension is a time bin
    counter = 0;
    for i = 1:timebins
        postmatrix(:,:,i) = post(:, counter*shift + 1 : counter*shift + window);
        counter = counter + 1;
    end

    %Build predictive features matrix:  baseline pupil mean, intercept, motor responses, oddball
    %or no, difference of frequency, distractor_on
    premeans = mean(pre,2);
    intercept = ones(length(premeans), 1);
    
    %Getting 'motor effort' column in features matrix
    motors = zeros(300,1);
    for i = 1:length(motors)
        %Calculating 'effort' to respond
        Rvec = Data.trueMotorResponses{i};
        if isempty(Rvec)
            motors(i) = 0; %If no buttons were pressed, it is a '0' in the motor explanatory variable column
            continue
        end
        
        Rvec(Rvec == 2) = 1;
        Rvec(Rvec == 4) = 2; %Changing 4s and 2s to 1s and 2s for easy tabulation

        mix = tabulate(Rvec); %Getting how many lefts vs. rights
        total = sum(mix(:,2)); %Total buttons required to be pressed
        lefts = mix(1,2); %Lefts required to press
    
        %Calculating number of left/right sequences possible to generate with
        %this proportion of left/rights
        listperms = factorial(total)/(factorial(total - lefts)*factorial(lefts));

        %Getting effort as a combo of sequence length/complexity
        effort = (log2(listperms)+ 1)*total;
        
        motors(i) = effort; %Saving final effort tally in 'motors' explanatory variable column 
    end
    
    %Oddball features column
    oddball = Data.StimFrequencies == Data.StandardFreq;
    oddball = ~oddball; %Ones for oddball freqs, 0s for standards
    
    %Frequency difference features column
    freqdiffs = Data.StimFrequencies - Data.StandardFreq;
    
    %Column to say whether distractors were on
    distractvector = ones(length(premeans),1) * Data.DistractorOn;
    
    %Extras
    rtype = sum(motors > 0) > length(motors)/2;
    rtype = ~rtype;
    responsetype = zeros(length(premeans), 1) + rtype;
    
    %Finalizing features matrix
    X = [intercept, premeans, motors, oddball', freqdiffs', distractvector, responsetype];
    
    
    X_matrix = [X_matrix; X];

    %Build predicted features matrix. Each 3d slice is a timebin. Every row is
    %our chosen feature extracted from the post-stim dilation of a particular
    %trial for that timebin. 
    feature = @(x) max(x);
    postfeatures = zeros(size(post,1), 1, timebins);
    for i = 1:timebins
        for j = 1:size(post,1) %for every row, grab a feature
            postfeatures(j,:,i) = feature(postmatrix(j,:,i));
        end
    end

    Y_matrix = [Y_matrix; postfeatures];

end

%% Paring the matrix
X_matrix(:, [5 6]) = [];

%% Performing a regression for every timebin and grabbing betas.
betas = zeros(timebins, size(X_matrix,2)); %Each row is a timebin.

%Performing regressions.
%Y_matrix(:,:,n) should give a column of features for one
%particular timebin.
for n = 1:timebins
    betas(n, :) = (X_matrix'*X_matrix)\X_matrix'*Y_matrix(:,:,n);
end

%To plot, then, plot the betas columnwise! Because each row is a
%progressive timebin. Each column is an explanatory variable. 
figure
for n = 2:size(betas,2)
    plot(betas(:,n));
    hold on
end

legend('Mean Pre-Stimulus', 'Motor Response', 'Oddball', ... 
        'Response Type');
title(['Subject: ' subID])
xlabel('Timebin (each bin is 200 samples, slid 50 samples at a time)')
ylabel('Beta-Coefficient Value')