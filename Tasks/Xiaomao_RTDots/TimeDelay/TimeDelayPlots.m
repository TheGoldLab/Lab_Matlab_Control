%% TimeDelayPlots
%
% This script generates plots for the data from the Eyelink/Matlab time
% delay script also located in this directory.
%
% 9/21/17    xd  wrote it

clearvars; close all;
%% Specify data file
filename = 'TimeDelayData2';
load(filename);

%% Plot average and errors for test 1,2,5
figure('Position',[0 0 1500 500]); 
toPlot = [1,2,5];
for jj = 1:length(toPlot)
    subplot(1,length(toPlot),jj);
    hold on;
    for ii = 1:3
        dataToPlot = squeeze(data(toPlot(jj),ii,:,:)) * 1000;
        m = mean(dataToPlot,2);
        se = std(dataToPlot,[],2) / sqrt(testRepeatNumber);
        
        errorbar(testDurations * 1000,m,se);
%         loglog(testDurations,m);
    end
    set(gca,'xscale','log');
    set(gca,'yscale','log');
    
    axis square;
    if jj == 1
        legend(timers,'Location','northwest');
    end
    xlim([0 testDurations(end)] * 1000);
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('True Duration (ms)','FontSize',16);
    ylabel('Measured Duraction (ms)','FontSize',16);
    
    title(tests{toPlot(jj)},'FontSize',20);
end
set(gcf, 'PaperPositionMode', 'auto');

%% Plot means for test 3,4
figure('Position',[0 0 1000 500]);
toPlot = [3,4];
for jj = 1:length(toPlot)
    subplot(1,length(toPlot),jj);
    hold on;
    for ii = 1:3
        dataToPlot = squeeze(data(toPlot(jj),ii,:,:)) * 1000;
        m = mean2(dataToPlot);
        se = std(dataToPlot(:)) / sqrt(testRepeatNumber * length(testDurations));
        
        bar(ii,m);
        errorbar(ii,m,se);
    end
    
    axis square;
    ylim([0 2e-1]);
    set(gca,'LineWidth',1.5,'FontSize',16);
    set(gca,'XTick',1:3,'XTickLabel',timers);
    
    xlabel('Timer function','FontSize',16);
    ylabel('Measured Duraction (ms)','FontSize',16);
    
    title(tests{toPlot(jj)},'FontSize',20);
end
set(gcf, 'PaperPositionMode', 'auto');

%% Plot deviation from true for test 1,2,5
figure('Position',[0 0 1500 500]); 
toPlot = [1,2,5];
for jj = 1:length(toPlot)
    subplot(1,length(toPlot),jj);
    hold on;
    for ii = 1:3
        dataToPlot = squeeze(data(toPlot(jj),ii,:,:)) * 1000;
        td = repmat(testDurations(:),1,10) * 1000;
        m = mean(dataToPlot - td,2);
        se = std(dataToPlot - td,[],2) / sqrt(testRepeatNumber);
        
        errorbar(testDurations*1000,m,se);
%         loglog(testDurations,m);
    end
    set(gca,'xscale','log');
    
    axis square;
    if jj == 1
        legend(timers,'Location','northwest');
    end
    
    xlim([1e-1 1e5]);
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('True Duration (ms)','FontSize',16);
    ylabel('Measured Duration Error (ms)','FontSize',16);
    
    title(tests{toPlot(jj)},'FontSize',20);
end
set(gcf, 'PaperPositionMode', 'auto');
