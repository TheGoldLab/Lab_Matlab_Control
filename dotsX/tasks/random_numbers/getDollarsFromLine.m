function dollars = getDollarsFromLine

% get the total points from the task
points = rGet('dXtask', 1, 'userData');

maxPoints = 50*800;
maxEarn = 20;
dollars = maxEarn*points/maxPoints;