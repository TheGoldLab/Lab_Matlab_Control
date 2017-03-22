% function gauss_err takes initial guess and some data set to produce the
% error between a gaussian fit and the data set.

% copyright 2008 Benjamin Naecker University of Pennsylvania

function err = gauss_err(fits, data)

err = sum( ((fits(3)/(sqrt(2*pi)*fits(2))) * (exp(-(data(:,1)-fits(1))./(2*fits(2)^2))) - data(:,2)).^2 );
   