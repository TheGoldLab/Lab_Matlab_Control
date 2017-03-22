% repeat progress scripts for each subject

%prog = @RTProgress;
prog = @dPrimeProgress;
%prog = @RTOverview;
%prog = @ddRT_modalityAndSession;

subjDirs = { ...
    '/Volumes/XServerData/Psychophysics/response_modality/BMS', ...
    '/Volumes/XServerData/Psychophysics/response_modality/EAF', ...
    '/Volumes/XServerData/Psychophysics/response_modality/JIG', ...
    '/Volumes/XServerData/Psychophysics/response_modality/MAG', ...
    '/Volumes/XServerData/Psychophysics/response_modality/NKM', ...
    '/Volumes/XServerData/Psychophysics/response_modality/XL', ...
    '/Volumes/XServerData/Psychophysics/response_modality/CC', ...
    };
ns = length(subjDirs);

% manage screen realestate
%   move the bottom to 5
screens = get(0, 'MonitorPositions');
estate = screens(1,:);

% the dock is about 55 pixels in the way at the bottom
bottom = 55;
left = 5;
W = estate(3) - left;
H = estate(4) - bottom;

% a grid of figures
cols = 3;
rows = ceil(ns/cols);

% locate grid cells
w = W/cols;
h = H/rows;
for ii = 1:ns
    c = mod(ii-1, cols);
    r = rows - 1 - floor((ii-1)/cols);
    pos(ii,:) = [w*c+left, r*h+bottom, w-5, h-25];
end

for ii = 1:ns
    % do analysis and get results in a figure
    [f, axises] = feval(prog, subjDirs{ii});
    
    if isnan(f)
        return
    end

    % make a new figure for those results
    fig = figure(ii+432);
    clf(fig);
    kids = get(f, 'Children');
    set(kids, 'Parent', fig);

    % manage screen realestate
    set(fig, 'Position', pos(ii,:), 'MenuBar', 'none', 'ToolBar', 'none');
    
    drawnow
end
close(f)