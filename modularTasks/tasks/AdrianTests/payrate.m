function payrate(timestamp)
% compute extra pay for subject
% ARGS:
%   timestamp -  string like '2019_11_06_12_43'

%   max_rate  -  integer. maximum rate a subject can get. E.g. 10 $/hour
max_rate=10;

%   th_perf   -   percent correct above which max pay rate is reached.
%   Between 0 and 1
th_perf=0.75;

pre= 'completed4AFCtrials_task100_date_';
post='.csv';
filename = which([pre, timestamp, post]);
t1=readtable(filename);
coh1 = t1(t1.coherence==100,:);
refdim = size(coh1);
dims=size(coh1(coh1.dirCorrect & coh1.cpCorrect, :));
perf = dims(1) / refdim(1);
%th_perf = .75;
payrate = min(perf/th_perf, 1);  % dollars per hour
disp(['additional payrate:  ', num2str( ceil(payrate * max_rate)), '$/hour'])
end