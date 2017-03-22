% I don't understand quite how MSE is an estimator of sigma.  Especially, I
% don't understand why taking deviations wrt the population mean is
% apparently so different from taking deviations wrt the mean of means.

% Oh, neither SST nor SSE nor MST nor MSE is chi-square distributed!
% SSE/sigma-squared is, and SST/sigma-squared is, but sigma-squared is
% latent.  So its only when we divide-out sigma-squared and divide-out
% degrees of freedom, that we can obey a distribution--the F.

clear all

% trials per block
n = 50;

% population parameters
% possibly many MU
MU = [1 1 1 1 1]+50;

% just one sigma
SIG = 5;

% blocks of data (like treatments)
b = length(MU);

% simulations
reps = 1000;

for r = 1:reps
    y = nan*ones(b,n);
    SE = nan*ones(1,b);
    for ii = 1:b
        % b-by-n samples
        y(ii,:) = normrnd(MU(ii), SIG, 1, n)';

        % block means
        mu(ii,r) = mean(y(ii,:));

        % squared individual errors
        SE(ii) = sum((y(ii,:)-mu(ii,r)).^2);
    end

    % MSE should estimate sig-squared
    SSE(r) = sum(SE);
    DFE = (n*b)-b;
    MSE(r) = SSE(r)/DFE;

    % sample grand mean
    %   vs mean of block means
    %   with same n these should be identical
    y_bar(r) = mean(y(1:numel(y)));

    % MSB should estimate sig-squared
    SSB(r) = n*sum((mu(:,r)-y_bar(r)).^2);
    DFB = b-1;
    MSB(r) = SSB(r)/DFB;
end

figure(8)
clf
raxis = 1:reps;

subplot(2,1,1)
% sigma-square from MSB
line(raxis, sort(MSB), ...
    'Color', [1 0 0], 'LineStyle', 'none', 'Marker', '.')

% sigma-square from MSE
line(raxis, sort(MSE), ...
    'Color', [0 1 0], 'LineStyle', 'none', 'Marker', '.')

% the real sigma-squared
line(raxis, SIG.^2*ones(size(raxis)), ...
    'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '-')


% compare ratio of estimators to F-distribution
subplot(2,1,2)

% make histogram of MS ratios
bins = 100;
[hMSRatio, bincen] = hist(MSB./MSE, bins);

% assume this hist represents some large % of the full F-distribution
pct = .9999;

% make an real F
x = finv(pct, DFB, DFE);
faxis = linspace(0, x, 10*bins);
F = fpdf(faxis, DFB, DFE);

% scale histogram to probability density units
q = reps*bincen(end)/bins;

% superimpose hist and real F
line(bincen, hMSRatio/q, ...
    'Color', [0 0 1], 'LineStyle', 'none', 'Marker', '.')
line(faxis, F, ...
    'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '-')

% show means
%   of real F-distribution
%   of observed F-statistics
[EF, VF] = fstat(DFB, DFE);
mMSRatio = sum(hMSRatio./sum(hMSRatio).*bincen);
line([1,1]*EF, [0,1], 'Color', [0 0 0]);
line([1,1]*mMSRatio, [0,1], 'Color', [0 0 1]);