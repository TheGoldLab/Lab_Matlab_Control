function plot_fit(cohs, pcor, fits)

cla reset; hold on;

cbins = 0:.1:1;
ncbins = length(cbins);

for cc = 1:ncbins-1
    
    Lc = cohs>=cbins(cc) & cohs<=cbins(cc+1);
    if sum(Lc) > 2
        plot(cbins(cc+1), sum(pcor(Lc)==1)./sum(Lc), 'k.');
    end
end

set(gca, 'XScale', 'log')