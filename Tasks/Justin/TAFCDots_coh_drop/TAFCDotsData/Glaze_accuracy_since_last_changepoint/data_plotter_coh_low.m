correct = load('H_.1_coh_11/correct.mat');
correct = correct.correct;

time_elapsed = load('H_.1_coh_11/time_elapsed.mat');
time_elapsed = time_elapsed.time_elapsed;

%round up to closest 

time_elapsed_round = ceil(time_elapsed * 2) / 2;
X_1 = unique(time_elapsed_round);
Y_1 = zeros(2,size(X_1,2));


for i=1:size(correct, 2)
    
    ind = find(X_1==time_elapsed_round(i));
    Y_1(1,ind) = Y_1(1,ind) + correct(i);
    Y_1(2,ind) = Y_1(2,ind) + 1;
    
end

for i=1:size(Y_1,2)
   Y_1(1,i) = Y_1(1,i) / Y_1(2,i);
    
end

correct = load('H_2_coh_11/correct.mat');
correct = correct.correct;

time_elapsed = load('H_2_coh_11/time_elapsed.mat');
time_elapsed = time_elapsed.time_elapsed;

%round up to closest 

time_elapsed_round = ceil(time_elapsed * 2) / 2;
X_2 = unique(time_elapsed_round);
Y_2 = zeros(2,size(X_2,2));


for i=1:size(correct, 2)
    
    ind = find(X_2==time_elapsed_round(i));
    Y_2(1,ind) = Y_2(1,ind) + correct(i);
    Y_2(2,ind) = Y_2(2,ind) + 1;
    
end

for i=1:size(Y_2,2)
   Y_2(1,i) = Y_2(1,i) / Y_2(2,i);
    
end

%use the x-axis of the ones with the smallest unique values
%TODO: splitting of this needs to be more autominized. It relies on X_1
%being bigger than X_2. 
figure(1)
plot(X_2, Y_1(1,1:size(X_2,2)), X_2,Y_2(1,:))
title('blue low hazard, orange high hazard')

figure(2)
plot(X_2,Y_1(1,1:size(X_2,2)))
title('Low Hazard Rate: 0.1')
dx = 0.05; dy = 0; % displacement so the text does not overlay the data points
for i=1:size(X_2,2)
    text(X_2(i) + dx, Y_1(1,i) + dy, strcat(int2str(Y_1(2,i)), ...
        '  :',num2str(round(binopdf(round(Y_1(1,i) * Y_1(2,i)), Y_1(2,i),.5)* 100)),'%'))
    
end

figure(3)
plot(X_2, Y_2(1,:),'color',[0.9100    0.4100    0.1700])
title('High Hazard Rate: 2')
for i=1:size(X_2,2)
    text(X_2(i) + dx, Y_2(1,i) + dy, strcat(int2str(Y_2(2,i)), ...
        '  :',num2str(round(binopdf(round(Y_2(1,i) * Y_2(2,i)), Y_2(2,i),.5)* 100)),'%'))
end

