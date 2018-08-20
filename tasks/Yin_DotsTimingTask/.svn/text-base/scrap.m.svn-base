%% rand plot
figure;
hold on;

d = data{2};
times = d.tStamp;

% h(1)=plot(fT,-1*ones(size(fT)),'.b');        % frames of stim.draw
h(1)=stem(times,ones(size(times)),'or','MarkerSize',3);  % times of exit

ylim([-2, 2]);
xlabel('time from session start (s)');

legend(h,'segment bounds');

%% plot vertical lines
hold on;
xs = [.1, 0.5];
yrange = ylim;
for i = 1:length(xs);
    plot(xs(i)*[1,1],yrange,'--k');
end

%% loop through dataLog
% dLog = dataLog object

d = data{2};
dLog = d.dataLog;

disp('');
for i=1:length(dLog);
    if ~strcmp(dLog(i).item.runnableClass,'topsCallList')
    disp([num2str(i) ' ' dLog(i).item.runnableClass]);
    end
%     if strcmp(dLog(i).item.actionName,'draw')
%         disp(num2str(i));
%         disp(dLog(i));
%         disp(dLog(i).item);
%         disp('');
%     end
end

%% plot cumulative distribution of d
d_ = diff(times);
[uniqueD, numUniqueD] = count_unique(d_);
cumuD = cumsum(numUniqueD);

figure;
plot(uniqueD,cumuD,'-or');
ylabel('cumulative sum');
xlabel('time (s)');

%% plot stuff
pos   =   pos7;
medat = medat7;

figure; 
subplot(1,2,1);
plot(pos(:,1), pos(:,2),'o');

subplot(1,2,2);
plot(medat, 'o'); 

%% plot pos
figure;
x = pos(:,1);
y = pos(:,2);
t = pos(:,3);
frames = unique(t);
GRAY = [1 1 1]*.7;
for fnum = 1:max(frames)
     plot(x(t==fnum),y(t==fnum),'o','MarkerSize',3,'Color',GRAY*fnum/max(frames)); hold on;
     xlim([0 1]);
     ylim([0 1]);
     axis equal;
%      input('press enter');
end

%% concatenate across blocks
sCumu = [];   % stimulus
rCumu = [];   % response
cCumu = [];   % confidence

for i = 1:length(data)
    sCumu = [sCumu data{i}.coh];
    rCumu = [rCumu data{i}.resp];
    cCumu = [cCumu data{i}.confid];
end

%% peformance display
GRAY = [1 1 1]*.7;
figure; 
sCumu = []; rCumu = []; cCumu = []; h = []; legText = [];
for i = 1:length(data)
    s = data{i}.coh;
    r = data{i}.resp;
    c = data{i}.confid;
    sCumu = [sCumu s];
    rCumu = [rCumu r];
    cCumu = [cCumu c];
    d2 = quick_formatData_yl([s',r']);
    h(i)=plot(d2(:,1),d2(:,2), '-o', 'MarkerSize',5,'LineWidth',2,...
        'Color',GRAY*i/length(data)); hold on;
%     plot(d2(7:12,2), 'ob-'); ylim([0.4,1]);
    legText{i} = ['block #' num2str(i)];
end

dCumu = quick_formatData_yl([sCumu',rCumu']);
h(end+1) = plot(dCumu(:,1),dCumu(:,2),'-or','MarkerSize',5,'LineWidth',2);
legText{end+1}=['session average'];
legend(h,legText); %ylim([0.7 1.01]);

set(gca,'XTick',dCumu(:,1),'XTickLabel',num2str(dCumu(:,1),2),'XScale','log');

[~,dCumu(:,3)] = count_unique(sCumu);
disp('-- coherence counts --');
disp(num2str(dCumu(:,[1,3])));


%% plot performance as sliding window

WINDOW = 20;
GRAY = [1 1 1]*.7;
figure; legText = []; h = [];
r = []; rCumu = [];
for i = 1:length(data)
    for j = 1:length(data{i}.resp)-WINDOW
        r(j) = sum(data{i}.resp(j:j+WINDOW-1))/WINDOW;
    end
    rCumu = [rCumu; r];
    h(i)=plot(r,'-o','MarkerSize', 5,...
        'LineWidth',2,...
        'Color',GRAY*i/length(data)); hold on;
    
    legText{i} = ['block #' num2str(i)];
    legText{i} = ['block #' num2str(i) ];
