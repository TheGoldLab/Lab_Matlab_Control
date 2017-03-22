clear all
global ROOT_STRUCT FIRA
rInit('debug')

name = 'gXrandom_helpers';
rAdd('dXtask', 1, 'name', name);
rGroup(name)

while rGetTaskByName(name, 'isAvailable')

    buildFIRA_addTrial('add');
    rBatch('saveToFIRA')
    rBatch('endTrial', {'dXdistr'}, true, 'testNoState')
end

eNum = strcmp(FIRA.ecodes.name, 'random_number_value');

clf(figure(85))
changes = rGet('dXdistr', 1, 'changeMetaD');
lc = length(changes);

totTrials = rGet('dXdistr', 1, 'totTrials');

blocks = [changes+1, totTrials];

for c = 1:lc
    subplot(lc,1,c)
    b = blocks(c):blocks(c+1)-1;
    hist(FIRA.ecodes.data(b, eNum), 1:100)
    xlim([1, 100])
end