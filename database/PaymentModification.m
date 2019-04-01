function PaymentModification
blah = readtable('/Users/joshuagold/Psychophysics/Projects/Database/ExperimentArchive.txt');
disp('Type in Total Payment with Incentives included:')
blah{end,28} = input('');
writetable(blah,'/Users/joshuagold/Psychophysics/Projects/Database/ExperimentArchive.txt');