end
xlabel('trial #'); 
ylabel('frac correct');

h(end+1) = plot(mean(rCumu,1),'-or','MarkerSize',5,'LineWidth',2);
legText{end+1}=['session average'];
% set(gca,'YScale','log');
legend(h,legText);

%% pulse display
GRAY = [1 1 1]*.7;
CONFID_ONLY = 0;                % only display results for trials with confidence
figure; 
sCumu = []; rCumu = []; cCumu = []; h = []; legText = [];
range = 1:6;
for i = 1:length(data)
    if CONFID_ONLY
        confidIndex = ~isnan(data{i}.confid);
        c = data{i}.confid(confidIndex);
        s = data{i}.coh(confidIndex);
        r = data{i}.resp(confidIndex) & data{i}.confid(confidIndex)>0;
                % consider resp 'correct' only if responded correctly and
                % with high confidence
    else
        s = data{i}.coh;
        r = data{i}.resp;
        c = data{i}.confid;
    end
    sCumu = [sCumu s];
    rCumu = [rCumu r];
    cCumu = [cCumu c];
    d2 = quick_formatData_yl([s',r']);
    h(i)=plot(d2(range,2), '-o', 'MarkerSize',5,'LineWidth',2,...
        'Color',GRAY*i/length(data)); hold on;
%     plot(d2(7:12,2), 'ob-'); ylim([0.4,1]);
    legText{i} = ['block #' num2str(i)];
end

dCumu = quick_formatData_yl([sCumu',rCumu']);
h(end+1) = plot(dCumu(range,2),'-or','MarkerSize',5,'LineWidth',2);
legText{end+1}=['session average'];
    legend(h,legText); ylim([0.4 1]);
%% check quick_fit_yl function
% x = 10.^linspace(0,2,7);
% y = -1*rand(1,length(x))/10+quick_val(x,40,3.5,.5,0.001);
% plot(x,y,'o'); ylim([0.4,1]);xlim([0,100]);

% d = [x',y'];

[fits,~,~,~,~] = quick_fit(d, .5, .001);
xs = 10.^linspace(0,2,50);
ps = quick_val(xs,fits(1),fits(2),.5,.001);

hold on;
plot(xs,ps,'-');

%% plot threshold estimate

THRESH = 0;             % to plot threshold; otherwise, plots coherence

GRAY = [1 1 1]*.7;
figure; legText = []; h = [];
for i = 1:length(data)
    if THRESH
        qThresh = data{i}.qThresh;
    else
        qThresh = data{i}.pulseCoh;
    end
    h(i)=plot(1:length(qThresh), qThresh,'-o','MarkerSize', 5,...
        'LineWidth',2,...
        'Color',GRAY*i/length(data)); hold on;
    if THRESH
        legText{i} = ['block #' num2str(i) ', thresh coh=' ...
            num2str(qThresh(40),3) '(40), '...
            num2str(qThresh(end),3) '(60)'];
    else
        legText{i} = ['block #' num2str(i) ];
    end
end
ylim([0 100]); xlabel('trial #'); 
if THRESH
    ylabel('estimated threshold coherence');
else
    ylabel('presented coherence');
end
% set(gca,'YScale','log');
legend(h,legText);

%% confidence vs. response

for i = 1:length(data)
    disp(['-- Block #' num2str(i) ' --']);
    xi = ~isnan(data{i}.confid);
    confid = data{i}.confid(xi);
    resp = data{i}.resp(xi);
    CR = sum(confid > 0 & resp > 0);
    nCR = sum(confid <=0 & resp > 0);
    CnR = sum(confid > 0 & resp <= 0);
    nCnR = sum(confid <= 0 & resp <=0);
    tot = length(confid);
    disp([' C  R: ' num2str(CR)   ' (' num2str(CR/tot,2) ')']);
    disp(['~C  R: ' num2str(nCR)  ' (' num2str(nCR/tot,2) ')']);
    disp([' C ~R: ' num2str(CnR)  ' (' num2str(CnR/tot,2) ')']);
    disp(['~C ~R: ' num2str(nCnR) ' (' num2str(nCnR/tot,2) ')']);
    disp('');
