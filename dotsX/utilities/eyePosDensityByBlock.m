function eyePosDensityByBlock(simple)
% get some FIRA(s) and plot eye pos for each block
%
%   eyePosDensityByBlock(simple)
%
%   Shows a subplot for each block.  Either draws squiggles(simple=true) or
%   superimposes patches to visualize the eyepos density over each whole
%   block.
%
%   Should work for any FIRA with ASL data.  Uses the current FIRA, or
%   gives a dialog for loading a FIRA file.

% 2008 by Benjamin Heasly at University of Pennsylvania

if ~nargin
    simple=false;
end

global FIRA
if isempty(FIRA)
    concatenateFIRAs;
end

% reality
if ~isfield(FIRA, 'ecodes') || ~isfield(FIRA, 'aslData')
    disp('Must use a FIRA with ecodes and aslData')
    return
end

% get organizational data about FIRA
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,30);
sessions = unique(sessionID)';

% plot sessions as rows and blocks as columns
ns = max(sessions);
nb = max(blockNum);

f = figure(919);
clf(f)
axArgs = {'XLim', [-15 15], 'YLim', [-10 10]};

% locate the good trials
eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = FIRA.ecodes.data(:,eGood);

% visit each block from each session
for ss = sessions

    thisSession = sessionID == ss;
    blocks = unique(blockNum(thisSession))';

    for bb = blocks

        thisBlock = good & thisSession & blockNum == bb;

        % concatenate all the eye data from good trials in this block
        blockEye = cat(1, FIRA.aslData{thisBlock});

        % new axes for this block
        s(ss,bb) = subplot(ns, nb, (ss-1)*nb + bb, axArgs{:});

        if simple

            % draw boring lines
            line(blockEye(:,2), blockEye(:,3), ...
                'Marker', 'none', 'LineStyle', '-', ...
                'Parent', s(ss,bb));
        else

            % superimpose transparent polygons
            gons = 3;
            for ii = 1:gons:size(blockEye,1)-gons
                patch(blockEye(ii:(ii+gons-1),2), blockEye(ii:(ii+gons-1),3), ...
                    [0 0 1], 'Parent', s(ss,bb), ...
                    'EdgeColor', 'none', 'FaceAlpha', .2);
            end
        end
    end
end