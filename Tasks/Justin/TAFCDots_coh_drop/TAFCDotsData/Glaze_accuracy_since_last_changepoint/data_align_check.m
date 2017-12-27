time_elapsed_1 = load('H_.1_coh_11/time_elapsed.mat');
time_elapsed_1 = time_elapsed_1.time_elapsed;

time_elapsed_2 = load('H_2_coh_11/time_elapsed.mat');
time_elapsed_2 = time_elapsed_2.time_elapsed;

time_elapsed_round_1 = ceil(time_elapsed_1 * 4) / 4;
time_elapsed_round_2 = ceil(time_elapsed_2 * 4) / 4;

X_1 = unique(time_elapsed_round_1);
X_2 = unique(time_elapsed_round_2);

isequal(X_1, X_2)