end

%% plot the psychometric functions
GRAY = [1 1 1]*.7;
baseCoh=[];baseCoh2=[];
for i = 1:length(data)
    [baseCoh(i), baseCoh2(i)]=makePF2(data{i},1,1.8,1);
end

%% plot frequency of presentation
GRAY = [1 1 1]*.7;
figure;
for i = 1:length(data)
    coh = data{i}.coh;
    [uniqCoh, numUniqCoh] = count_unique(coh);
    numUniqCoh= numUniqCoh/sum(numUniqCoh);
    h(i)=plot(uniqCoh, numUniqCoh,'-o','MarkerSize', 5,...
        'LineWidth',2,...
        'Color',GRAY*i/length(data)); hold on;
    legText{i} = ['block #' num2str(i)];
end
xlabel('coherence'); ylabel('frequency of presentation');
set(gca,'XScale','log');
legend(h,legText);

%% plot threshold estimate
qThresh = pfData.qThresh;
pThresh = pfData.q.pThreshold;
qThreshSD = 10.^(QuestMean(pfData.q) + QuestSd(pfData.q)*[-1 1]);
figure;
plot(1:length(qThresh), qThresh,'-or','MarkerSize',3); hold on;
plot([0,length(qThresh)], qThresh(end)*[1,1],'-k');
plot([0,length(qThresh)], qThreshSD(1)*[1,1],'--k');
plot([0,length(qThresh)], qThreshSD(2)*[1,1],'--k');
ylim([0 100]);
xlabel('trial #'); ylabel(['coherence']);
legend(['pThresh = ' num2str(pThresh,3)], ['est coh = ' num2str(qThresh(end),3)]);

%% concatenate data
coh = [coh pfData.coh];
resp = [resp pfData.dir == pfData.choice];

%% plot raw data
% data=pfData;
% coh=data.coh; 
% dir=data.dir; 
% choice=data.choice;
% resp = dir==choice;
% 
% figure;
% hold on;
% plot(coh,resp+rand(size(resp))/5-.1,'ob','MarkerSize',5);
% 
% d = quick_formatData_yl([coh',resp']);
% plot(d(:,1),d(:,2),'ob','MarkerFaceColor','b','MarkerSize',5);
% 
% % fit from Quest
% guess = 0.5; lapse=0;
% questThresh = 10^QuestMean(pfData.q);
% questBeta = QuestBetaAnalysis(pfData.q);
% 
% % fit from quick_fit
% [fits,sems,stats,preds,resids]=quick_fit([coh',resp'],guess,lapse);
% 
% xs = linspace(0,100);
% psQuest = quick_val(xs,questThresh,questBeta,guess,lapse);
% psQuick = quick_val(xs,fits(1),fits(2),guess,lapse);
% 
% hold on;
% h(1)=plot(xs,psQuest, '-k','LineWidth',2);
% h(2)=plot(xs,psQuick, '-.k','LineWidth',2);
% set(gca,'XTick', d(:,1), 'XTickLabel', num2str(d(:,1),2));
% xlabel('coherence'); ylabel('fraction correct');
% 
% legend(h,...
%     ['Quest Thresh = ' num2str(questThresh,2)],...
%     ['Quick Thresh = ' num2str(fits(1),2)],...
%     'Location','SouthEast');
%% compute sliding window average and plot
r = pfData.resp;
avg = []; window = 20;
for i = 1:length(r)
    avg = [avg sum(r(1:i))/length(1:i)];
end

figure;
% ax2 = axes('Position',get(gca,'Position'),...
%                 'YAxisLocation','right',...
%                 'XTick',1:length(r),...
%                 'XTickLabel',[],...
%                 'YLim',[0 1],...
%                 'Color','none','XColor','k','YColor','r');
h(1)=plot(1:length(r),avg,'o-r'); hold on;
h(2)=plot([0,80],dPrimeToPercent(1)*[1,1],'--k');
xlabel('trial num');
legend(h,...
    'cumulative frac correct',...
    ['pThresh = ' num2str(dPrimeToPercent(1),3)], 'Location','SouthEast');
