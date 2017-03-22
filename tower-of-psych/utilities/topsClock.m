% Get the current time as a number.
% @details
% Returns the time in seconds since topsClock() was first called.
% topsClock() uses a private instance of Matlab's builtin tic()-toc()
% stopwatch.
%
% @ingroup topsUtilities
function t = topsClock()

% Create a private timer
persistent topsTic
if isempty(topsTic)
    topsTic = tic;
end

% Return the current timer time
t = toc(topsTic);