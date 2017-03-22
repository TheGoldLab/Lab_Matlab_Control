% Check performance of different Matlab data structures.
% @param n the number of items to try adding to each data structure
% @ details
% Adds @a n values to a struct, and to a containers.Map object.  Measures
% how long it takes to add the values, and how long it takes to access
% them.  Plots a summary in the gcf() figure.
%
% @ingroup topsUtilities
function benchmarkStructVsMap(n)

if nargin < 1
    n = 10000;
end

% Add and retreive the same keys and data with struct vs containers.Map
keys = cell(1,n);
data = cell(1,n);
for ii = 1:n
    keys{ii} = sprintf('key%d', ii);
    data{ii} = ii;
end

% struct
s.(keys{1}) = data{1};
structAddTimes = zeros(1,n);
for ii = 1:n
    tic;
    s.(keys{ii}) = data{ii};
    structAddTimes(ii) = toc;
end

structGetTimes = zeros(1,n);
for ii = 1:n
    tic;
    a = s.(keys{ii});
    structGetTimes(ii) = toc;
end

% containers.Map
m = containers.Map(keys{1}, data{1}, 'uniformValues', true);
mapAddTimes = zeros(1,n);
for ii = 1:n
	tic;
    m(keys{ii}) = data{ii};
    mapAddTimes(ii) = toc;
end

mapGetTimes = zeros(1,n);
for ii = 1:n
    tic;
    a = m(keys{ii});
    mapGetTimes(ii) = toc;
end


subplot(2,1,1)
line(1:n, structAddTimes, 'Color', [1 0 0])
line(1:n, mapAddTimes, 'Color', [0 1 0])
ylabel('time to add iith datum')
legend('struct', 'map')

subplot(2,1,2)
line(1:n, structGetTimes, 'Color', [1 0 0])
line(1:n, mapGetTimes, 'Color', [0 1 0])
ylabel('time to get iith datum')
legend('struct', 'map')