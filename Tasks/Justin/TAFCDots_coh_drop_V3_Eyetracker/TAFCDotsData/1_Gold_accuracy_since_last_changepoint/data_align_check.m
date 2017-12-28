time_elapsed_1 = load('H_.1/time_elapsed.mat');
time_elapsed_1 = time_elapsed_1.time_elapsed;

time_elapsed_2 = load('H_2/time_elapsed.mat');
time_elapsed_2 = time_elapsed_2.time_elapsed;

time_elapsed_round_1 = ceil(time_elapsed_1 * 2) / 2;
time_elapsed_round_2 = ceil(time_elapsed_2 * 2) / 2;

X_1 = unique(time_elapsed_round_1);
X_2 = unique(time_elapsed_round_2);

isequal(X_1, X_2)