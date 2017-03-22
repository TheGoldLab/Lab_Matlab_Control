% Demonstrate the Tower of Psych (tops) foundation classes with a game.
% @details
% "Encounter" is a game which demonstrates Tower of Psych.  It's a
% simplified homage to the battle seqences in the "Final Fantasy" Nintendo
% games.  In the game, you control several characters with different speeds
% and attack powers. Your job is to attack monsters (by clicking on them)
% and defeat them before they defeat you (by attacking you periodically).
% @details
% Returns a topsRunnable object for organizing the structure and flow
% of the game.  The objects run() method will start the game.  Also returns
% as a second output a topsGroupedList object which contains data and
% objects that make up the game.
%
% @ingroup topsDemos
function [runnable, list] = configureEncounter()
% By benjamin.heasly@gmail.com,
%   2009 Seattle, WA
%   2012 Portland, Me.

%% Create, organize, and return objects.

% top-level data object, add arbitrary parameters
list = topsGroupedList();

% top-level control object
runnable = topsTreeNode('Encounter');
runnable.startFevalable = {@gameSetup, list};
runnable.finishFevalable = {@gameTearDown, list};
list.addItemToGroupWithMnemonic(runnable, 'game', 'runnable');

% low-level function queues for character and monster attacks
%   add dispatch method to function queue
monsterQueue = EncounterBattleQueue();
characterQueue = EncounterBattleQueue();
list.addItemToGroupWithMnemonic(monsterQueue, 'game', 'monsterQueue');
list.addItemToGroupWithMnemonic(characterQueue, 'game', 'characterQueue');

% batch of functions to call, with arguments
battleCalls = topsCallList('battle calls');
battleCalls.addCall({@drawnow}, 'drawnow');
battleCalls.addCall( ...
    {@dispatchNextFevalable, monsterQueue}, 'monsterDispatch');
battleCalls.addCall( ...
    {@dispatchNextFevalable, characterQueue}, 'characterDispatch');
battleCalls.addCall( ...
    {@checkBattleStatus, list, battleCalls}, 'battleStatus');
list.addItemToGroupWithMnemonic(battleCalls, 'game', 'battleCalls');

% Create an array of battler objects to represent player characters.
%   add character array to the list
%   create a wake-up timers for character
%   add each timer to a call list
Goonius = EncounterBattler();
Goonius.name = 'Goonius';
Goonius.attackInterval = 15;
Goonius.attackMean = 20;
Goonius.maxHP = 50;
Goonius.restoreHP();

Jet = EncounterBattler();
Jet.name = 'Jet';
Jet.attackInterval = 5;
Jet.attackMean = 2;
Jet.maxHP = 50;
Jet.restoreHP();

Hero = EncounterBattler();
Hero.name = 'Hero';
Hero.attackInterval = 5;
Hero.attackMean = 10;
Hero.maxHP = 10;
Hero.restoreHP();

characters = [Goonius, Jet, Hero];
list.addItemToGroupWithMnemonic(characters, 'game', 'characters');
list.addItemToGroupWithMnemonic({}, 'game', 'activeCharacter');

charCalls = topsCallList('character calls');
for ii = 1:length(characters)
    bt = EncounterBattleTimer();
    charTimers(ii) = bt;
    bt.loadForRepeatIntervalWithCallback( ...
        characters(ii).attackInterval, ...
        {@characterWakesUp, characters(ii), list});
    charCalls.addCall({@tick, bt}, characters(ii).name);
end
list.addItemToGroupWithMnemonic(charCalls, 'game', 'charCalls');
list.addItemToGroupWithMnemonic(charTimers, 'game', 'charTimers');


% Create battler objects to reperesent several types of monster
%   make several arrays with interesting groups of monsters
%   add each monster group to the list
%   create wake-up timers for monsters in each group
%   add each timer to a call list
isMonster = true;
Evil = EncounterBattler(isMonster);
Evil.name = 'Evil Hero';
Evil.attackInterval = 5;
Evil.attackMean = 7;
Evil.maxHP = 1;
Evil.restoreHP();

Fool = EncounterBattler(isMonster);
Fool.name = 'Fool';
Fool.attackInterval = 10;
Fool.attackMean = 0.5;
Fool.maxHP = 5;
Fool.restoreHP();

Boxer = EncounterBattler(isMonster);
Boxer.name = 'Boxer';
Boxer.attackInterval = 3;
Boxer.attackMean = 1;
Boxer.maxHP = 20;
Boxer.restoreHP();

Robot = EncounterBattler(isMonster);
Robot.name = 'Iron Robot';
Robot.attackInterval = 15;
Robot.attackMean = 10;
Robot.maxHP = 100;
Robot.restoreHP();

