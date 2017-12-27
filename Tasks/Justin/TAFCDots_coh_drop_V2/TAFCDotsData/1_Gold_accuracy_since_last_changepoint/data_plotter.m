correct = load('H_tenth_low/correct.mat');
correct = correct.correct;
correct_1 = correct;

time_elapsed = load('H_tenth_low/time_elapsed.mat');
time_elapsed = time_elapsed.time_elapsed;
time_elapsed_1 = time_elapsed;

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

correct = load('H_2_low/correct.mat');
correct = correct.correct;

time_elapsed = load('H_2_low/time_elapsed.mat');
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
title('Data Binned to Closest 200 Millisecond')
xlabel('Time Post Final Change-Point (seconds)')
ylabel('p(correct)`')
ylim([0 1])
xlim([0 2])
legend('Hazard = .1','Hazard  = 2','Location','southeast')
% %PLOTSSSS
hold off
figure(2)
hold on
%fit to time points only less than 2 second
index = find(time_elapsed_1 > 2);
time_elapsed_1(index)  = [];
correct_1(index) = [];

index = find(time_elapsed > 2);
time_elapsed(index) = [];
correct(index) = [];

ylim([0 1])
xlim([0 2])
f1 = fit(time_elapsed_1', correct_1', 'exp2');
fl1 = plot(f1);
% % 
f2 = fit(time_elapsed', correct', 'exp2');
fl2 = plot(f2);
set(fl1, 'color', [0 0.4470 0.7410])
set(fl2, 'color', [0.8500 0.3250 0.0980])
title('Data Fit to 2-term Exponential Function')
xlabel('Time Post Final Change-Point (seconds)')
ylabel('p(correct)')
legend('Hazard = .1','Hazard  = 2','Location','southeast')

% find intersection of exponential fits
f = @(x)f1(x)-f2(x);
xx = 0:.01:2;
t = f(xx) > 0;
i0 = find(diff(t(:))~=0);
i0 = [i0(:)';i0(:)'+1];
n = size(i0,2);
xout = zeros(n,1);
for jj = 1:n
    xout(jj) = fzero(f,xx(i0(:,jj))); 
end