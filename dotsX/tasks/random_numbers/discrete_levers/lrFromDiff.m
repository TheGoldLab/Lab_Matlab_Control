function lr_ = lrFromDiff(ptr1, ptr2)
%return right=1 if *ptr1 >= *ptr2, or else left=0

diff = rGet(ptr1{:}) - rGet(ptr2{:});
lr_ = diff >= 0;

%ffdisp([rGet(ptr1{:}), rGet(ptr2{:}), lr_])