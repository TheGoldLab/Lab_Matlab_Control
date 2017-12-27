START = 7;
END = 7;

%6 is coh low
%7 is coh high

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
       %only want low coherence
       if(path.coherence == 80)
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
end

%remove trials that do not have changepoint
ind_remove = find(~time_elapsed);
time_elapsed(ind_remove) = [];
correct(ind_remove) = [];

save('H_2_coh_80/correct','correct');
save('H_2_coh_80/time_elapsed','time_elapsed');

time_elapsed = zeros(1,dim1 *dim2);
correct= zeros(1,dim1 *dim2);

for i=1:dim1
   for j=1:dim2
       
       path = all_data(i).statusData(j).stimstrct;
       %only want low coherence
       if(path.coherence == 11)
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
end

%remove trials that do not have changepoint
ind_remove = find(~time_elapsed);
time_elapsed(ind_remove) = [];
correct(ind_remove) = [];

save('H_2_coh_11/correct','correct');
save('H_2_coh_11/time_elapsed','time_elapsed');