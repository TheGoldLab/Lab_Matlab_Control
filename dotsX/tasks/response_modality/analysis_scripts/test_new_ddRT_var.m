% Try loads of k and A' values and see if ddRT predicted variance is
% positive.

% a test for the corrected A.34 in Palmer, Huk, Shadlen.

np = 100;
k = logspace(-3, 0, np);
b = 1;
A = linspace(0, 100, np);
l = .01;
g = .05;
tR = 0;

x = [2.^(4:10)]/10;

var = nan*zeros(np, np, length(x));
figure(556)
ax = gca;
for ii = 1:np
    cla(ax)
    title(ax, k(ii));
    for jj = 1:np
        Q = [k(ii), b, A(jj), l, g, tR];
        var(ii,jj,:) = ddRT_chrono_val(Q, x);
        
        line(x, squeeze(var(ii,jj,:)), 'Parent', ax);
    end
    
    pause(.1)
end