function [ Y ] = Weibull( intensity, threshold, gamma, beta, epsilon, delta, grain)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
Y_init = 1 - (1-gamma)*exp(-10.^((beta/grain)*(intensity - threshold + epsilon)));
Y = min(Y_init, 1 - delta);

end

