% Demonstrate some key behaviors of the topsStateMachine class.
% @details
% Returns a the topsStateMachine object configured to do a little demo in
% the Command Window.  The object's run() method will start the demo.  The
% object's gui() method will show internal details.
% @code
% sm = demoStateMachine();
% sm.run();
% sm.gui();
% @endcode
%
% @ingroup topsDemos
function sm = demoStateMachine()

% Create a state machine object and give it a name
sm = topsStateMachine('demo machine');

% chose functions to call before and after doing state traversal
sm.startFevalable = {@disp, 'Starting state traversal'};
sm.finishFevalable = {@disp, 'Finished state traversal'};

% choose a function to call when transitioning between states
%   should expect a 1x2 struct array of "to" and "from" state data
sm.transitionFevalable = {@transitioning};

% define a "begin", "middle", and "end" functions
doBegin = {@disp, ' begin'};
doMiddle = {@disp, ' middle'};
doEnd = {@disp, ' end'};

% define a function which returns a value from user input
%   if the returned value is a state name, it will cause a transitions to
%   the named state.
askInput = {@getStateInput};

% define a few states with cell array syntax.
%   Each row specifies a state, each column specifies state property.
statesInfo = { ...
    'name'      'timeout'   'next'      'entry'     'input'; ...
    'begin'     0           'middle'	doBegin     {}; ...
    'middle'    0.1         'end'       doMiddle    askInput; ...
    'end'       0           ''          doEnd,      {}; ...
    };
sm.addMultipleStates(statesInfo);

% define one other state with struct syntax.
%   Each struct field specifies a state property.
surprise.name = 'surprise';
surprise.next = 'end';
message = sprintf(' ---\n You found the secret state!\n ---');
surprise.entry = {@disp, message};
sm.addState(surprise);

sm.run()
% An arbitrary function to call between states.
function transitioning(transitionStates)
disp(sprintf('Transitioning from %s to %s', ...
    transitionStates(1).name, transitionStates(2).name));

% A function to get user input for one state.
function stateName = getStateInput
stateName = input(' OK, which state next? ', 's');