Unknown = EncounterBattler(isMonster);
Unknown.name = '???';
Unknown.attackInterval = 25;
Unknown.attackMean = 1000;
Unknown.maxHP = 15;
Unknown.restoreHP();

% group monsters into several overlapping groups,
%   add groups top-level grouped list object
%   create a runnable tree node for each group, add to top-level tree node
group(1).name = 'some fools';
group(1).monsters = [Fool.copy(), Fool.copy(), Fool.copy(), Fool.copy()];

group(2).name = 'an iron robot';
group(2).monsters = Robot.copy();

group(3).name = 'Bizzaro Guys';
group(3).monsters = [Evil.copy(), Boxer.copy(), Fool.copy()];

group(4).name = 'a whole dojo';
group(4).monsters = [Evil.copy(), Boxer.copy(), Boxer.copy(), ...
    Boxer.copy(), Boxer.copy(), Boxer.copy()];

group(5).name = 'a mysterious figure';
group(5).monsters = Unknown.copy();

for ii = 1:length(group)
    groupCalls = topsCallList(group(ii).name);
    groupTimers = EncounterBattleTimer.empty;
    for jj = 1:length(group(ii).monsters)
        bt = EncounterBattleTimer();
        groupTimers(jj) = bt;
        bt.loadForRepeatIntervalWithCallback( ...
            group(ii).monsters(jj).attackInterval, ...
            {@monsterWakesUp, group(ii).monsters(jj), list});
        groupCalls.addCall({@tick, bt}, group(ii).monsters(jj).name);
    end
    list.addItemToGroupWithMnemonic( ...
        group(ii).monsters, 'monsters', group(ii).name);
    list.addItemToGroupWithMnemonic( ...
        groupTimers, 'monsterTimers', group(ii).name);
    list.addItemToGroupWithMnemonic( ...
        groupCalls, 'monsterCalls', group(ii).name);
    
    % combine call lists that using a concurrent composite,
    %   which will run() them concurrently
    concurrents = topsConcurrentComposite(group(ii).name);
    concurrents.addChild(charCalls);
    concurrents.addChild(groupCalls);
    concurrents.addChild(battleCalls);
    
    battleNode = runnable.newChildNode(group(ii).name);
    battleNode.startFevalable = {@battleSetup, battleNode, list};
    battleNode.addChild(concurrents);
    battleNode.finishFevalable = {@battleTearDown, battleNode, list};
end
list.addItemToGroupWithMnemonic('', 'game', 'activeMonsterGroup');


%% Define functions for game behavior.

% Initialize a whole new Encounter game.
function gameSetup(list)
% create the game GUI
fig = figure( ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'Name', 'When a hero wakes up, click on a bad guy.', ...
    'NumberTitle', 'off', ...
    'Color', [1 1 1]*0.5);
list.addItemToGroupWithMnemonic(fig, 'game', 'figure');
ax = axes( ...
    'Parent', fig, ...
    'Box', 'on', ...
    'XTick', [], ...
    'XLim', [0 1], ...
    'YTick', [], ...
    'YLim', [0 1], ...
    'Units', 'normalized', ...
    'Position', [.01 .25, .98, .5], ...
    'Color', [0 0 0]);
list.addItemToGroupWithMnemonic(ax, 'game', 'axes');

% initialize each character
characters = list.getItemFromGroupWithMnemonic('game', 'characters');
nChars = length(characters);
for ii = 1:nChars
    axesPos = subposition([0 0 1 1], nChars, nChars+1, ii, nChars+1);
    characters(ii).restoreHP();
    characters(ii).makeGraphicsForAxesAtPositionWithCallback( ...
        ax, axesPos, []);
end

% Initialize each Encounter battle.
function battleSetup(battleNode, list)
% show the name of this battle.
groupName = battleNode.name;
ax = list.getItemFromGroupWithMnemonic('game', 'axes');
if ~ishandle(ax)
    return;
end
xlabel(ax, sprintf('You encountered %s!', groupName));

% refresh characters for the next battle
list.addItemToGroupWithMnemonic({}, 'game', 'activeCharacter');
characters = list.getItemFromGroupWithMnemonic('game', 'characters');
nChars = length(characters);
for ii = 1:nChars
    characters(ii).hideHighlight();
end

% get the monster group for this battle
monsterGroup = list.getItemFromGroupWithMnemonic('monsters', groupName);
list.addItemToGroupWithMnemonic(groupName, 'game', 'activeMonsterGroup');

% initialize monsters and position in axes
for ii = 1:length(monsterGroup)
    monsterGroup(ii).restoreHP();
    axesPos = subposition([0 0 1 1], ...
        nChars, nChars+1, mod(ii-1, nChars)+1, ceil(ii/nChars));
    cb = @(source, event) characterSelectVictim(source, event, list);
    monsterGroup(ii).makeGraphicsForAxesAtPositionWithCallback( ...
        ax, axesPos, cb);
