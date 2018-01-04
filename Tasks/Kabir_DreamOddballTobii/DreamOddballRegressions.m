%% DreamOddball Regressions
% By M.Kabir
clear all

files = dir('*.mat'); %Ensure only one subject's files are in the current directory!
X_matrix = [];
Y_matrix = [];

%Loop to build features matrices
for z = 1:length(files)

    load(files(z).name)

    ld = list{'Eye'}{'Right'};
    ld = ld(:,3);
    eyetime = list{'Eye'}{'Time'};
    eyetime = double(eyetime);

    %clean
    ld = pupilclean(ld);

    %find sound time stamps in terms of idx
    playtimes = list{'Stimulus'}{'Playtimes'}*(1e6); %in microseconds
    stim_idx = arrayfun(@(x) max(find(eyetime <= x)), playtimes', 'UniformOutput', 1);
    stim_times = eyetime(stim_idx);

    % Setting window sizes for pre and post stimulus clips of the pupil 
    % waveform.
    prewindow = 60;
    postwindow = 120;

    % Collecting pre and postpackets from 2:end-1, to avoid over-indexing
    pre = zeros(length(stim_idx), prewindow);
    post = zeros(length(stim_idx), postwindow);
    for i = 2:length(stim_idx)-2
        pre(i,:) = ld(stim_idx(i)-prewindow:stim_idx(i)-1,1);
        post(i,:) = ld(stim_idx(i):stim_idx(i) + postwindow - 1,1);
    end

    % Getting multiple timewindows of postwave stuff
    window = 20;
    shift = 5;
    timebins = (postwindow-window)/shift;
    postmatrix = zeros(length(post), window, timebins);

    %Get 3D matrix with individual timebins in 3rd dimension
    %Each row is a different trial
    %Each column is a sample
    %Each 3rd dimension is a time bin
    counter = 0;
    for i = 1:timebins
        postmatrix(:,:,i) = post(:, counter*shift + 1 : counter*shift + window);
        counter = counter + 1;
    end

    %Build predictive features matrix: intercept, baseline pupil, motor responses, oddball
    %or no, difference of frequency, distractor_on
    premeans = mean(pre,2);
    intercept = ones(length(premeans), 1);
    motors = list{'Input'}{'Effort'}.*list{'Input'}{'Choices'}';
    oddball = list{'Stimulus'}{'Playfreqs'} == list{'Stimulus'}{'StandardFreq'};
    oddball = ~oddball; %Ones for oddball freqs, 0s for standards
    freqdiffs = list{'Stimulus'}{'Playfreqs'} - list{'Stimulus'}{'StandardFreq'};
    distractvector = ones(length(premeans),1) * list{'Distractor'}{'On'};

    X = [intercept, premeans, motors, oddball', freqdiffs', distractvector];
    X_matrix = [X_matrix; X];

    %Build predicted features matrix. Each 3d slice is a timebin. Every row is
    %our chosen feature extracted from the post-stim dilation of a particular
    %trial for that timebin. 
    feature = @(x) max(x);
    postfeatures = zeros(length(post), 1, timebins);
    for i = 1:timebins
        for j = 1:length(post) %for every row, grab a feature
            postfeatures(j,:,i) = feature(postmatrix(j,:,i));
        end
    end

    Y_matrix = [Y_matrix; postfeatures];

end

%% Performing a regression for every timebin and grabbing betas.
betas = zeros(timebins, size(X_matrix,2)); %Each row is a timebin.

%Performing regressions.
%Y_matrix(:,:,n) should give a column of features per trial for one
%particular timebin.
for n = 1:timebins
    betas(n, :) = (X_matrix'*X_matrix)\X_matrix'*Y_matrix(:,:,n);
end

%To plot, then, plot the betas columnwise! Because each row is a
%progressive timebin.
for n = 1:size(betas,2)
    plot(betas(:,n));
    hold on
end
legend('Intercept', 'Mean Pre-Stimulus', 'Motor Response', 'Oddball', ... 
        'Frequency Difference', 'Distractor');
xlabel('Timebin (each bin is 20 samples, slid 5 samples at a time)')
ylabel('Beta-Coefficient Value')