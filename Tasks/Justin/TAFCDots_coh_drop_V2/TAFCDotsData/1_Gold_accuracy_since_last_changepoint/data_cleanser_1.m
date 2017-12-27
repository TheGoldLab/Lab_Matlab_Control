function [] = data_cleanser(file_name, H,coh)

all_data = [];
for i=1:length(file_name)
    all_data = [all_data, load(file_name{i})];
    %NEW
    %remove uncompleted trials
    all_data(end).statusData = all_data(end).statusData(~isnan([all_data(end).statusData.H]));
end

[~, dim1] = size(all_data);

%NEW - Each dim2 has a different size. This finds each size and stores in
%dim2Array
dim2Array = zeros(1,dim1);
for i=1:dim1
    [dim2, ~] = size(all_data(i).statusData);
    dim2Array(i) =dim2;
end


%NEW - changed to NAN from zeros
time_elapsed = NaN(1,dim1 *dim2);
correct= NaN(1,dim1 *dim2);
direction_before_drop = NaN(1,dim1*dim2);
direction_first =  NaN(1,dim1*dim2);
direction_choice = NaN(1,dim1*dim2);

for i=1:dim1
   dim2 = dim2Array(i);
   for j=1:dim2
       if (strcmp(coh,'high'))
           if (all_data(i).statusData(j).coherencevc(end) < .50)
               continue
           end
       elseif (strcmp(coh,'low'))
           if (all_data(i).statusData(j).coherencevc(end) > .50)
               continue
           end
       end
       directionvc = all_data(i).statusData(j).directionvc;
       coherencevc = all_data(i).statusData(j).coherencevc;
       
       %find index of last changepoint
       tind = length(directionvc);
       last_changepoint_index = nan;
       for k=tind:-1:1
           
            if (directionvc(tind) ~= directionvc(k))
                last_changepoint_index = k;
                break;
            end
       end
       
       index = i*j;
       
       %no changepoint,
       if (isnan(last_changepoint_index))
           last_changepoint_index = 1;
       end
       
       %find accuracy
       correct(index) = all_data(i).statusData(j).correct;
       
       %find the time since the last changepoint
       dur = all_data(i).statusData(j).duration;
       time_elapsed(index) = dur - ((last_changepoint_index/tind)*dur);
       direction_before_drop(index) = directionvc(60);
       direction_first(index) = directionvc(1);
       direction_choice(index) = all_data(i).statusData(j).choice;
       
       
   end
end

%remove trials that do not have changepoint
ind_remove = find(isnan(time_elapsed));
time_elapsed(ind_remove) = [];
correct(ind_remove) = [];
direction_before_drop(ind_remove) = [];
direction_first(ind_remove) = [];
direction_choice(ind_remove) = [];

%change choice to 0 and 180
for i=1:length(direction_choice)
    if (direction_choice(i) == -1)
        direction_choice(i) = 180;
    elseif(direction_choice(i) == 1)
        direction_choice(i) = 0;
    end
end

save(strcat('H_', H,'_',coh,'/correct'),'correct');
save(strcat('H_', H,'_',coh,'/time_elapsed'),'time_elapsed');
save(strcat('H_', H,'_',coh,'/direction_before_drop'),'direction_before_drop');
save(strcat('H_', H,'_',coh,'/direction_first'),'direction_first');
save(strcat('H_', H,'_',coh,'/direction_choice'),'direction_choice');

end