end

% prepare wake-up queues for characters and monsters
characterQueue = list.getItemFromGroupWithMnemonic( ...
    'game', 'characterQueue');
characterQueue.isLocked = false;
monsterQueue = list.getItemFromGroupWithMnemonic( ...
    'game', 'monsterQueue');
monsterQueue.flushQueue();

% start wake-up timers for characters and monsters
charTimers = list.getItemFromGroupWithMnemonic('game', 'charTimers');
monsterTimers = list.getItemFromGroupWithMnemonic( ...
    'monsterTimers', groupName);
for t = [charTimers, monsterTimers]
    t.beginRepetitions();
end


% Enqueue a character to become the active character.
function characterWakesUp(character, list)
characterQueue = list.getItemFromGroupWithMnemonic( ...
    'game', 'characterQueue');
characterQueue.addFevalable( ...
    {@characterBecomesTheActiveCharacter, character, list});


% Let the next character become active (may attack).
function characterBecomesTheActiveCharacter(character, list)
characterQueue = list.getItemFromGroupWithMnemonic( ...
    'game', 'characterQueue');
characterQueue.isLocked = true;
character.showHighlight();
list.addItemToGroupWithMnemonic(character, 'game', 'activeCharacter');


% Let the active character attack.
function characterSelectVictim(monsterGraphic, event, list)
activeCharacter = list.getItemFromGroupWithMnemonic( ...
    'game', 'activeCharacter');
if ~isempty(activeCharacter)
    % attack a victim!
    battlerAttacksBattler( ...
        activeCharacter, get(monsterGraphic, 'UserData'));
    
    % resign as the active character
    list.addItemToGroupWithMnemonic({}, 'game', 'activeCharacter');
    
    % unfreeze the queue for the next active character
    characterQueue = list.getItemFromGroupWithMnemonic( ...
        'game', 'characterQueue');
    characterQueue.isLocked = false;
end

% Let a monster wake up and queue up to attack.
function monsterWakesUp(monster, list)
characters = list.getItemFromGroupWithMnemonic('game', 'characters');
alive = find(~[characters.isDead]);
if ~isempty(alive)
    victim = characters(alive(ceil(rand*length(alive))));
    monsterQueue = list.getItemFromGroupWithMnemonic( ...
        'game', 'monsterQueue');
    monsterQueue.addFevalable({@battlerAttacksBattler, monster, victim});
end

% Let one battler attack another, with graphics and timing.
function battlerAttacksBattler(attacker, victim)
attacker.showHighlight();
if attacker.isMonster
    pause(.5)
end
attacker.attackOpponent(victim);
pause(.5)
victim.hideDamage();
attacker.hideHighlight();

% Figure out if a battle or the game is over.
function checkBattleStatus(list, battleCalls)
% prevent eternal locking of characterQueue
activeCharacter = list.getItemFromGroupWithMnemonic( ...
    'game', 'activeCharacter');
if ~isempty(activeCharacter) && activeCharacter.isDead
    characterQueue = list.getItemFromGroupWithMnemonic( ...
        'game', 'characterQueue');
    characterQueue.isLocked = false;
end

% check if all characters are dead
characters = list.getItemFromGroupWithMnemonic('game', 'characters');
if all([characters.isDead])
    battleCalls.isRunning = false;
    disp('Anihiliation!')
end

% check if all monsters are dead
groupName = list.getItemFromGroupWithMnemonic( ...
    'game', 'activeMonsterGroup');
monsterGroup = list.getItemFromGroupWithMnemonic( ...
    'monsters', groupName);
if all([monsterGroup.isDead])
    battleCalls.isRunning = false;
    disp('Victory!')
end

% check if the game figure was closed
fig = list.getItemFromGroupWithMnemonic('game', 'figure');
if ~ishandle(fig)
    battleCalls.isRunning = false;
    disp('Quit.')
end

% Clean up after each battle.
function battleTearDown(battleNode, list)
% clear monster group from axes
groupName = battleNode.name;
monsterGroup = list.getItemFromGroupWithMnemonic( ...
    'monsters', groupName);
for ii = 1:length(monsterGroup)
    monsterGroup(ii).deleteGraphics();
end

% Clean up after a whole Encounter game.
function gameTearDown(list)
characters = list.getItemFromGroupWithMnemonic('game', 'characters');
nChars = length(characters);
for ii = 1:length(nChars)
    characters(ii).deleteGraphics();
end
f = list.getItemFromGroupWithMnemonic('game', 'figure');
if ishandle(f)
    close(f)
end