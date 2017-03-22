function demoFmin
%Demonstrate how MATLAB's gradient descent algorithms work.  These include:
%   fminbnd     find min f(x1 < x < x2) (one-dimensional)
%   fmincon     find min f(X1 < X < X2) (multidimensional)
%   fminimax    minimize the maximum of f(X1 < X < X2) (multidimensional)
%   fminsearch  find min f(X) (multidimensional, unconstrained)
%   fminunc     find min f(X) (multidimensional, unconstrained)

% Plot the iterative progress of any one of these estimation functions, for
% a known "error surface" in 1, 2, or 3 "parameters".

% 2007 by Benjamin Heasly
%   at University of Pennsylvania
global h

% number of dimensions
h.N = 2;

% domain of each dimension
h.L = 500;
h.S = linspace(0, 1, h.L);

% optional bounds on X
h.lb = zeros(1,h.N);
h.ub = ones(1,h.N);

% starting point
h.guess = h.ub*.1;

% basis functions of some error surfaces
h.errFuns = {'sin', 'cos', 'planar', 'steep_normal', 'shallow_normal'};
h.errFun = h.errFuns{3};
h.errSurf = [];

% which fit procedure?
h.fminFuns = {@fmincon, @fminsearch, @fminunc};
h.fminFun = h.fminFuns{3};

% fit options
h.opt = optimset('LargeScale', 'off', ...
    'TolFun', .00001, 'TolX', .001, ...
    'DiffMaxChange', 10*h.S(2), 'DiffMinChange', h.S(2));

h.iterations = 0;

% do some plotting
h.f = figure(543);
h.paramAx = subplot(2,1,1, 'Parent', h.f, ...
    'Xlim', [0 1], 'Ylim', [0 1]);

% pick some colors agains which green points will show
colormap(h.paramAx, 'spring')

% make transparent plots
h.alpha = .6;

h.errAx = subplot(4,1,3, 'Parent', h.f);
xlabel(h.errAx, 'iteration')
ylabel(h.errAx, 'f')

% initialize the plot
newSurf

% try a minimization
fmin

% use selected fmin to minimize the selected error surface
function fmin(obj, event, varargin)
global h

% which a fmin*?
switch char(h.fminFun)

    case 'fmincon'
        %FMINCON(FUN,X0,A,B,Aeq,Beq,LB,UB,NONLCON,OPTIONS)
        h.fit = fmincon(@errs, h.guess, ...
            [], [], [], [], ...
            h.lb, h.ub, [], h.opt);

    case 'fminsearch'
        %FMINSEARCH(FUN,X0,OPTIONS)
        h.fit = fminsearch(@errs, h.guess, h.opt);

    case 'fminunc'
        %FMINUNC(FUN,X0,OPTIONS)
        h.fit = fminunc(@errs, h.guess, h.opt);
end


% generate a new error surface
function newSurf(obj, event, varargin)
global h

% refresh axes
cla(h.paramAx)
cla(h.errAx)

switch h.errFun

    % compute one dimension with the error function
    case 'sin'
        a = sind(h.S*360);

    case 'cos'
        a = cosd(h.S*360);

    case 'planar'
        a = h.S;

    case 'steep_normal'
        a = normpdf(h.S, h.S(round(end/2)), h.S(round(end/10)));

    case 'shallow_normal'
        a = normpdf(h.S, h.S(round(end/2)), h.S(round(end)));
end

% make a symmetric N-d surface
%   plot it
switch h.N
    case 2
        h.errSurf = -(a'*a);

        % show two parameters plus error
        surf(h.S, h.S, h.errSurf, 'Parent', h.paramAx, ...
            'EdgeColor', 'none', 'FaceAlpha', h.alpha)
        view(h.paramAx, [30,45])
        xlabel(h.paramAx, 'param 1')
        ylabel(h.paramAx, 'param 2')
        zlabel(h.paramAx, 'f')

    case 3
        disp('3D takes a moment...')
        b = zeros(h.L, h.L, 'single');
        h.errSurf = zeros(h.L, h.L, h.L, 'single');
        b = a'*a;
        for ii = 1:h.L
            h.errSurf(:,:,ii) = b*a(ii);
        end

        % show three parameters
        view(h.paramAx, [30,45])
        xlabel(h.paramAx, 'param 1')
        ylabel(h.paramAx, 'param 2')
        zlabel(h.paramAx, 'param 3')

    otherwise
        h.errSurf = a;

        % show one parameter plus error
        line(X(1), err, 'Marker', '.', 'Parent', h.paramAx)
        view(h.paramAx, [0 90])
        xlabel(h.paramAx, 'param 1')
        ylabel(h.paramAx, 'f')
end
drawnow

function err = errs(X)
global h

% keep score
h.iterations = h.iterations + 1;

% round "parameters" in X to indices of error surface
X = min(max(X,0),1);
xi = interp1(h.S, 1:h.L, X, 'nearest');

% lookup the "error"
switch h.N
    case 2
        err = h.errSurf(xi(1), xi(2));

        % show two parameters plus error
        line(X(1), X(2), err, 'Marker', '.', 'Parent', h.paramAx)

    case 3
        err = h.errSurf(xi(1), xi(2), xi(3));

        % show three parameters
        line(X(1), X(2), X(3), 'Marker', '.', 'Parent', h.paramAx)

    otherwise
        err = h.errSurf(xi(1));
        % show one parameter plus error
        line(X(1), err, 'Marker', '.', 'Parent', h.paramAx)
end

% show evolution of the score
line(h.iterations, err, 'Parent', h.errAx, ...
    'Marker', '.', 'Color', [1 0 0])
drawnow