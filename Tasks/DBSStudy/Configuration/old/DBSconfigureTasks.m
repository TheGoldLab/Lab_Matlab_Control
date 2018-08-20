function DBSconfigureTasks(topNode)
% function DBSconfigureTasks(topNode)
%
% This function sets up tasks for a DBS experiment. Uses the 'taskSpecs'
%  cell array stored in the datatub, of the form:
%     {<TaskType1> <trialsPerCondition1> <TaskType2> <trialsPerCondition2>
%     <etc>}
%
% Arguments:
%  topNode ... the topsTreeNode at the top of the hierarchy

