function [perms, m] = allPerm(n)
% recusrively get all permutations of the numbers 1 through n
%
%   n is a positive integer.
%
%   perms is an n-by-n! matrix containing all permutations of the integers
%   1:n.  perms(:,i) gives the ith permutation.
%
%   m is n!, the number of permutations;
%
%   see also randperm

% 2008 Benjamin Heasly at University of Pennsylvnia

if n < 1

    % idiot's case
    perms = [];
    m = 0;

elseif n==1

    %base case
    perms = 1;
    m = 1;

else

    % recursive case
    [small, p] = allPerm(n-1);

    % allocate the return
    %   this is inefficient in recursion, 
    %   but we have no pointers so deal with it
    m = factorial(n);
    perms = zeros(n,m);

    % mix recursive result with n
    %   in n different ways
    col = 1:p:m;
    short = logical(ones(1,n));
    for ii = 1:n
        short(ii) = false;
        perms(ii,col(ii):(col(ii)+p-1)) = n;
        perms(short,col(ii):(col(ii)+p-1)) = small;
        short(ii) = true;
    end
end