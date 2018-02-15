addpath(genpath(fullfile('~/Users/joshuagold/Users/Lalitta/lalitta-matlab-control/edfmex/edfmex.m')))


edf_data = edfmex('H_2.edf');
save('H_2.mat','edf_data')

% edf_data = edfmex('H_tenth.edf');
% save('H_tenth.mat','edf_data')

DATA = TreatData()

save('DATA.mat','DATA')