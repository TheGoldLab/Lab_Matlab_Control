function copyQuestCoherences(taski, varargin)
% find the threshold estimates that Quest came up with and save then in the
% userData for this task

% find the natural PMF, as if epsilon=0
q = rGet('dXquest', 1);
pars = q.psychParams;
pars(1) = pars(1) + q.estimateLikedB;
p = feval(q.psycFunction, q.dBDomain, pars);

% get some coherences corresponding to several percents correct
%   first is for subthreshold dots
%   rest are for test dots
pcts = [55 60 75 90]./100;
for ii = 1:length(pcts)
    coherences(ii) = q.stimDomain(find(p >= pcts(ii), 1));
end

% make a package
Qdots.subCoh  = coherences(1);
Qdots.testCoh = coherences(2:end);

% copy these coherences to the userData of this task
rSet('dXtask', taski, 'userData', Qdots);
disp(['picked coherences: ', sprintf('%.1f ', coherences)])