addpath(genpath(fullfile('..','..','..','..','Lab-Matlab-Utilities')));

correct = load('H_.1/correct.mat');
correct = correct.correct;

time_elapsed = load('H_.1/time_elapsed.mat');
time_elapsed = time_elapsed.time_elapsed;

%round up to closest 
time_elapsed_round = ceil(time_elapsed * 5) / 5;
%time_elapsed_round = time_elapsed;
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

correct = load('H_2/correct.mat');
correct = correct.correct;

time_elapsed = load('H_2/time_elapsed.mat');
time_elapsed = time_elapsed.time_elapsed;

%round up to closest 

time_elapsed_round = ceil(time_elapsed * 5) / 5;
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


%data = [time_elapsed' correct' ones(size(time_elapsed,2),1)*.05 ];
% f = fit(data(:,1),data(:,2),'exp1');
% plot(f, data(:,1),data(:,2));
figure(1)
hold on
f1 = fit(X_1', Y_1', 'exp2');
plot(f1, X_1', Y_1');
%figure(2)
f2 = fit(X_2', Y_2', 'exp2');
plot(f2, X_2', Y_2');


% [fits_, sems_, sse_] = getFIT_exp1(data);

% figure
% X = 0:.1:10;
% Y = fits_(2) + fits_(3)*exp(X/fits_(1));
% plot(X,Y)

%fits do not look promising. Even error rate is high.