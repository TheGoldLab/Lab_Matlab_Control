function [coh_thresh_, coh_pulse_] = makePF(coh, dir, choice, dispPlot, THRESH, PULSE)
% function:  creates a psychometric fxn
% inputs:
%   coh = array of coherence of the stimulus trials,  0-100%
%   dir = array of direction of the stimulus trials, where 0 = R, 180 = L
%   choice = array of user choices, where 0 = R, 180 = L
% outputs:
%
% last updated: yl 2010/09/15

%% -1. Constants
%% 0. figure out the input being used
exp_date = [];
if isstruct(coh)            % actually a 'data' struct from saved mat file
    data = coh;
    coh = data.coh;
    dir = data.dir;
    choice = data.choice;
    if isfield(data,'date');
        exp_date = datestr(data.date);
    end
    
    if isfield(data,'confid');
        confid = data.confid;
    end
end

if ~exist('dispPlot','var')
    dispPlot = 1;
end

if ~exist('THRESH', 'var')
    THRESH = 1;                     % defines threshold d' = 1
    PULSE = 1.25;             % defines signal intensity for pulses
end

% plot PF w/ intensity = signed coherence (-100 to 100%) - LOGISTIC
%% 1. re-code stim and resp
s = coh;
s(dir>90) = -1*s(dir>90);                  % intensity as signed coh
r = choice<90;                             % resp as R choice
d=[ones(length(s),1),s',r'];               % format data for logist_fit
[fits,sems,stats,preds,resids] = logist_fit(d,'lu2');

%% 2. plot data
d2 = quick_formatData_yl(d(:,2:3));
if dispPlot
    figure;
    h(1)=plot(d2(:,1),d2(:,2),'.b','MarkerSize',5); hold on;
    plot([-1 1]*100, [.5 .5],':k');         % plot the 'chance' line
    plot([0 0], [0 1],':k');                   % plot the zero line
end

%% 3. plot fit
xs = sort([linspace(-100,100) logspace(-1,1) -1*logspace(-1,1)]);
ps = logist_valLU2(fits, [ones(size(xs));xs]');
if dispPlot
    h(2)=plot(xs,ps, '-k','LineWidth',2);% plot(-1*xs,ps,'-k');
    set(gca,'XTick', d2(:,1), 'XTickLabel', num2str(d2(:,1)));
    xlabel('signed coherence'); ylabel('fraction rightward');
    title(['Experiment Date: ' exp_date]);
end

%% 4. get threshold and pulse coherences
p_thresh = dPrimeToPercent([-1 1]*THRESH);
p_pulse = dPrimeToPercent([-1 1]*PULSE);

[dum, thresh_ind(1)] = min((ps-p_thresh(1)).^2);
[dum, thresh_ind(2)] = min((ps-p_thresh(2)).^2);
coh_thresh = xs(thresh_ind);
% if dispPlot
%     plot(coh_thresh,p_thresh,'ok','MarkerFaceColor','k');
% end

[dum, pulse_ind(1)] = min((ps-p_pulse(1)).^2);
[dum, pulse_ind(2)] = min((ps-p_pulse(2)).^2);
coh_pulse = xs(pulse_ind);
% if dispPlot
%     plot(coh_pulse,p_pulse,'ok','MarkerFaceColor','w');
% end

coh_thresh_ = abs(.5*diff(coh_thresh));
coh_pulse_ = abs(.5*diff(coh_pulse));

%% 5. plot these coherences to be used
if dispPlot
    h(3)=plot([1 1]*coh_thresh_, [0 1],'-k');
    plot([-1 -1]*coh_thresh_, [0 1],'-k');
    h(4)=plot([1 1]*coh_pulse_, [0 1],'--k');
    plot([-1 -1]*coh_pulse_, [0 1],'--k');
end

%% 6. plot confidence data
if 0
    if exist('data','var') && isfield(data,'confid')
        confid = data.confid;
        d3 = quick_formatData_yl([s', confid']);

        if dispPlot
            % plot over same set of points - but using diff y axis
            set(gca,'YAxisLocation','left');
            ax2 = axes('Position',get(gca,'Position'),...
                'YAxisLocation','right',...
                'XTick',[],...
                'XTickLabel',[],...
                'YLim',[-1 1],...
                'Color','none','XColor','k','YColor','r');
            set(get(ax2,'YLabel'),'String','confidence');
            h(5) = line(d3(:,1),d3(:,2),...
                'Color','r','LineStyle','-','Marker','o','Parent',ax2);
            legend(h,...
                ['Choice(signed coh)'],...
                ['Logistic fit to choice'],...
                ['Threshold coh = ' num2str(coh_thresh_,3)],...
                ['Pulse coh = ' num2str(coh_pulse_,3)],...
                ['Confidence'],...
                'Location','SouthEast');

        %     h(5) = plot(d3(:,1),d3(:,2),'ro-');
        %     [ax,h(4),h(5)]=plotyy([1 1]*coh_pulse_, [0 1],...
        %         d3(:,1),d3(:,2),'plot');
        %     
        %     set(h(4),'LineStyle','--','Color','k');
        %     set(h(5),'LineStyle','-','Color','r','Marker','o');

        %     set(get(ax(1),'YLabel'),'Color','k');
        %     set(ax(1),'Color','k');
        %     set(get(ax(2),'YLabel'),'Color','r');

        %     figure;
        %     [ax,h1,h2]=plotyy(d2(:,1),d2(:,2),d3(:,1),d3(:,2),'plot');
        %     set(h1,'LineStyle','-','Marker','.');
        %     set(h2,'LineStyle','-','Marker','o');
        end
    else
        legend(h,...
            ['Choice(signed coh)'],...
            ['Logistic fit to choice'],...
            ['Threshold coh = ' num2str(coh_thresh_,3)],...
            ['Pulse coh = ' num2str(coh_pulse_,3)],...
            'Location','SouthEast');
    end
end

% %% 1. plot PF w/ intensity = coherence (0 to 100%) - QUICK/WEIBULL
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

% 
% % plot the threshold
% [diff, thresh_ind] = min((ps-THRESH).^2);
% x_thresh = xs(thresh_ind);                  % find the x that yields value closest to THRESH
% plot(x_thresh, THRESH, 'ok');
% text(x_thresh+5, THRESH, ['P(x=' num2str(round(x_thresh)) ')=' num2str(THRESH)]);


% plot the threshold
% [diff, thresh_ind] = min((ps-THRESH).^2);
% x_thresh2 = xs(thresh_ind);                  % find the x that yields value closest to THRESH
% plot(x_thresh2, THRESH, 'ok');
% text(x_thresh2+5, THRESH, ['P(x=' num2str(round(x_thresh2)) ')=' num2str(THRESH)]);

%% Useless old code for Weibull 'fit' for folded-out data
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
% plot(d2(:,1),d2(:,2),'ob','MarkerSize',5); hold on;
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