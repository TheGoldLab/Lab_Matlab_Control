% show a summary of data from Ling's readout task
clear all
global FIRA

% get some data
concatenateFIRAs(false);
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(10,5);

% find all the stim direction conditions
eCondition = strcmp(FIRA.ecodes.name, 'dot_dir_condition');
condition = FIRA.ecodes.data(:,eCondition);
conditions = unique(condition);
nConditions = length(conditions);

% find the plus/minus conditions
ePlusMinus = strcmp(FIRA.ecodes.name, 'plus_minus');
plusMinus = FIRA.ecodes.data(:,ePlusMinus);

% compute real dot direction from known increment
inc = 20;
realDir = condition + inc*plusMinus;
realDirs = unique(realDir);
nRealDirs = length(realDirs);

% find good and correct trials
eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = logical(FIRA.ecodes.data(:,eGood));
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

f = figure(33);
clf(f)
pol = subplot(1,2,1);
lin = subplot(1,2,2);

% look at each condition for % correct
for ii = 1:nConditions

    % select trials from this condition
    selectCondition = condition == conditions(ii);

    n_condition(ii) = sum(selectCondition & good);
    Pc_condition(ii) = sum(correct(selectCondition & good))/n_condition(ii);
end

% look at each real direction for % correct
for ii = 1:nRealDirs

    % select trials from this condition
    selectDir = realDir == realDirs(ii);

    n_dir(ii) = sum(selectDir & good);
    Pc_dir(ii) = sum(correct(selectDir & good))/n_dir(ii);
end

line_condition = line(conditions, Pc_condition', 'Parent', lin);
set(line_condition, 'Color', [0 0 1], 'Marker', '*', 'LineStyle', 'none')
hold(lin, 'on')
line_dir = line(realDirs, Pc_dir', 'Parent', lin);
set(line_dir, 'Color', [1 0 0], 'Marker', '*', 'LineStyle', 'none')


pol_condition = polar(pi*conditions/180, Pc_condition', 'Parent', pol);
set(pol_condition, 'Color', [0 0 1], 'Marker', '*', 'LineStyle', 'none')
hold(pol, 'on')
pol_dir = polar(pi*realDirs/180, Pc_dir', 'Parent', pol);
set(pol_dir, 'Color', [1 0 0], 'Marker', '*', 'LineStyle', 'none')