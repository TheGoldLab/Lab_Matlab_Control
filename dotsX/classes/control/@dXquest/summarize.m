function q_ = summarize(q_, varargin)
%show a summary of Quested psychometric functions
%   q_ = summarize(q_, varargin)
%
%   Show a good summary of the results of runnung dXquest objects.  This is
%   a more complete psychometric picture than that given by endTrial when
%   showPlot is set to true.
%
%   Input:      q_      ... an array of dXquest objects.
%               varargin... a figure number or something
%
%   Output:     q_      ... updated class instances
%
%               also makes plots in a figure
%
%   See also endTrial dXquest

% Copyright 2007 Benjamin Heasly University of Pennsylvania

% use some figure other than the q_.fig, used by endTrial
if nargin>1 && ishandle(varargin{1})
    fig = varargin{1};
else
    fig = figure;
end
ax = cla(gca);

% elide dB abscissas
bigAxisdB = unique([q_.dBDomain]);

% elide linear abscissas
bigAxis = unique([q_.linearDomain]);

inc = round(length(bigAxis)/10) - 1;

if length(q_(1).ptr) == 3
    unit = q_(1).ptr{3};
else
    unit = 'unknown';
end
set(ax, 'XTick', bigAxisdB(1:inc:end), ...
    'XTickLabel', round(bigAxis(1:inc:end)));
xlabel(sprintf('stim units (%s)', unit));
ylabel('P')

global ROOT_STRUCT
if ~isempty(ROOT_STRUCT.groups.name)
    name = ROOT_STRUCT.groups.name;
else
    name = 'unknown task';
end
title(sprintf('QUEST results (%s)', name));

% build PFs with threshold estimates
nq = length(q_);
PFS = nan*ones(nq, length(bigAxis));
errX = nan*ones(nq, 5);
errY = nan*ones(nq, 5);
for qq = 1:nq
    
    clr = dec2bin(qq,3)==('1');

    % threshold for this PF
    Th = q_(qq).estimateLikedB;

    % PF may have an epsilon added to threshold
    %   see Watson and Pelli, "QUEST...", 1983 p116.
    if ~isempty(q_(qq).psychParams);
        par = q_(qq).psychParams;
        ep = -par(1);
    else
        ep = 0;
    end
    par(1) = Th - ep;
    
    % mark the threshold estimate
    PTh = feval(q_(qq).psycFunction, Th, par);
    l = line(Th, PTh, 'Marker', '*', ...
        'Color', clr, 'Parent', ax);
    t = text(Th, PTh, sprintf('  (%.1f, %.2f) from %s', ...
        q_(qq).estimateLike, PTh, q_(qq).estimateType), 'Parent', ax);

    % evaluate PF across the whole big domain
    PFS(qq,:) = feval(q_(qq).psycFunction, bigAxisdB, par);
    l = line(bigAxisdB, PFS(qq,:), 'Color', clr, 'Parent', ax);

    % show a box around the confidence interval
    errX(qq,:) = q_(qq).CIdB([1 2 2 1 1]);
    errY(qq,:) = feval(q_(qq).psycFunction, ...
        q_(qq).CIdB([1 1 2 2 1]), par);
    p = patch(errX(qq,:), errY(qq,:), clr, 'EdgeColor', 'none', ...
        'FaceColor', clr, 'FaceAlpha', .1, 'Parent', ax);
    t = text(errX(qq,2), errY(qq,2), sprintf('%d%%', 100*q_(qq).CIsignif), ...
        'Parent', ax);
end