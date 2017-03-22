% I want to know more about the error surface in fitting.
%   get a real psychometric dataset for the RT response modality task.
%   compute likelihood surface for several of my 6 ddRT parameters

% 2008 Benjamin Heasly
%   University of Pennsylvania

% load data
clear all
global FIRA
concatenateFIRAs(dir);

% make new multisession ecodes, get basic summary data
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,30);
sessions = unique(sessionID)';

% get common data structure, d
d = getCommonDataTypes(subjects, blockNum, sessionID);

% package data from one task for the ddRT model
tt = 2;
select = d.good & tt == taskID';
ddData = [d.coh(select), d.correct(select), d.RT(select)];

% parameter ranges for likelihood
% for sanity, fix facilitation, lapse, and guess
np = 10;
k = logspace(-5, -1, np);
b = 1;
A = linspace(1, 75, np);
l = .01;
g = .5;
r = linspace(200, 1000, np);

% a 3D surface of errors
surface = nan*zeros(np, np, np);
tic
for ii = 1:np
    for jj = 1:np
        for kk = 1:np
            Q = [k(ii) b A(jj) l g r(kk)];
            surface(ii,jj,kk) = feval(@ddRT_psycho_nll, Q, ddData) ...
                + feval(@ddRT_chrono_nll_from_fano, Q, ddData);
        end
    end
end
toc

% Use the power of this code for Good.
[fig, axe, sur] = nDimVisualize(surface, 'nll', ...
    {k, A, r}, {'k', 'A''', 'TR'}, {'log', 'linear', 'linear'}, ...
    [], [], ...
    figure(2));

% fix the likelihood scale, ignore inf
fin = isfinite(surface(1:numel(surface)));
set(axe, 'ZLim', [min(surface(fin)), max(surface(fin))]);

% arbitrary z-lim for -log(like)
title(axe, [subjects{1}, ': ', tasks{tt}]);