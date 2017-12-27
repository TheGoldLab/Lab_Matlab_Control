correct = load('H_.1/correct.mat');
correct = correct.correct;

time_elapsed = load('H_.1/time_elapsed.mat');
time_elapsed = time_elapsed.time_elapsed;

BINS = 5;

%round up to closest 

time_elapsed_round = ceil(time_elapsed * BINS) / BINS;
X_1 = unique(time_elapsed_round);
Y_1_count = zeros(2,size(X_1,2));

for i=1:size(correct, 2)
    
    ind = find(X_1==time_elapsed_round(i));
    Y_1_count(1,ind) = Y_1_count(1,ind) + correct(i);
    Y_1_count(2,ind) = Y_1_count(2,ind) + 1;
    
end

for i=1:size(Y_1_count,2)
   Y_1(1,i) = Y_1_count(1,i) / Y_1_count(2,i);
    
end

%compute standard deviation
err_1 = zeros(1,size(Y_1_count,2));
for i=1:size(Y_1_count,2)
    err_1(i) = std(repelem([0 1],[Y_1_count(1,i) (Y_1_count(2,i) - Y_1_count(1,i))]));
end

correct = load('H_2/correct.mat');
correct = correct.correct;

time_elapsed = load('H_2/time_elapsed.mat');
time_elapsed = time_elapsed.time_elapsed;

%round up to closest 

time_elapsed_round = ceil(time_elapsed * BINS) / BINS;
X_2 = unique(time_elapsed_round);
Y_2_count = zeros(2,size(X_2,2));


for i=1:size(correct, 2)
    
    ind = find(X_2==time_elapsed_round(i));
    Y_2_count(1,ind) = Y_2_count(1,ind) + correct(i);
    Y_2_count(2,ind) = Y_2_count(2,ind) + 1;
    
end

for i=1:size(Y_2_count,2)
   Y_2(1,i) = Y_2_count(1,i) / Y_2_count(2,i);
    
end

%compute standard deviation
err_2 = zeros(1,size(Y_2_count,2));
for i=1:size(Y_2_count,2)
    err_2(i) = std(repelem([0 1],[Y_2_count(1,i) (Y_2_count(2,i) - Y_2_count(1,i))]));
end

%use the x-axis of the ones with the smallest unique values
%TODO: splitting of this needs to be more autominized. It relies on X_1
%being bigger than X_2. 

% PLOTTING

%plot with error bars
% figure(1)
% hold on
% errorbar(X_2, Y_1(1,1:size(X_2,2)), err_1)
% errorbar(X_2,Y_2(1,:), err_2)
% hold off

%plot everything
figure(1)
hold on
plot(X_1, Y_1(1,:),'Color',[0 0.4470 0.7410])
plot(X_2,Y_2(1,:), 'Color', [0.8500 0.3250 0.0980])
%PLOTSSSS
figure(1)
f1 = fit(X_1', Y_1', 'exp2');
plot(f1, X_1', Y_1','b');

figure(2)
f2 = fit(X_2', Y_2', 'exp2');
plot(f2, X_2', Y_2','o');


hold off
legend('Hazard = .1','Hazard  = 2')
xlabel('Time after Changepoint (seconds)')
ylabel('P(Correct)')
xlim([min(X_1(1), X_2(1)) max(X_1(end), X_2(end))])
Y_1_count = cat(1,Y_1_count, X_1);
Y_2_count = cat(1,Y_2_count, X_2);
title('Binned to closest 200 millisecond')

% figure(2)
% plot(X_2, Y_2_count(2,:))
% ylim([0 (max(Y_2_count(2,:))+2)])
% xlim([0 1.8])
% xticks([0:.1:2])
% title('Natural Time after Changepoint for High Hazard (H = 2)')
% xlabel('Seconds after last change')
% ylabel('Number of trials')
% Y_2_count = cat(1,Y_2_count, X_2);