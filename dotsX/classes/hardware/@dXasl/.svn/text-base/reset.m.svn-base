function a_ = reset(a_, start_time)
%reset method for class dXasl: return to virgin state
%   a_ = reset(a_, start_time)
%
%   Some DotsX classes can revert to a consistent state, as though just
%   created, with their reset methods.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% resets a 'dXasl' object
%-% and returns the updated object
%----------Special comments-----------------------------------------------
%
%   See also reset dXasl

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

if a_.active

    % let mex function refresh itself
    as('reset');

    if nargin < 2 || isempty(start_time)
        a_.offsetTime = 0;
    else
        %a_.offsetTime = round((GetSecs - start_time)*1000);
        a_.offsetTime = -round(start_time*1000);
    end

    % let the dead rest and the past remain the past
    a_.values    = [];
    a_.recentVal = 1;

    % take this opportunity to hog time and do graphics
    if (a_.showPlot)

        if isempty(a_.fig) || ~ishandle(a_.fig)
            % if there's no figure open but there should be, open one and
            % set handles and properties for figure window and axes objects.

            a_.fig  = figure(99);
            a_.ax   = gca;

            % most of these properties allow faster MATLAB drawing
            set(a_.fig,                             ...
                ...'WindowStyle',          'docked', ...
                'Units',                'characters',...
                'BackingStore',         'off',      ...
                'DoubleBuffer',         'on',      ...
                'MenuBar',              'none',     ...
                'Name',                 'Eye Position!',...
                'NextPlot',             'add',      ...
                'RendererMode',         'manual',   ...
                'Renderer',             'painters',   ...
                'SelectionHighlight',   'off',      ...
                'Toolbar',              'none');

            % Position the aslwindow just below right of the main dXgui
            mainPos = get(findobj('Type', 'figure', ...
                'Name', 'dXgui'), 'Position');
            if ~isempty(mainPos)
                aslPos = get(a_.fig, 'Position');
                h = mainPos(4)*1.5;
                aslPos = [mainPos(1), mainPos(2)-h-2, mainPos(3), h];
                set(a_.fig, 'Position', aslPos);
            end

            % don't bomb if degreeRect isn't set
            if isempty(a_.degreeRect)
                a_.degreeRect = [-20,-20,40,40];
            end

            Xaxis=[a_.degreeRect(1),a_.degreeRect(1)+a_.degreeRect(3)];
            Yaxis=[a_.degreeRect(2),a_.degreeRect(2)+a_.degreeRect(4)];
            Xtick=[Xaxis(1),mean(Xaxis),Xaxis(end)];
            Ytick=[Yaxis(1),mean(Yaxis),Yaxis(end)];

            % these properties allow faster MATLAB drawing and proper viewing
            set(a_.ax,                              ...
                'Color',                'k',        ...
                'DataAspectRatioMode',  'manual',   ...
                'DrawMode',             'fast',     ...
                'FontUnits',            'points',   ...
                'GridLineStyle',        ':',        ...
                'Layer',                'top',      ...
                'NextPlot',             'add',      ...
                'PlotBoxAspectRatio',   [1,1,1],    ...
                'PlotBoxAspectRatioMode','manual',  ...
                'SelectionHighlight',   'off',      ...
                'XColor',               'r',        ...
                'XGrid',                'on',       ...
                'XLim',                 Xaxis,      ...
                'XTick',                Xtick,      ...
                'XDir',                 'normal',   ...
                'XLimMode',             'manual',   ...
                'YColor',               'r',        ...
                'YGrid',                'on',       ...
                'YLim',                 Yaxis,      ...
                'YTick',                Ytick,      ...
                'YDir',                 'normal',   ...
                'YLimMode',             'manual',   ...
                'DefaultRectangleEdgeColor',    'w',    ...
                'DefaultRectangleEraseMode',    'background',...
                'DefaultRectangleFaceColor',    'none',     ...
                'DefaultRectangleLineStyle',    '-',        ...
                'DefaultRectangleLineWidth',    2);

        elseif ishandle(a_.ax)
            % if figure is open, just refresh the axes
            %   and redraw screen objects
            cla(a_.ax);

            % plot object to represent eye position
            % always need a new instance after cla
            a_.plt = plot(a_.ax,        ...
                0,                      0,          ...
                'Color',                [1 1 .5],	...
                'EraseMode',            'xor',	...
                'LineStyle',            'none',     ...
                'LineWidth',            2, ...
                'Marker',               '.',        ...
                'MarkerSize',           15,         ...
                'SelectionHighlight',   'off',      ...
                'XDataMode',            'manual');

            % plot circles that represent the dX__ graphics objects
            %   tht are specified in a_.showPtr
            %   a_.showPtr has the form
            %   {{'classname' [,ind]}; [{'classname' [,ind]}; ... ] }
            ptr = a_.showPtr;
            if ~isempty(ptr)

                % loop through rows of pointers
                for p = 1:size(ptr,1)

                    if (size(ptr{p},2) == 1 || isempty(ptr{p}(2)))

                        % if no index given, show all objects of type ...
                        Objs = rGet(ptr{p}{1});

                    else

                        % ... otherwise use indicated objects
                        Objs = rGet(ptr{p}{1},ptr{p}{2});

                    end

                    if ~isempty(Objs)

                        % Get relevant properties of graphics objects.
                        % Objects like "dXtargets" describe many targets,
                        % show them all.
                        xs=[];
                        if isfield(Objs,'x')
                            xs = [Objs.x];
                        end
                        ys = [];
                        if isfield(Objs,'y')
                            ys = [Objs.y];
                        end
                        if isfield(Objs,'diameter')
                            ds = [Objs.diameter];
                        else
                            % default to 1 deg diameter
                            ds = ones(size(xs));
                        end

                        cs = cell(length(xs));
                        if isfield(Objs,'color')
                            % get interesting colors
                            %   colors have 1, 3, or 4 columns
                            for ii = 1:length(xs)
                                cs{ii} = Objs(ii).color(1:3)./255;
                            end
                        else
                            % default to white
                            for ii = 1:length(xs)
                                cs{ii} = [1 1 1];
                            end
                        end

                        % move positions from center to bottom left
                        xs = xs - ds/2;
                        ys = ys - ds/2;

                        if ~isempty(xs)
                            for ii = 1:length(xs)

                                r = rectangle(  ...
                                    'Curvature',	[1,1],  ...
                                    'EdgeColor',	cs{ii}, ...
                                    'Parent',       a_.ax,	...
                                    'Position',     [xs(ii),ys(ii),ds(ii),ds(ii)]);
                            end
                        end
                    end
                end
            end

            % show all these graphics (~40ms slow!) before the next trial
            drawnow;

        end

    elseif ~isempty(a_.fig) && ishandle(a_.fig)

        % not showing plot, get rid of it
        close(a_.fig)
    end
end