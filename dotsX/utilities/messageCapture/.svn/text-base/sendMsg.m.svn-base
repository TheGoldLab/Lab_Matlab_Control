function sendMsg(messageString, noWait)
% function sendMsg(messageString, noWait)
%
% silly overload which allows UDP messaged to be captured locally instead
% of being sent to a remote machine

global fid time
% insert double quotes for single quotes
q = find(messageString == '''');
if ~isempty(q)
    r = logical(zeros(1, length(messageString)+(length(q))));
    r(q + (1:length(q))) = true;
    messageString(~r) = messageString;
    messageString(r) = '''';
end
fprintf(fid, 'sendMsg(''%s''); %% %.4f\n', messageString, GetSecs-time);