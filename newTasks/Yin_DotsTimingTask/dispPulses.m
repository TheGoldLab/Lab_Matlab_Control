function dispPulses(coh, cohcode, dir, choice, confid)
% yl: 2010/09/12
% function:  creates a psychometric fxn
% inputs:
%   coh = array of coherence of the stimulus trials,  0-100%
%   cohcode = cell array defining how to decode the coherence trains in
%   'coh' (e.g., 1 in coh <=> [50% 50% 25%]
%   dir = array of direction of the stimulus trials, where 0 = R, 180 = L
%   choice = array of user choices, where 0 = R, 180 = L

%% -1. Constants

%% 0. figure out the input being used
exp_date = [];
if isstruct(coh)            % actually a 'data' struct from saved mat file
    data = coh;
    coh = data.coh;
    cohcode = data.cohcode;
    dir = data.dir;
    choice = data.choice;
    if isfield(data,'confid');
        confid = data.confid;
    end
    if isfield(data,'date');
         exp_date = datestr(data.date);
    end
end

% figure out the base and pulse coh
baseCoh =[]; pulseCoh = [];
for i = 1:length(cohcode)
    baseCoh = min([baseCoh cohcode{i}]);
    pulseCoh = max([pulseCoh cohcode{i}]);
end

%% 1. plot behavior as a function of coherence (i.e., where the 'pulse' is)
s = pulseTime(coh, cohcode);            % trial-by-trial stimulus 
                                        % (defined by where the pulse starts)
r = dir == choice;              % trial-by-trial response
d=[]; d(:,1)=s; d(:,2)=r;               % format data for quick_formatData_yl
d2 = quick_formatData_yl(d);            % xf data into % correct

minx = min(d2(:,1)); maxx = max(d2(:,1));
figure; %subplot(2,1,1);
plot(d2(:,1),d2(:,2),'-ob','MarkerSize',5,'MarkerFaceColor','b','LineWidth',2); hold on;
% plot(d2(2:end,1),d2(2:end,2),'-b','LineWidth',2);
plot([minx maxx], [.5 .5], '--k');
set(gca,'XTick', d2(:,1), 'XTickLabel', num2str(d2(:,1)));
xlabel('pulse position'); ylabel('P(correct|pulse position)');
set(gca,'YAxisLocation','left','YLim',[0 1]);
title(['Experiment Date: ' exp_date]);

%% 2. tell them what the base and pulse coherences were
text(.5,min(ylim)+.90*(max(ylim)-min(ylim)),['Base coh = ' num2str(baseCoh,3)]);
text(.5,min(ylim)+.8*(max(ylim)-min(ylim)),['Pulse coh = ' num2str(pulseCoh,3)]);

%% 3. plot confidence as a function of coherence
if exist('confid','var')
    r = confid;
    dConfid = quick_formatData_yl([s',r']);
    
    
    ax2 = axes('Position',get(gca,'Position'),...
                'YAxisLocation','right',...
                'XTickLabel',[],...
                'XTick',[],...
                'YLim',[-1 1],...
                'Color','none','XColor','k','YColor','r');
    set(get(ax2,'YLabel'),'String','confidence');
    line(dConfid(:,1),dConfid(:,2),...
        'Color','r','LineStyle','-','Marker','o','Parent',ax2);
end
% %% 3. plot coherence as a function of behavior
% 
% % get stim data for all the correct trials:
% r = dir == choice;
% scorrect = s(r);
% prop = hist(scorrect,d2(:,1))/length(scorrect);   % bin the correct s according to all the unique stims
% 
% subplot(2,1,2);
% plot(d2(:,1),prop,'-ob','MarkerSize',5,'MarkerFaceColor','b','LineWidth',2); hold on;
% % plot(d2(:,1),prop,'-b','LineWidth',2);
% set(gca,'XTick',d2(:,1),'XTickLabel',num2str(d2(:,1)));
% xlabel('pulse position'); ylabel('P(pulse position|correct)');
% 

% 
% 
% %% 1. plot PF w/ intensity = coherence (0 to 100%)
% % do the fit
% s = coh;                                % trial-by-trial stimulus
% r = dir == choice;              % trial-by-trial response
% d=[]; d(:,1)=s; d(:,2)=r;               % format data for quick_fit
% guess = 0.5; lapse = 0;                 % for intensity from 0 to 100%, resp from 0.5 to 1
% [fits,sems,stats,preds,resids] = quick_fit(d, guess, lapse);
% 
% % plot the data
% d2=quick_formatData_yl(d);                 % transform data into % correct
% figure; subplot(2,1,1);
% plot(d2(:,1),d2(:,2),'.b','MarkerSize',5); hold on;
% plot([0 100],[.5 .5],'--k');                % plot the 'chance' line
% 
% % plot the fit
% xs = linspace(0,100);
% ps = quick_val(xs,fits(1),fits(2),guess,lapse);
% plot(xs,ps, '-k');
% set(gca,'XTick', d2(:,1), 'XTickLabel', num2str(d2(:,1)));
% xlabel('coherence'); ylabel('fraction correct');
% title(['Experiment Date: ' exp_date]);
% 
% % plot the threshold
% [diff, thresh_ind] = min((ps-THRESH).^2);
% x_thresh = xs(thresh_ind);                  % find the x that yields value closest to THRESH
% plot(x_thresh, THRESH, 'ok');
% text(x_thresh+5, THRESH, ['P(x=' num2str(round(x_thresh)) ')=' num2str(THRESH)]);
% 
% %% 2. plot PF w/ intensity = signed coherence (-100 to 100%)
% % re-code s and r
% s(dir>90) = -1*s(dir>90);                  % intensity as signed coh
% offset = 100; s = s+offset;                % and then shift by 100 for Weibull fit
% r = choice<90;                             % resp as R choice
% d=[]; d(:,1)=s; d(:,2)=r;                   % format data for quick_fit
% guess = 0; lapse = 0;                       % for resp from 0 to 1
% [fits, sems,stats,preds,resids] = quick_fit(d,guess,lapse);
% 
% % plot the data
% d2=quick_formatData_yl(d);                 % transform data into % correct
% d2(:,1)=d2(:,1)-offset;                    % restore the offset
% subplot(2,1,2);
% plot(d2(:,1),d2(:,2),'.b','MarkerSize',5); hold on;
% plot([-1 1]*offset, [.5 .5],'--k');         % plot the 'chance' line
% plot([0 0], [0 1],'--k');                   % plot the zero line
% 
% % plot the fit
% xs = linspace(-100,100);
% ps = quick_val(xs+offset,fits(1),fits(2),guess,lapse);
% plot(xs,ps, '-k');
% set(gca,'XTick', d2(:,1), 'XTickLabel', num2str(d2(:,1)));
% xlabel('coherence'); ylabel('fraction rightward');
%  
% % plot the threshold
% [diff, thresh_ind] = min((ps-THRESH).^2);
% x_thresh2 = xs(thresh_ind);                  % find the x that yields value closest to THRESH
% plot(x_thresh2, THRESH, 'ok');
% text(x_thresh2+5, THRESH, ['P(x=' num2str(round(x_thresh)) ')=' num2str(THRESH)]);

% %% 1. plot PF w/ signed coh scale
% % re-code coherence as +/- if R/L
% signCoh = coh;  signCoh(dir > 90) = -1*signCoh(dir>90);
% 
% % the new set of stim parameter is thus defined by the unique signed
% % coherences
% stim = unique(signCoh);
% 
% % for each coherence, find % R choices
% resp = zeros(1,length(stim));
% for i = 1:length(stim)
%     cohIndex = signCoh==stim(i);
%     resp(i) = (sum(choice(cohIndex) == 0))/sum(cohIndex); 
% end
% 
% figure; subplot(2,1,1);
% plot(stim,.5*ones(size(stim)),'--k','LineWidth',1); hold;
% plot(stim,resp,'.b','MarkerSize', 5);
% plot(stim,resp, '-b', 'LineWidth',2);
% xlim([-100,100]); ylim([0,1]); 
% xlabel('signed coherence'); ylabel('fraction right choice');
% 
% 
% % re-calculate % correct by averaging z-scores
% % this algorithm doesn't work when one of the P is 0 or 1 - average w/
% % infinity!
% % correction w/ 0 => 1/(2N) and 1 => 1-1/(2N)
% resp(resp==0)=1/(2*9); resp(resp==1)=1-1/(2*9);
% respZ = 0.5*(norminv(1-resp,0,1)+norminv(resp(end:-1:1),0,1));
% respZ = respZ(1:ceil(end/2));
% resp2 = normcdf(respZ);
% stim2 = -1*(stim(1:ceil(end/2)));
% 
% % resp2 = 0.5*(1-resp + resp(end:-1:1));
% % resp2 = resp2(1:ceil(end/2));
% % stim2 = -1*(stim(1:ceil(end/2)));
% 
% % stim2 = unique(coh);
% % resp2 = zeros(1,length(stim2));
% % for i = 1:length(stim2)
% %     cohIndex = coh==stim2(i);
% %     resp2(i) = sum(choice(cohIndex) == dir(cohIndex))/sum(cohIndex)
% % end
% 
% subplot(2,1,2);
% plot(stim2,.5*ones(size(stim2)),'--k','LineWidth',1); hold;
% plot(stim2,resp2,'.r','MarkerSize',5); 
% plot(stim2,resp2,'-r','LineWidth',2);
% xlim([0,100]);ylim([0,1]);
% xlabel('coherence'); ylabel('fraction correct');