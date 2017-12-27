START = 60;
END = 60;

H = '.1';
%H = '2';

all_data = [];
for i=START:END
    all_data = [all_data, load(strcat('Justin_44_main_',num2str(i),'.mat'))];
end

[~, dim1] = size(all_data);
[dim2, ~] = size(all_data(1).statusData);

time_elapsed = zeros(1,dim1 *dim2);
correct= zeros(1,dim1 *dim2);

for i=1:dim1
   for j=1:dim2
       
       path = all_data(i).statusData(j).stimstrct;
       %find index of last changepoint
       tind = path.tind;
       last_changepoint_index = nan;
       for k=tind:-1:1
           
            if (path.directionvc(tind) ~= path.directionvc(k))
                last_changepoint_index = k;
                break;
            end
       end
       
       index = i*j;
       
       %no changepoint,
       if (isnan(last_changepoint_index))
           last_changepoint_index = 1;
       end
       
       %find the time since the last changepoint
       time_elapsed(index) = path.stimtime(tind) - path.stimtime(last_changepoint_index);
       
       %find accuracy
       correct(index) = all_data(i).statusData(j).correct;
       
   end
end

%remove trials that do not have changepoint
ind_remove = find(~time_elapsed);
time_elapsed(ind_remove) = [];
correct(ind_remove) = [];

%TEMP
% time_elapsed = time_elapsed(200:300)
% correct = correct(200:300)

save(strcat('H_', H,'/correct'),'correct');
save(strcat('H_', H,'/time_elapsed'),'time_elapsed');