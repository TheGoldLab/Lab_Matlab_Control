START = 7;
END = 7;

all_data = [];
for i=START:END
    all_data = [all_data, load(strcat('Justin_44_main_',num2str(i),'.mat'))];
end

[~, dim1] = size(all_data);
[dim2, ~] = size(all_data(1).statusData);

time_elapsed = zeros(1,dim1 *dim2);
correct= zeros(1,dim1 *dim2);

count_0 = 0;
count_180 = 0;

count_0_last = 0;
count_180_last = 0;
for i=1:dim1
   for j=1:dim2
       
       path = all_data(i).statusData(j);
       
       if(path.direction0 == 0)
           count_0 = count_0 + 1;
         
       elseif(path.direction0 == 180)
           count_180 = count_180 + 1;
           
       end
       
       if(path.directionvc(end) == 0)
           count_0_last = count_0_last + 1;
           
       elseif(path.directionvc(end) == 180)
           count_180_last = count_180_last + 1;
           
       end
         
   end
   
end

count_0;
count_180;
count_0_last
count_180_last