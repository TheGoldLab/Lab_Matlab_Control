function y = errPow(x, varargin)
% calculate sum squared deviations for power law

% column 1 are x points
% column 2 are data points
data = varargin{1};

% fit a power function with the current params
% x(1) is a, the threshold
% x(2) is b, the exponent, so
% y = (X/a)^b;
test = (data(:,1)./x(1)).^x(2);

% get sum of squared deviations
y = sum((data(:,2)-test).^2);