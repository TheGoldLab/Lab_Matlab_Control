function a = angdiff(v1, v2)
%ANGDIFF Summary of this function goes here
%   Detailed explanation goes here
v1x = cos(v1);
v1y = sin(v1);

v2x = cos(v2);
v2y = sin(v2);

a=zeros(size(v1));

for i=1:length(v1)
a(i) = acos([v1x(i) v1y(i)]*[v2x(i) v2y(i)]');

if v1(i)>v2(i)
    a(i)=-a(i);
end

end 
end

