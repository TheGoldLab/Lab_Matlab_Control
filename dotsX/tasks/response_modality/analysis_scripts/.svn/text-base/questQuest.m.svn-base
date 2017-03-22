% look at the quest thing and stuff

clear all
concatenateFIRAs

% get FIRA structural info
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,50);

global ROOT_STRUCT FIRA
ROOT_STRUCT = FIRA.header.session;
ROOT_STRUCT.screenMode = 0;
rGroup('ModalityRTLever')

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = FIRA.ecodes.data(:,eGood) & ~isnan(sessionID) & ~isnan(blockNum);

% domain = rGet('dXquest', 1, 'dBDomain');
% units = sprintf('dB (0 = %.1f coh)', rGet('dXquest', 1, 'refValue'));
domain = rGet('dXquest', 1, 'linearDomain');
units = 'coherence';

% show available coherences
cohs = rGet('dXquest', 1, 'values');
line(cohs, 0, 'Marker', '*', 'MarkerSize', 10, 'Color', [1 1 0])

clf
ax = axes( ...
    'XLim',     domain([1, end]), ...
    'XTick',    cohs, ...
    'XScale',   'log', ...
    'YLim',     [0 .05]);
xlabel(ax, units);
ylabel(ax, 'like alpha');
grid(ax, 'on')

nt = length(FIRA.QUESTData);
nq = length(FIRA.QUESTData{1});
nTail = 10;

% prime the tail
tail = zeros(nt,10);
for ii = 1:10
    for jj = 1:nq
        tail(jj,ii) = line;
    end
end

drawnow
for ii = find(good)'
    q = FIRA.QUESTData{ii};
    ti = mod(ii,10)+1;

    for jj = 1:nq

        if ~isempty(q(jj).pdfLike)
            delete(tail(jj,ti));
            tail(jj,ti) = line(domain, q(jj).pdfLike, ...
                'Parent', ax, ...
                'Color', dec2bin(jj,3)=='1');
        end
    end

    pause(.1)
end