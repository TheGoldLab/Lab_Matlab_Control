function states_ = gXrandom_statelist(varargin)
varargin{:}
waitMove = { ...
    'dXkbHID',  {'f', 'slowDown', 'j', 'slowUp', 'h', 'newNumber', 1}; ...
    'dXgameHID', {[3:6]', 'newNumber', 7, 'slowDown', 8, 'slowUp', ...
    [1, -1], 'fastDown', [1, 1], 'fastUp', 1}};

b = [1,7,8]';
goBack = { ...
    'dXkbHID',  {{['fj']',0}, 'waitMove'}; ...
    'dXgameHID', {[b,0*b], 'waitMove'}};

rU = @rVarUpdate;
cm = @compareEstimate;
mv = @moveLine;
rE = @resetEst;

nxt = 'next';
err = 'error';
wmv = 'waitMove';
sd = 'slowDown';
su = 'slowUp';
fd = 'fastDown';
fu = 'fastUp';
dr = 'dXdistr';
rt = {'dXtext', 1, 'string'};


t = true;
f = false;

% THE STATE DINNER. Careful -- this MUST be a double cellery.
%
%   You know those guitars that are like *double* guitars?
%
%   name        fun  args                        jump    wait  repsDrawQuery   cond
arg_dXstate = {{ ...
    'reset',    rE, {1, varargin{1}, []},          nxt,  0,     0,  3,  0,       {};
    'waitMove', {}, {},                            'end',6e4,   0,  3,  waitMove,{}; ...
    'slowDown', mv, {2, 2, -1, t, [],[]},          sd,   150,   0,  3,  goBack,  {}; ...
    'slowUp',   mv, {2, 2, +1, t, [],[]},          su,   150,   0,  3,  goBack,  {}; ...
    'fastDown', mv, {2, 2, -1, t, [],[]},          fd,   0,     0,  3,  goBack,  {}; ...
    'fastUp',   mv, {2, 2, +1, t, [],[]},          fu,   0,     0,  3,  goBack,  {}; ...
    'newNumber',rU, {dr},                          nxt,  0,     0,  0,  0,       {}; ...
    'newLine',  mv, {1, 1, rt, f, [], varargin{2}},nxt,  0,     0,  0,  0,       {}; ...
    'compare',  cm, {6, []},                       nxt,  0,     0,  3,  0,       {}; ...
    'end',      {}, {},                            'x',  0,     0,  0,  0,       {}; ...
  
    }};
sz = size(arg_dXstate{1}, 1);

tony = {'current', true, true, false};
states_ = {'dXstate', sz, tony, arg_dXstate};