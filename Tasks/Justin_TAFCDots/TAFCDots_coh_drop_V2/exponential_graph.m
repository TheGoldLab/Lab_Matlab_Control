%% hist
size = 1000;
Y = exprnd(1,1,size);
hist(Y,size);c

%% pdf
X = 0:.1:10;
Y = exppdf(X,1/.1);
plot(X,Y);

%% show accumulation
size = 1000;
H = .1;
Y = zeros(1,size);
minT = 1;
maxT = 4;
for i=1:size
    choice = min(minT + exprnd(1/H), maxT);
    while(choice == maxT)
        choice = min(minT + exprnd(1/H), maxT);
    end
    Y(i) = choice;
end
hist(Y,20);