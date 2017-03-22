% I want to know more about the error surface in fitting.
%   get a real psychometric dataset
%   compute all fit likelihoods for 4 parameters in a reasonable range
%   look at the 4-d surface with the sweet code I just wrote

% 2008 Benjamin Heasly
%   University of Pennsylvania

% pick a session
clear all
concatenateFIRAs
[sessID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,50);
global FIRA

% ignore trials that don't belong to a proper session and block
OK = ~isnan(sessID) & ~isnan(blockNum);

% locate performance data
eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = FIRA.ecodes.data(OK,eGood);
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(OK,eCorrect));

% get coh as recorded by low quest
eCoh = strcmp(FIRA.ecodes.name, 'dot_coh_low_used');
coh = FIRA.ecodes.data(OK,eCoh);

% bin coherences
edges = (.5:1:100);
centers = edges(2:end)-edges(2)/2;

% calculate performance in each bin, for this block
Pc = nan*ones(size(centers));
n = nan*ones(size(centers));
for ii = 1:length(centers)
    stimSelect = coh >= edges(ii) & coh < edges(ii+1) & good;
    n(ii) = sum(stimSelect);
    Pc(ii) = sum(correct & stimSelect)/n(ii);
end

z = n~=0;

% package data for the quick function
bins = sum(z);
data(1:bins, 1) = centers(z);
data(1:bins, 2) = Pc(z);
data(1:bins, 3) = n(z);

% parameter ranges for fitting
np = 10;
alpha = linspace(1, 100, np);
beta = linspace(0.1, 10, np);
lambda = linspace(0, .2, np);

% a 3D surface of errors
surface = nan*ones(np, np, np);
tic
for a = 1:np
    for b = 1:np
        for l = 1:np
            fits = [alpha(a) beta(b) lambda(l)];
            surface(a,b,l) = quick_err(fits, data);
        end
    end
end
toc

% Use the power of this code for Good.
[fig, axe, sur] = nDimVisualize(surface, '-log(likelihood)', ...
    {alpha, beta, lambda}, {'alpha', 'beta', 'lambda'}, ...
    [], [], ...
    2);

% arbitrary z-lim for -log(like)
set(axe, 'ZLim', [0 2000])