%     'Marker','.','MarkerSize',2,'LineStyle','-','Color','r','Parent');

% log_s = linspace(0,2,100);

%% 'Fake' Quest procedure
tToTest = log10(pfData.coh);
resp = pfData.choice == pfData.dir;
tGuess = tToTest(1);
tGuessSD = 1;
pThresh = dPrimeToPercent(1);
beta = 3.5;
delta = 0.01;
gamma = 0.5;

q = QuestCreate(tGuess, tGuessSD, pThresh,beta,delta,gamma);
q.normalizePdf =1;

trialsDesired = length(tToTest);

for i = 1:trialsDesired
    q=QuestUpdate(q,tToTest(i),resp(i));
end

d = quick_formatData_yl([q.intensity',q.response']);

plot(d(:,1),d(:,2),'o');

x=[];
for i = 1:trialsDesired
    x=[x ceil(rand*2)];
end

%% random display stuff
GRAY = [1 1 1]*.7;figure;
frames = unique(t);
for fnum = 1:max(frames)
    plot(x(t==fnum),y(t==fnum),'o','MarkerSize',3,'Color',GRAY*fnum/max(frames)); hold on;
    xlim([0 1]);
    ylim([0 1]);
    axis equal;
%     input('press enter');
end


% for i = 1:length(uniqueL);
%     crit_l = l>=uniqueL(i); 
%     PBb(i) = sum(b(crit_l)); 
%     PBo(i) = sum(o(crit_l));
% end;
% 
% PBb = [PBb 0];
% PBo = [PBo 0];
% 
% % calculate slopes
% for i = 1:length(uniqueL);
%     slope(i) = (PBb(i)-PBb(i+1))/(PBo(i)-PBo(i+1));
% end
% 
% 
% % code to randomize cohrence/angle conditions
% % create array for coherence:
% coh = [0 3.2 6.4 12.8 25.6 51.2 100];
% % create array for angles:
% ang = [0 180];
% 
% % we want 10 presentations of each coh-ang pair:
% numPres = 10;
% numItr = length(coh)*length(ang)*numPres;
% cohArray = repmat(coh, 1, length(ang)*numPres);
% angArray = repmat(ang, 1, length(coh)*numPres);
% 
% cohArray = cohArray(randperm(numItr));
% angArray = angArray(randperm(numItr));

% pf = zeros(1,length(cohUsed));
% for i = 1:length(cohUsed)
%     cohIndex = data.coh==cohUsed(i);
%     if sum(cohIndex)
%         pf(i) = sum(data.choice(cohIndex)==data.dir(cohIndex))/...
%             sum(cohIndex);
%     else
%         pf(i) = 0;
%     end
% end

% coh = data.coh;
% dir = data.dir;
% choice = data.choice;
% 
% s = coh; s(dir>90) = -1*s(dir>90);
% r = choice<90;
% 
% d=ones(length(s),3); d(:,1)=1; d(:,2)=s; d(:,3)=r;
% [fits,sems,stats,preds,resids] = logist_fit(d,'lu2');
% 
% % plot data
% d2 = quick_formatData_yl(d(:,2:3));
% figure;
% plot(d2(:,1),d2(:,2),'ob','MarkerSize',2,'MarkerFaceColor','b'); hold on;
% plot([-1 1]*100, [.5 .5],'--k');         % plot the 'chance' line
% plot([0 0], [0 1],'--k');                   % plot the zero line
% 
% % plot fit
% xs = linspace(-100,100);
% ps = logist_valLU2(fits, [ones(size(xs));xs]');
% plot(xs,ps, '-k');
% set(gca,'XTick', d2(:,1), 'XTickLabel', num2str(d2(:,1)));
% xlabel('coherence'); ylabel('fraction rightward');
% 
% confid = data.confid;
% c = confid;
% 
% d3 = quick_formatData_yl([s',c']);
% plot(d3(:,1),d3(:,2),'ok','MarkerSize',5);

