% Demonstrate random dot kinetograms, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableDotKinetogram2(delay)

if nargin < 1
    delay = 10;
end

commonProperties = struct( ...
   'pixelSize',    3, ...
   'density',      200, ...
   'diameter',     10, ...
   'direction',    0, ...
   'interleaving', 3, ...
   'coherence',    20);

% create a kinetogram with minimal motion features
dots1 = dotsDrawableDotKinetogram();
dots1.stencilNumber = 1;
dots1.xCenter = -5;

dots2 = dotsDrawableDotKinetogram();
dots2.stencilNumber = 2;
dots2.xCenter = 5;
dots2.coherenceSTD = 30;

for ff = fieldnames(commonProperties)'
   dots1.(ff{:}) = commonProperties.(ff{:});
   dots2.(ff{:}) = commonProperties.(ff{:});
end

% Aggrigate the kinetograms into one ensemble
kinetograms = topsEnsemble('kinetograms');
kinetograms.addObject(dots1);
kinetograms.addObject(dots2);

% automate the task of drawing all the objects
%   the static drawFrame() takes a cell array of objects
isCell = true;
kinetograms.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], isCell);

%% animate for the duration given above
try
    % get a drawing window
    %sc=dotsTheScreen.theObject;
    %sc.reset('displayIndex', 2);
    dotsTheScreen.reset('displayIndex', 0);
    dotsTheScreen.openWindow();
    
    % get the objects ready to use the window
    kinetograms.callObjectMethod(@prepareToDrawInWindow);
    
    % let the ensemble animate for a while
    kinetograms.run(delay);
    
    % close the OpenGL drawing window
    dotsTheScreen.closeWindow();
    
catch err
    dotsTheScreen.closeWindow();
    rethrow(err)
end