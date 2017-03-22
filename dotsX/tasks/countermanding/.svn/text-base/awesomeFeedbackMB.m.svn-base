function feedback = awesomeFeedback(t)
% generate a string which shows error on a random numbers task

% copyright 2006 Benjamin Heasly
%   University of Pennsylvania

global FIRA
global ROOT_STRUCT

% copy of the paradigm properties, for easy access
dXp = struct(ROOT_STRUCT.dXparadigm(1));


taskName = rGet('dXtask', dXp.taski, 'name')

if strcmp(taskName, 'total')
    t = dXp;
else
    t = rGetTaskByName(taskName);
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





