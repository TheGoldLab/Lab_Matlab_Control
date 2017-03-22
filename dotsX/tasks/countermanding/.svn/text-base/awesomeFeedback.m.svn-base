function feedback = awesomeFeedback(dXp)
% generate a string which shows error on a random numbers task

% copyright 2006 Benjamin Heasly
%   University of Pennsylvania

global FIRA
global ROOT_STRUCT

if isempty(FIRA)
    feedback = 'getting started...';
    return
end

GTindex = getFIRA_ecc('good_trial')
CORindex = getFIRA_ecc('correct')
INCindex = getFIRA_ecc('incorrect')

%%getting data for the variables of interest

good = FIRA.ecodes.data(:, GTindex)
cor  = FIRA.ecodes.data(:, CORindex)
inc  = FIRA.ecodes.data(:, INCindex)

realcor  = ~isnan(cor)

total_income = sum(good*0.02) + sum(realcor*.02)

feedback = sprintf('So far you have earned a total of $%1.2f%', total_income)





