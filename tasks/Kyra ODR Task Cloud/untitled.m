 H=.15;

for i=1:1000
                   Randnumber=rand;
                   seqLen1(i)=1;
                   while Randnumber>H
                       seqLen1(i)=seqLen1(i)+1;
                       Randnumber=rand;

                       if seqLen1(i)>8
                           seqLen1(i)=1;
                       end
                   end
end
hist(seqLen1,8,'r')
hold on

for i=1:1000
seqLen2(i)=ceil(exprnd(10));
while seqLen2(i)>8
   seqLen2(i)=ceil(exprnd(10)); 
end
end
hist(seqLen2,8)