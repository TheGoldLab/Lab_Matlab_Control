% how sensitive is the F distribution to degrees of freedom?
%   especially when v1 is known and small
%   and v2 is unknown but probably large
%
% it seems like large v1 leads to more variability per change in v2
%   but in general, F changes when v2 is small, and when v2 is large,
%   changes in v2 only change F a little.  This is intuitive
%
% so estimating dof incorrectly need not always be the end of the world.

dofNumerator = 9:-2:1;
dofDenominator = 20:20:400;
faxis = linspace(eps, 3, 1000);

figure(1543)
clf;

% show F_alpha critical values with various parameters
alaxis = 10.^[-5:.01:-1.3];
ax(1) = subplot(1,1,1, 'Color', [0 0 1], 'XLim', [0, alaxis(end)]);
xlabel('F_a_l_p_h_a')
ylabel('critical x')

paxis = 1-alaxis;
for v1 = dofNumerator
    for v2 = dofDenominator
        crit = finv(paxis, v1, v2);
        line(alaxis, crit, 'Parent', ax(1), ...
            'Color', [v1/max(dofNumerator), v2/max(dofDenominator), 0]);
        drawnow
    end
end

% show F pdf with various parameters
ax(2) = axes('Position', [.5 .5 .4 .4], 'Color', [0 0 1], 'YLim', [0, 1.5]);
xlabel('x')
ylabel('dP/dx')

for v1 = dofNumerator
    for v2 = dofDenominator
        F = fpdf(faxis, v1, v2);
        line(faxis, F, 'Parent', ax(2), ...
            'Color', [v1/max(dofNumerator), v2/max(dofDenominator), 0]);
        drawnow
    end
end

% legend
j = 0;
x = faxis(end)*.6;
for v1 = [max(dofNumerator), min(dofNumerator)]
    for v2 = [max(dofDenominator), min(dofDenominator)]
        text(x, 1.5-(j*.1), sprintf('v1 = %d  v2 = %d', v1, v2), ...
            'Color', [v1/max(dofNumerator), v2/max(dofDenominator), 0], ...
            'Parent', ax(2))
        j = j+1;
    end
end