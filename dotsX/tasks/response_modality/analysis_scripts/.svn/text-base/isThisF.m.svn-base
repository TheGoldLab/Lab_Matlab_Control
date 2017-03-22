function isThisF
% I want to find out if a statistic I can compute is F-distributed.  If it
% is, then I can easily do analysis of variance with my data.
%
% Key questions:
%   what is the right size of confidence interval (CI)?
%   what is the right number of bootstrap resamples (N)?
%   do these tell me my degrees of freedom?
%       -Maybe number of trials gives toal dof.

clear all

% how many times to redo bootstrapping
%   i.e. how many times to resample my F-statistic
redo = 10000;

% population parameters
% possibly many MU
MU = [1 1 1 1 1 1]+50;

% just one sigma
SIG = 5;

% blocks of data (like treatments)
b = length(MU);
DFB = b-1;

% for each block, simulate the bootstrapping process
%   (skip some initial parameter estimation, since its all fake anyway)
%   generate a dataset from the "real" parameters and
%   get the sample mean and some confidence interval
N = 100;
CI = 95;%.44997361036;
ha = (100-CI)/2;

% how many Gaussian standard deviations does CI represent?
gsd = erfinv(CI/100)*sqrt(2);

for jj = 1:redo
    for ii = 1:b
        y = normrnd(MU(ii), SIG, 1, N);
        mu(jj,ii) = mean(y);
        clb(jj,ii) = prctile(y, ha);
        cub(jj,ii) = prctile(y, 100-ha);
        ci_width(jj,ii) = cub(jj,ii) - clb(jj,ii);
    end

    % MSB
    %   Get MSB--mean square deviations of block threshold estimate means.
    %   This one is not hard.  Assuming same ni = N, it should be an
    %   unbiased estimate of sigma-squared, with dof = b-1
    mu_bar(jj) = mean(mu(jj,:));
    MSB(jj) = N*sum((mu(jj,:)-mu_bar(jj)).^2)/(b-1);

    % MSE
    %   Try to get the remaining error.  This one is harder, since I don't
    %   know whether the statistic is proportional to chi-square, nor the
    %   degrees of freedom, if it is chi-square.  So take a look
    %   numerically...

    % try this:
    %   assume bootstrapping gives gaussian-distributed error bars
    %   estimate sigma as the fraction of confidence interval that
    %   corresponds to one standard deviation
    sigs = ci_width(jj,:)./(gsd*2);
    
    % take mean square of sigma estimates
    MSE(jj) = sum(sigs.^2)/b;
end

figure(4)
clf
xaxis = 1:redo;
sp = subplot(2,1,1);
title('are MSB and MSE good estimators of SIG squared?')

% MSB sigma estimates
line(xaxis, sort(MSB), 'Parent', sp, ...
    'Color', [1 0 0], ...
    'LineStyle', 'none', ...
    'Marker', '.', 'MarkerSize', 6)

% MSE sigma estimates
line(xaxis, sort(MSE), 'Parent', sp, ...
    'Color', [0 1 0], ...
    'LineStyle', 'none', ...
    'Marker', '.', 'MarkerSize', 6)

% the real sigma
line(xaxis, (SIG.^2)*ones(size(xaxis)), 'Parent', sp, ...
    'Color', [0 0 0], 'LineStyle', '-', 'Marker', 'none')

% compare ratio of estimators to F-distribution
subplot(2,1,2, 'Color', [.6 .6 1])

% make histogram of MS ratios
%   and scale histogram to probability density units
bins = 100;
[hMSRatio, bincen] = hist(MSB./MSE, bins);
q = redo*bincen(end)/bins;
F_sample = hMSRatio/q;

% plot the F samples
line(bincen, F_sample, ...
    'Color', [1 1 0], 'LineStyle', 'none', 'Marker', '.')

% make some real F
%   assume this hist represents some large % of the full F-distribution
pct = .9999;

% make a reasonable guess at DFE
%   use N for now, instead of number of trials
DFE_guess = (N*(CI/100)-1)*b

% plot the F guess
F_fit = fpdf(bincen, DFB, DFE_guess);
line(bincen, F_fit, 'Color', [0 0 1], 'LineStyle', '-', 'Marker', 'none');

% get a least-square error fit of DFE
opt = optimset;
[DFE_fit, err, exit_flag] = fminsearch(@Ferr, DFE_guess, opt, ...
    bincen, DFB, F_sample)

% plot the F fit
F_fit = fpdf(bincen, DFB, DFE_fit);
line(bincen, F_fit, 'Color', [0 0 0], 'LineStyle', '-', 'Marker', 'none');

% superimpose the guess, fit, and sampled F means
F_fit_mean = fstat(DFB, DFE_fit);
line([1,1]*F_fit_mean, [0,1], 'Color', [0 0 0]);
text(F_fit_mean*1.1, .9, sprintf('DFE fit = %i', round(DFE_fit)), ...
    'Color', [0 0 0]);

F_guess_mean = fstat(DFB, DFE_guess);
line([1,1]*F_guess_mean, [0,1], 'Color', [0 0 1]);
text(F_guess_mean*1.1, .85, sprintf('DFE guess = %i', round(DFE_guess)), ...
    'Color', [0 0 1]);

F_sample_mean = sum(hMSRatio./sum(hMSRatio).*bincen);
line([1,1]*F_sample_mean, [0,1], 'Color', [1 1 0]);

% some fit values: 
%   I think those huge values come up because my histogram has no tail.
% [347.585632324219, 292.886402893067, 201.415734863281,
% 102657953.35,408.37645111084, 101489134.149932, 642.546972656251,
% 1009.15904388428, 67664185.7195801, 119.314810180664, 32372161.3673828]


function err = Ferr(DFE, bincen, DFB, F_sample)
y = fpdf(bincen, DFB, DFE);
err = sum((y-F_sample).^2);