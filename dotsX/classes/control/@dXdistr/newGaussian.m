function d_ = newGaussian(d_)
%pick new random parameters for a gaussian distribution

d = d_.distributions(1);
sig = round(5+(30*rand));
mu = round(2*sig+((300-4*sig)*rand));
d.args = {mu, sig};
d_.distributions(1) = d;