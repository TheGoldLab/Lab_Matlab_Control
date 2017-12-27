figure(1)
subplot(3,1,1)
X = -10:.1:10;
Y = normpdf(X,0,1);
plot(X,Y)

subplot(3,1,2)
X = -10:.1:10;
Y = normpdf(X,0,1);
Y = log10(Y);
plot(X,Y)

subplot(3,1,3)
X = -10:.1:10;
Y1 = normpdf(X,0,1);
Y2 = log10(Y1);
Y3 = Y1.*Y2*0.1;
plot(X,Y)